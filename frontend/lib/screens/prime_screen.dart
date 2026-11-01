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
      if (_referralController.text.isEmpty && state.profile != null) {
        final signupMethod = state.profile!.signupMethod;
        if (signupMethod.startsWith('Referral (') && signupMethod.endsWith(')')) {
          final code = signupMethod.substring('Referral ('.length, signupMethod.length - 1).trim();
          if (code.isNotEmpty && code != 'TBC') {
            _referralController.text = code;
          }
        }
      }
      state.loadSettings().then((_) {
        final primeSettings = state.settings.where((s) => s.key.startsWith('PRIME_PLAN_')).toList();
        final effSetting = state.settings.where((s) => s.key == 'prime_effective_amount').firstOrNull;
        if (primeSettings.isNotEmpty) {
          setState(() {
            selectedPlanId = primeSettings.first.key;
            final parts = primeSettings.first.value.split('|');
            double parsedPrice = double.tryParse(parts.length > 1 ? parts[1] : parts[0]) ?? 999;
            if (effSetting != null && double.tryParse(effSetting.value) != null) {
              parsedPrice = double.tryParse(effSetting.value)!;
            }
            price = parsedPrice;
          });
        } else if (effSetting != null && double.tryParse(effSetting.value) != null) {
          setState(() {
            selectedPlanId = 'PRIME_PLAN_ANNUAL';
            price = double.tryParse(effSetting.value) ?? 999;
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
          // Background ambient orbs using brand colors
          Positioned(
            top: -120,
            left: -100,
            child: Container(
              width: 380,
              height: 380,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [AppColors.amber.withOpacity(0.24), Colors.transparent],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -160,
            right: -120,
            child: Container(
              width: 420,
              height: 420,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [AppColors.amber2.withOpacity(0.14), Colors.transparent],
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
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.06),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white.withOpacity(0.08)),
                          ),
                          child: const Icon(Icons.chevron_left, color: Colors.white70),
                        ),
                      ),
                      const Spacer(),
                    ],
                  ),
                ),
                
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        const SizedBox(height: 10),
                        Image.asset(
                          'res/images/logo_transparent.png', 
                          height: 70, 
                          fit: BoxFit.contain,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "Prime Membership", 
                          style: GoogleFonts.playfairDisplay(
                            color: AppColors.text,
                            fontSize: 26, 
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Unlock exclusive discounts at premier merchants and local favorites", 
                          textAlign: TextAlign.center, 
                          style: GoogleFonts.jost(
                            color: AppColors.text2, 
                            fontSize: 13, 
                            height: 1.6,
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Sheet
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: AppColors.ink2,
                            borderRadius: BorderRadius.circular(28),
                            border: Border.all(color: Colors.white.withOpacity(0.05)),
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: () {
                                  final primePlans = state.settings.where((s) => s.key.startsWith('PRIME_PLAN_')).toList();
                                  final effSetting = state.settings.where((s) => s.key == 'prime_effective_amount').firstOrNull;
                                  final amtSetting = state.settings.where((s) => s.key == 'prime_amount').firstOrNull;

                                  if (primePlans.isNotEmpty) {
                                    return primePlans.map((plan) {
                                      final parts = plan.value.split('|');
                                      String pOldPrice = (parts.isNotEmpty && parts[0].isNotEmpty) ? parts[0] : "1499";
                                      String pNewPrice = (parts.length > 1 && parts[1].isNotEmpty) ? parts[1] : pOldPrice;

                                      if (amtSetting != null && amtSetting.value.trim().isNotEmpty) {
                                        pOldPrice = amtSetting.value.trim();
                                      }
                                      if (effSetting != null && effSetting.value.trim().isNotEmpty) {
                                        pNewPrice = effSetting.value.trim();
                                      }

                                      final pName = plan.key.replaceAll('PRIME_PLAN_', '').replaceAll('_MONTHLY', '').replaceAll('_YEARLY', '').replaceAll('_', ' ');
                                      final pType = plan.key.contains('YEARLY') ? 'YEARLY' : 'MONTHLY';
                                      return _buildPlanCard(
                                        plan.key,
                                        pName,
                                        '₹$pNewPrice',
                                        pType,
                                        originalPriceStr: '₹$pOldPrice',
                                      );
                                    }).toList();
                                  } else if (effSetting != null) {
                                    final pOldPrice = (amtSetting != null && amtSetting.value.trim().isNotEmpty) ? amtSetting.value.trim() : "9999";
                                    final pNewPrice = effSetting.value.trim();
                                    return [
                                      _buildPlanCard(
                                        'PRIME_PLAN_ANNUAL',
                                        'ANNUAL',
                                        '₹$pNewPrice',
                                        'YEARLY',
                                        originalPriceStr: '₹$pOldPrice',
                                      ),
                                    ];
                                  } else {
                                    return const [
                                      Expanded(child: Center(child: Text("No plans available", style: TextStyle(color: Colors.white24)))),
                                    ];
                                  }
                                }(),
                              ),
                              const SizedBox(height: 24),
                              TextField(
                                controller: _referralController,
                                style: GoogleFonts.jost(color: Colors.white, fontSize: 14),
                                decoration: InputDecoration(
                                  hintText: "Referral Code (Optional)",
                                  hintStyle: GoogleFonts.jost(color: Colors.white30),
                                  filled: true,
                                  fillColor: Colors.white.withOpacity(0.03),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: BorderSide(color: Colors.white.withOpacity(0.06)),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: const BorderSide(color: AppColors.amber),
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
                                  String pOldPrice = (parts.isNotEmpty && parts[0].isNotEmpty) ? parts[0] : "1499";
                                  String pNewPrice = (parts.length > 1 && parts[1].isNotEmpty) ? parts[1] : pOldPrice;

                                  final effSetting = state.settings.where((s) => s.key == 'prime_effective_amount').firstOrNull;
                                  final amtSetting = state.settings.where((s) => s.key == 'prime_amount').firstOrNull;
                                  if (amtSetting != null && amtSetting.value.trim().isNotEmpty) {
                                    pOldPrice = amtSetting.value.trim();
                                  }
                                  if (effSetting != null && effSetting.value.trim().isNotEmpty) {
                                    pNewPrice = effSetting.value.trim();
                                  }
                                  
                                  if (pOldPrice != pNewPrice) {
                                    final discount = (double.tryParse(pOldPrice) ?? 0) - (double.tryParse(pNewPrice) ?? 0);
                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 16),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                        decoration: BoxDecoration(
                                          color: Colors.redAccent.withOpacity(0.08),
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(color: Colors.redAccent.withOpacity(0.2)),
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              "Special Offer Active:",
                                              style: GoogleFonts.jost(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                                            ),
                                            const SizedBox(height: 6),
                                            Row(
                                              children: [
                                                Text(
                                                  "₹$pOldPrice",
                                                  style: GoogleFonts.dmMono(
                                                    color: Colors.white38,
                                                    fontSize: 13,
                                                    decoration: TextDecoration.lineThrough,
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Text(
                                                  "₹$pNewPrice + GST",
                                                  style: GoogleFonts.dmMono(
                                                    color: AppColors.amber2,
                                                    fontSize: 18,
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
                                                    style: GoogleFonts.jost(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
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
                                    colors: [AppColors.amber, AppColors.amber2],
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.amber.withOpacity(0.3),
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
                                    style: GoogleFonts.jost(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 15,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                ),
                              ),
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
    
    // Clean original and discount values
    final displayOriginal = originalPriceStr ?? priceStr;
    final displayDiscount = priceStr;
    
    int discountPct = 0;
    if (originalPriceStr != null) {
      final double orig = double.tryParse(originalPriceStr.replaceAll('₹', '').replaceAll(',', '')) ?? 0;
      final double disc = double.tryParse(priceStr.replaceAll('₹', '').replaceAll(',', '')) ?? 0;
      if (orig > 0 && disc > 0) {
        discountPct = (((orig - disc) / orig) * 100).round();
      }
    }
    
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
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.amber.withOpacity(0.08) : Colors.white.withOpacity(0.02),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isSelected ? AppColors.amber : Colors.white.withOpacity(0.06),
              width: isSelected ? 2 : 1,
            ),
            boxShadow: [
              if (isSelected) BoxShadow(color: AppColors.amber.withOpacity(0.15), blurRadius: 15),
            ],
          ),
          child: Column(
            children: [
              // Best Value / Selected badge
              if (isSelected || isBestValue)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.amber : Colors.white10,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    isSelected ? "SELECTED" : "BEST VALUE",
                    style: GoogleFonts.jost(
                      color: isSelected ? Colors.black : Colors.white60,
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                )
              else
                const SizedBox(height: 24),
              // Plan Name
              Text(
                name.toUpperCase(),
                style: GoogleFonts.jost(
                  color: isSelected ? Colors.white : AppColors.text2,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 14),
              
              // Original Price - SHOWN BIG
              Text(
                displayOriginal,
                style: GoogleFonts.playfairDisplay(
                  color: isSelected ? Colors.white38 : Colors.white24,
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  decoration: TextDecoration.lineThrough,
                  decorationColor: AppColors.amber,
                  decorationThickness: 2.0,
                ),
              ),
              const SizedBox(height: 6),
              
              // Highlighted Offer Box for discounted price
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  gradient: isSelected 
                      ? const LinearGradient(colors: [AppColors.amber, AppColors.amber2])
                      : null,
                  color: isSelected ? null : Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? Colors.transparent : Colors.white.withOpacity(0.06),
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      displayDiscount,
                      style: GoogleFonts.dmMono(
                        color: isSelected ? Colors.white : AppColors.text,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      "+ GST",
                      style: GoogleFonts.jost(
                        color: isSelected ? Colors.white60 : AppColors.text2,
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              
              // Save Badge
              if (discountPct > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.greenAccent.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.greenAccent.withOpacity(0.25)),
                  ),
                  child: Text(
                    "SAVE $discountPct%",
                    style: GoogleFonts.jost(
                      color: Colors.greenAccent,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              const SizedBox(height: 8),
              // Billing cycle
              Text(
                "billed $sub".toLowerCase(),
                style: GoogleFonts.jost(
                  color: isSelected ? AppColors.text : AppColors.text2,
                  fontSize: 10,
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
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.02),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.amber.withOpacity(0.15), AppColors.amber.withOpacity(0.02)],
                ),
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.amber.withOpacity(0.2)),
              ),
              child: Icon(icon, color: AppColors.amber2, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.jost(
                      color: AppColors.text,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (desc.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      desc,
                      style: GoogleFonts.jost(
                        color: AppColors.text2,
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

}

