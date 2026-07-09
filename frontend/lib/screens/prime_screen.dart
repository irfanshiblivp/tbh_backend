import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:frontend/utils/razorpay_payment_helper.dart';
import '../core/app_theme.dart';
import '../providers/app_state.dart';
import '../models/models.dart';
import 'payment_success_screen.dart';

class PrimeScreen extends StatefulWidget {
  const PrimeScreen({super.key});

  @override
  State<PrimeScreen> createState() => _PrimeScreenState();
}

class _PrimeScreenState extends State<PrimeScreen> {
  String? selectedPlanId;
  double price = 0;
  final TextEditingController _referralController = TextEditingController();
  Razorpay? _razorpay;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      _razorpay = Razorpay();
      _razorpay!.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
      _razorpay!.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
      _razorpay!.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = context.read<AppState>();
      state.loadSettings().then((_) {
        final primeSettings = state.settings.where((s) => s.key.startsWith('PRIME_PLAN_')).toList();
        if (primeSettings.isNotEmpty) {
          setState(() {
            selectedPlanId = primeSettings.first.key;
            final parts = primeSettings.first.value.split('|');
            price = double.tryParse(parts.length > 1 ? parts[1] : parts[0]) ?? 999;
          });
        }
      });
    });
    // Ensure we have a default even before settings load
    selectedPlanId = 'PRIME_PLAN_ANNUAL';
    price = 999;
  }

  @override
  void dispose() {
    _razorpay?.clear();
    _referralController.dispose();
    super.dispose();
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
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
      referralCode: _referralController.text,
    );

    if (!mounted) return;
    Navigator.pop(context); // Close loading spinner

    if (success) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => PaymentSuccessScreen(
            amount: price.toStringAsFixed(0),
            message: "Welcome to Prime! Your account has been upgraded.",
            onDone: () => state.refreshData(),
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Payment verification failed. Please contact support."),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
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
    final referralInput = _referralController.text.trim().toUpperCase();
    final ownReferralCode = state.profile?.referralCode?.trim().toUpperCase();
    if (referralInput.isNotEmpty && ownReferralCode != null && referralInput == ownReferralCode) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("You cannot use your own referral code for prime membership."),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator(color: AppColors.amber)),
    );

    final orderData = await state.createRazorpayOrder(price);
    
    if (!mounted) return;
    Navigator.pop(context); // Close spinner

    if (orderData == null || orderData['order_id'] == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Failed to initiate payment. Please try again."),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    var options = {
      'key': orderData['key'] ?? 'rzp_test_Sq5pz3FrwtVkhg',
      'amount': orderData['amount'], // paise from backend
      'name': 'The Baron Club',
      'order_id': orderData['order_id'],
      'description': 'Prime Membership Subscription',
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
            _handlePaymentSuccess(successResponse);
          },
          onCancel: () {
            _handlePaymentError(PaymentFailureResponse(
              2, // PAYMENT_CANCELLED
              'Payment cancelled by user',
              {},
            ));
          },
        );
      } else {
        _razorpay?.open(options);
      }
    } catch (e) {
      // debugPrint("Error opening Razorpay checkout: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return Scaffold(
      backgroundColor: AppColors.ink,
      body: Stack(
        children: [
          // Background orb
          Positioned(
            top: -100,
            left: -80,
            child: Container(
              width: 360,
              height: 360,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [AppColors.amber.withValues(alpha: 0.32), Colors.transparent],
                ),
              ),
            ),
          ),
          
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Row(
                    children: [
                      const Spacer(),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                          ),
                          child: const Icon(Icons.chevron_left, color: Colors.white70),
                        ),
                      ),
                    ],
                  ),
                ),
                
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        const SizedBox(height: 30),
                        // Crown
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: const Color(0xFF1A1A2E),
                            borderRadius: BorderRadius.circular(26),
                            boxShadow: [
                              BoxShadow(color: AppColors.amber.withValues(alpha: 0.6), blurRadius: 40, offset: const Offset(0, 10)),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(15.0),
                            child: Image.asset('res/images/logo_transparent.png', fit: BoxFit.contain),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text("Prime Membership", style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 30)),
                        const SizedBox(height: 8),
                        const Text("Unlock exclusive discounts at premier merchants and local favorites", textAlign: TextAlign.center, style: TextStyle(color: Colors.white38, fontSize: 13, height: 1.7)),
                        const SizedBox(height: 30),
                        if (state.profile != null && state.profile!.role == 'customer') ...[
                          _buildReferralRewardCard(state),
                          const SizedBox(height: 24),
                        ],
                        // Sheet
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.055),
                            borderRadius: BorderRadius.circular(28),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: state.settings.where((s) => s.key.startsWith('PRIME_PLAN_')).isNotEmpty
                                    ? state.settings
                                        .where((s) => s.key.startsWith('PRIME_PLAN_'))
                                        .map((plan) {
                                      final parts = plan.value.split('|');
                                      final pOldPrice = (parts.isNotEmpty && parts[0].isNotEmpty) ? parts[0] : "1499";
                                      final pNewPrice = (parts.length > 1 && parts[1].isNotEmpty) ? parts[1] : pOldPrice;
                                      final pName = plan.key.replaceAll('PRIME_PLAN_', '').replaceAll('_MONTHLY', '').replaceAll('_YEARLY', '').replaceAll('_', ' ');
                                      final pType = plan.key.contains('YEARLY') ? 'YEARLY' : 'MONTHLY';
                                      return _buildPlanCard(
                                        plan.key,
                                        pName,
                                        '₹$pNewPrice',
                                        pType,
                                        originalPriceStr: '₹$pOldPrice',
                                      );
                                    }).toList()
                                    : [
                                        const Expanded(child: Center(child: Text("No plans available", style: TextStyle(color: Colors.white24)))),
                                      ],
                              ),
                              const SizedBox(height: 24),
                              TextField(
                                controller: _referralController,
                                style: const TextStyle(color: Colors.white, fontSize: 14),
                                decoration: InputDecoration(
                                  hintText: "Referral Code (Optional)",
                                  hintStyle: const TextStyle(color: Colors.white24),
                                  filled: true,
                                  fillColor: Colors.white.withValues(alpha: 0.05),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(13),
                                    borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                                  ),
                                  prefixIcon: const Icon(Icons.group_add_outlined, color: AppColors.amber, size: 20),
                                ),
                              ),
                              const SizedBox(height: 24),
                              // Dynamic Benefits from selected plan
                              if (selectedPlanId != null)
                                ...(() {
                                  final selectedPlan = state.settings.firstWhere((s) => s.key == selectedPlanId, orElse: () => AppSetting(id: 0, key: '', value: ''));
                                  final parts = selectedPlan.value.split('|');
                                  if (parts.length > 2 && parts[2].isNotEmpty) {
                                    final benefits = parts[2].split(',');
                                    return benefits.map((b) => _buildBenefit(Icons.check_circle_outline, b.trim(), "")).toList();
                                  }
                                  return [
                                    _buildBenefit(Icons.sell_outlined, "Exclusive Discounts", "Save 5–40% at 50+ premium merchants"),
                                    _buildBenefit(Icons.bolt, "Priority Access", "First access to special deals and events"),
                                  ];
                                })(),
                              const SizedBox(height: 24),
                              if (selectedPlanId != null) ...[
                                (() {
                                  final selectedPlan = state.settings.firstWhere(
                                    (s) => s.key == selectedPlanId,
                                    orElse: () => AppSetting(id: 0, key: '', value: ''),
                                  );
                                  final parts = selectedPlan.value.split('|');
                                  final pOldPrice = (parts.isNotEmpty && parts[0].isNotEmpty) ? parts[0] : "1499";
                                  final pNewPrice = (parts.length > 1 && parts[1].isNotEmpty) ? parts[1] : pOldPrice;
                                  
                                  if (pOldPrice != pNewPrice) {
                                    final discount = (double.tryParse(pOldPrice) ?? 0) - (double.tryParse(pNewPrice) ?? 0);
                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 16),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                        decoration: BoxDecoration(
                                          color: Colors.redAccent.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
                                        ),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            const Text(
                                              "Special Offer Active:",
                                              style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                                            ),
                                            Row(
                                              children: [
                                                Text(
                                                  "₹$pOldPrice",
                                                  style: const TextStyle(
                                                    color: Colors.white54,
                                                    fontSize: 13,
                                                    decoration: TextDecoration.lineThrough,
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Text(
                                                  "₹$pNewPrice + GST",
                                                  style: const TextStyle(
                                                    color: AppColors.amber,
                                                    fontSize: 15,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: Colors.redAccent,
                                                    borderRadius: BorderRadius.circular(6),
                                                  ),
                                                  child: Text(
                                                    "Save ₹${discount.toStringAsFixed(0)}",
                                                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  }
                                  return const SizedBox.shrink();
                                })(),
                              ],
                              Container(
                                width: double.infinity,
                                height: 56,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [AppColors.amber, Color(0xFFFF9D00)],
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.amber.withValues(alpha: 0.3),
                                      blurRadius: 20,
                                      offset: const Offset(0, 10),
                                    ),
                                  ],
                                ),
                                child: ElevatedButton(
                                  onPressed: state.isLoading ? null : () => _startRazorpayPayment(state),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    foregroundColor: Colors.white,
                                    shadowColor: Colors.transparent,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  ),
                                  child: Text(
                                    "GET PRIME NOW — ₹${price.toStringAsFixed(0)} + GST",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 15,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 4),
                              const Text("Cancel anytime · No hidden charges · Auto-renewal", style: TextStyle(color: Colors.white24, fontSize: 10)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanCard(String id, String name, String priceStr, String sub, {bool isBestValue = false, String? originalPriceStr}) {
    bool isSelected = selectedPlanId == id;
    final cleanPrice = double.tryParse(priceStr.replaceAll('₹', '').replaceAll(',', '')) ?? 0;
    
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            selectedPlanId = id;
            price = cleanPrice;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.amber.withValues(alpha: 0.12) : Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: isSelected ? AppColors.amber : Colors.white.withValues(alpha: 0.12),
              width: isSelected ? 2 : 1,
            ),
            boxShadow: [
              if (isSelected) BoxShadow(color: AppColors.amber.withValues(alpha: 0.2), blurRadius: 15, spreadRadius: 2),
            ],
          ),
          child: Column(
            children: [
              if (isSelected || isBestValue)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.amber : Colors.white10,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    isSelected ? "SELECTED" : "BEST VALUE",
                    style: TextStyle(
                      color: isSelected ? Colors.black : Colors.white60,
                      fontSize: 8,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              Text(
                name.toUpperCase(),
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.white38,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 12),
              if (originalPriceStr != null && originalPriceStr != priceStr)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      originalPriceStr,
                      style: const TextStyle(
                        color: Colors.redAccent,
                        fontSize: 13,
                        decoration: TextDecoration.lineThrough,
                        decorationColor: Colors.redAccent,
                        decorationThickness: 1.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      "ORIGINAL",
                      style: TextStyle(
                        color: Colors.white30,
                        fontSize: 7,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                )
              else
                const SizedBox(height: 15),
              const SizedBox(height: 2),
              Text(
                priceStr,
                style: GoogleFonts.dmMono(
                  color: isSelected ? AppColors.amber : Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                "+ GST",
                style: TextStyle(
                  color: Colors.white38,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                sub.toLowerCase(),
                style: TextStyle(
                  color: isSelected ? Colors.white70 : AppColors.text2,
                  fontSize: 11,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBenefit(IconData icon, String title, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.amber.withValues(alpha: 0.2), AppColors.amber.withValues(alpha: 0.05)],
                ),
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.amber.withValues(alpha: 0.3)),
              ),
              child: Icon(icon, color: AppColors.amber, size: 24),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (desc.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      desc,
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReferralRewardCard(AppState state) {
    final count = state.profile?.referredMembershipCount ?? 0;
    final status = state.profile?.freePrimeRequested ?? 'none';
    final double progress = (count / 10).clamp(0.0, 1.0);
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.amber.withValues(alpha: 0.15),
            Colors.white.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.amber.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.amber.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.card_giftcard, color: AppColors.amber, size: 20),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  "Refer 10 Friends & Get Free Prime!",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            "Get 10 friends to purchase Prime Membership using your referral code (${state.profile?.referralCode ?? ''}) and get 1 year of free premium access.",
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Progress: $count / 10 referred",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (progress >= 1.0)
                const Icon(Icons.check_circle, color: Colors.green, size: 18)
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.white10,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.amber),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 20),
          
          // Button or status
          if (status == 'pending')
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.blueAccent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.4)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.blueAccent),
                    ),
                  ),
                  SizedBox(width: 10),
                  Text(
                    "Request Pending Admin Approval",
                    style: TextStyle(
                      color: Colors.blueAccent,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            )
          else if (status == 'approved')
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.withValues(alpha: 0.4)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.verified, color: Colors.green, size: 18),
                  SizedBox(width: 8),
                  Text(
                    "Request Approved! Prime Activated",
                    style: TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            )
          else ...[
            if (count >= 10)
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: state.isLoading
                      ? null
                      : () async {
                          try {
                            await state.requestFreePrime();
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("Premium request sent successfully!"),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(e.toString()),
                                  backgroundColor: Colors.redAccent,
                                ),
                              );
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.amber,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    "Request Free Premium Access",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
              )
            else
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                ),
                child: const Center(
                  child: Text(
                    "Refer more users to unlock free access",
                    style: TextStyle(
                      color: Colors.white30,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}
