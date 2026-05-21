import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:frontend/utils/razorpay_payment_helper.dart';
import 'package:frontend/core/app_theme.dart';
import 'package:frontend/providers/app_state.dart';
import 'package:frontend/models/models.dart';
import 'package:frontend/screens/prime_screen.dart';
import 'package:frontend/screens/payment_success_screen.dart';
import 'package:url_launcher/url_launcher.dart';

class MerchantDetailScreen extends StatefulWidget {
  final Merchant merchant;
  const MerchantDetailScreen({super.key, required this.merchant});

  @override
  State<MerchantDetailScreen> createState() => _MerchantDetailScreenState();
}

class _MerchantDetailScreenState extends State<MerchantDetailScreen> {
  final TextEditingController _billController = TextEditingController();
  double billAmount = 0;
  double discountAmount = 0;
  double finalAmount = 0;
  String paymentMethod = 'ONLINE'; 
  String? receiptPath;
  late Razorpay _razorpay;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handleMerchantPaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handleMerchantPaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  @override
  void dispose() {
    _razorpay.clear();
    _billController.dispose();
    super.dispose();
  }


  void _handleMerchantPaymentSuccess(PaymentSuccessResponse response) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator(color: AppColors.amber)),
    );

    final state = context.read<AppState>();
    bool success = await state.verifyRazorpayPayment(
      orderId: response.orderId ?? '',
      paymentId: response.paymentId ?? '',
      signature: response.signature ?? '',
    );

    if (success) {
      final paySuccess = await state.customerPay(widget.merchant.id, billAmount);
      
      if (!mounted) return;
      Navigator.pop(context); // Close loading spinner

      if (paySuccess) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => PaymentSuccessScreen(
              amount: finalAmount.toStringAsFixed(0),
              message: "Payment of ₹${finalAmount.toStringAsFixed(0)} to ${widget.merchant.businessName} was successful! You saved ₹${discountAmount.toStringAsFixed(0)}.",
              onDone: () => state.refreshData(),
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Payment completed but failed to register discount. Please contact support."),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } else {
      if (!mounted) return;
      Navigator.pop(context); // Close spinner
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Payment verification failed. Please try again."),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  void _handleMerchantPaymentError(PaymentFailureResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Payment failed: ${response.message ?? 'Unknown error'}"),
        backgroundColor: Colors.redAccent,
      ),
    );
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("External Wallet Selected: ${response.walletName}")),
    );
  }

  void _startRazorpayPayment(AppState state) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator(color: AppColors.amber)),
    );

    final orderData = await state.createRazorpayOrder(finalAmount, purpose: widget.merchant.businessName);
    
    if (!mounted) return;
    Navigator.pop(context); // Close spinner

    if (orderData == null || orderData['order_id'] == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Failed to initiate online payment. Please try again."),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    var options = {
      'key': orderData['key'] ?? 'rzp_test_Sq5pz3FrwtVkhg',
      'amount': orderData['amount'],
      'name': widget.merchant.businessName,
      'order_id': orderData['order_id'],
      'description': 'Payment for ${widget.merchant.businessName}',
      'prefill': {
        'contact': state.profile?.phone ?? '',
        'email': state.profile?.email ?? '',
      },
      'theme': {
        'color': '#FFB000'
      }
    };

    try {
      if (kIsWeb) {
        openRazorpayWebCheckout(
          options: options,
          onSuccess: (response) {
            final successResponse = PaymentSuccessResponse(
              response['razorpay_payment_id'],
              response['razorpay_order_id'],
              response['razorpay_signature'],
              response,
            );
            _handleMerchantPaymentSuccess(successResponse);
          },
          onCancel: () {
            _handleMerchantPaymentError(PaymentFailureResponse(
              2, // PAYMENT_CANCELLED
              'Payment cancelled by user',
              {},
            ));
          },
        );
      } else {
        _razorpay.open(options);
      }
    } catch (e) {
      debugPrint("Error opening Razorpay: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final isPrime = state.profile?.isPrime ?? false;

    return Scaffold(
      backgroundColor: const Color(0xFF07070A),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: AppColors.ink,
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  decoration: BoxDecoration(color: Colors.black45, shape: BoxShape.circle, border: Border.all(color: Colors.white10)),
                  child: const Icon(Icons.chevron_left, color: Colors.white),
                ),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  widget.merchant.cardImage != null && widget.merchant.cardImage.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: widget.merchant.cardImage,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: AppColors.ink2,
                            child: const Center(
                              child: CircularProgressIndicator(color: AppColors.amber),
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [AppColors.ink2, Color(0xFF14141E)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: const Icon(
                              Icons.storefront_outlined,
                              color: Colors.white24,
                              size: 64,
                            ),
                          ),
                        )
                      : Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [AppColors.ink2, Color(0xFF14141E)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: const Icon(
                            Icons.storefront_outlined,
                            color: Colors.white24,
                            size: 64,
                          ),
                        ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, const Color(0xFF07070A).withOpacity(0.95)],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 24,
                    left: 24,
                    right: 24,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            color: AppColors.ink2,
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(color: AppColors.line, width: 2),
                            boxShadow: [BoxShadow(color: Colors.black38, blurRadius: 20)],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: widget.merchant.logo != null && widget.merchant.logo.isNotEmpty
                                ? CachedNetworkImage(
                                    imageUrl: widget.merchant.logo,
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) => Container(
                                      color: AppColors.ink2,
                                      child: const Center(
                                        child: SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            color: AppColors.amber,
                                            strokeWidth: 2,
                                          ),
                                        ),
                                      ),
                                    ),
                                    errorWidget: (context, url, error) => Container(
                                      color: AppColors.ink2,
                                      child: const Icon(
                                        Icons.storefront_outlined,
                                        color: AppColors.amber,
                                        size: 32,
                                      ),
                                    ),
                                  )
                                : Container(
                                    color: AppColors.ink2,
                                    child: const Icon(
                                      Icons.storefront_outlined,
                                      color: AppColors.amber,
                                      size: 32,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                widget.merchant.businessName.toUpperCase(),
                                style: GoogleFonts.playfairDisplay(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.location_on_outlined, color: AppColors.amber, size: 14),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      "${widget.merchant.city}, ${widget.merchant.state}".toUpperCase(),
                                      style: GoogleFonts.jost(color: AppColors.text2, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Badges
                  Row(
                    children: [
                      _buildInfoBadge(Icons.percent, "${widget.merchant.discountPercent}% OFF", AppColors.amber),
                      const SizedBox(width: 12),
                      _buildInfoBadge(Icons.star_rounded, "4.8 RATING", Colors.white38),
                      const SizedBox(width: 12),
                      _buildInfoBadge(Icons.category_outlined, (widget.merchant.categoryName).toUpperCase(), Colors.white38),
                    ],
                  ),
                  
                  const SizedBox(height: 32),
                  
                  Text(
                    "LOCATION",
                    style: GoogleFonts.jost(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1.5),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.merchant.address,
                    style: GoogleFonts.jost(color: AppColors.text2, fontSize: 15, height: 1.5),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  if (widget.merchant.description.isNotEmpty) ...[
                    Text(
                      "ABOUT",
                      style: GoogleFonts.jost(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1.5),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.merchant.description,
                      style: GoogleFonts.jost(color: AppColors.text2, fontSize: 15, height: 1.6),
                    ),
                    const SizedBox(height: 32),
                  ],

                  if (!isPrime)
                    _buildPrimeLockCard(context)
                  else
                    _buildPaymentCalculator(context, state),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoBadge(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 12),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildPrimeLockCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.ink2,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.amber.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(Icons.lock_person_outlined, size: 48, color: AppColors.amber.withOpacity(0.5)),
          const SizedBox(height: 24),
          Text(
            "PRIME EXCLUSIVE",
            style: GoogleFonts.jost(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            "Upgrade to Prime to unlock this merchant's exclusive discount.",
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.text2, fontSize: 13),
          ),
          const SizedBox(height: 24),
          Container(
            width: double.infinity,
            height: 56,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.amber, Color(0xFFFF9D00)],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: ElevatedButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PrimeScreen())),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                foregroundColor: Colors.white,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text("UPGRADE NOW", style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentCalculator(BuildContext context, AppState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "PROCEED TO PAYMENT",
          style: GoogleFonts.jost(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1.5),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.ink2,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: AppColors.line),
          ),
          child: Column(
            children: [
              TextField(
                controller: _billController,
                keyboardType: TextInputType.number,
                onChanged: (v) {
                  setState(() {
                    finalAmount = double.tryParse(v) ?? 0;
                    double discountPercent = widget.merchant.discountPercent.toDouble();
                    if (discountPercent >= 100) {
                      discountAmount = 0;
                      billAmount = finalAmount;
                    } else {
                      discountAmount = finalAmount * (discountPercent / (100 - discountPercent));
                      billAmount = finalAmount + discountAmount;
                    }
                  });
                },
                style: GoogleFonts.dmMono(color: Colors.white, fontSize: 18),
                decoration: InputDecoration(
                  labelText: "ENTER FINAL AMOUNT PAID",
                  labelStyle: const TextStyle(color: AppColors.text2, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5),
                  hintText: "0.00",
                  hintStyle: const TextStyle(color: Colors.white10),
                  prefixText: "₹ ",
                  prefixStyle: const TextStyle(color: AppColors.amber),
                  filled: true,
                  fillColor: Colors.black26,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
                ),
              ),
              if (finalAmount > 0) ...[
                const SizedBox(height: 24),
                _buildPriceRow("FINAL AMOUNT TO PAY", "₹${finalAmount.toStringAsFixed(2)}", Colors.white, isLarge: true),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: state.isLoading ? null : () => _showPaymentOptions(context, state),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.amber,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    ),
                    child: const Text(
                      "PROCEED TO PAY",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  void _showPaymentOptions(BuildContext context, AppState state) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(32),
        decoration: const BoxDecoration(color: AppColors.ink2, borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("CHOOSE PAYMENT", style: GoogleFonts.jost(color: AppColors.text2, fontWeight: FontWeight.bold, letterSpacing: 2)),
            const SizedBox(height: 24),
            _paymentOptionTile(Icons.account_balance_wallet_outlined, "UPI PAYMENT", "Pay directly using any UPI App (GPay, PhonePe, Paytm, etc.)", () {
              Navigator.pop(context);
              _startDirectUpiPayment(state);
            }),
            const SizedBox(height: 12),
            _paymentOptionTile(Icons.money, "CASH PAYMENT", "Pay directly at store", () {
              Navigator.pop(context);
              _simulatePayment(state);
            }),
          ],
        ),
      ),
    );
  }

  void _startDirectUpiPayment(AppState state) async {
    String cleanMerchantName = widget.merchant.businessName.replaceAll(RegExp(r'[^a-zA-Z0-9 ]'), '');
    String upiUrl = "upi://pay?pa=thebaronclub@ybl&pn=${Uri.encodeComponent(cleanMerchantName)}&am=${finalAmount.toStringAsFixed(2)}&cu=INR";
    final uri = Uri.parse(upiUrl);
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Launching payment. Select any UPI app (GPay, PhonePe, Paytm, etc.) to pay."),
        backgroundColor: AppColors.amber,
        duration: Duration(seconds: 4),
      ),
    );
    
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Could not launch UPI app: $e"),
          backgroundColor: Colors.redAccent,
        ),
      );
    }

    if (mounted) {
      _showUpiCompletionDialog(context, state);
    }
  }

  void _showUpiCompletionDialog(BuildContext context, AppState state) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Dialog(
            backgroundColor: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: AppColors.ink2,
                borderRadius: BorderRadius.circular(32),
                border: Border.all(color: AppColors.line),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.check_circle_outline,
                    color: AppColors.amber,
                    size: 64,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    "UPI PAYMENT INITIATED",
                    style: GoogleFonts.jost(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "Please complete the payment of ₹${finalAmount.toStringAsFixed(2)} in your selected UPI app.",
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.text2, fontSize: 13, height: 1.4),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: state.isLoading ? null : () {
                        Navigator.pop(context);
                        _simulatePayment(state);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.amber,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        "I HAVE COMPLETED PAYMENT",
                        style: GoogleFonts.jost(
                          fontWeight: FontWeight.w900,
                          fontSize: 13,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      "Cancel / Go Back",
                      style: TextStyle(color: Colors.white.withOpacity(0.5)),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _paymentOptionTile(IconData icon, String title, String sub, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(border: Border.all(color: AppColors.line), borderRadius: BorderRadius.circular(20)),
        child: Row(
          children: [
            Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: AppColors.amber.withOpacity(0.1), shape: BoxShape.circle), child: Icon(icon, color: AppColors.amber)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  Text(sub, style: const TextStyle(color: AppColors.text2, fontSize: 11)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white24),
          ],
        ),
      ),
    );
  }

  void _simulatePayment(AppState state) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator(color: AppColors.amber)),
    );

    final success = await state.customerPay(widget.merchant.id, billAmount);
    
    if (!mounted) return;
    Navigator.pop(context); // Close loading

    if (success) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => PaymentSuccessScreen(
            amount: finalAmount.toStringAsFixed(0),
            message: "Discount applied successfully! You saved ₹${discountAmount.toStringAsFixed(0)}.",
            onDone: () => state.refreshData(),
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Payment processing failed. Please try again."),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Widget _buildPriceRow(String label, String value, Color color, {bool isLarge = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: AppColors.text2, fontSize: isLarge ? 14 : 11, fontWeight: FontWeight.bold)),
        Text(value, style: GoogleFonts.dmMono(color: color, fontSize: isLarge ? 22 : 16, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
