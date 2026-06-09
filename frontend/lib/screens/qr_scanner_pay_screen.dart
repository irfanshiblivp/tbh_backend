import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import 'package:frontend/core/app_theme.dart';
import 'package:frontend/providers/app_state.dart';
import 'package:frontend/screens/payment_success_screen.dart';

class QRScannerPayScreen extends StatefulWidget {
  final int merchantId;
  final String businessName;
  final double billAmount;
  final double discountAmount;
  final double finalAmount;

  const QRScannerPayScreen({
    super.key,
    required this.merchantId,
    required this.businessName,
    required this.billAmount,
    required this.discountAmount,
    required this.finalAmount,
  });

  @override
  State<QRScannerPayScreen> createState() => _QRScannerPayScreenState();
}

class _QRScannerPayScreenState extends State<QRScannerPayScreen> {
  final MobileScannerController _scannerController = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
  );
  bool _hasProcessed = false;
  final TextEditingController _manualUpiController = TextEditingController();

  @override
  void dispose() {
    _scannerController.dispose();
    _manualUpiController.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_hasProcessed) return;

    final List<Barcode> barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      final String? rawValue = barcode.rawValue;
      if (rawValue != null && rawValue.isNotEmpty) {
        debugPrint('Scanned barcode raw value: $rawValue');
        if (rawValue.toLowerCase().startsWith('upi://')) {
          setState(() {
            _hasProcessed = true;
          });
          _processUpiPayment(rawValue);
          break;
        }
      }
    }
  }

  Future<void> _processUpiPayment(String upiUrl) async {
    final originalUri = Uri.parse(upiUrl);
    final params = Map<String, String>.from(originalUri.queryParameters);
    final amountStr = widget.finalAmount.toStringAsFixed(2);
    params['am'] = amountStr;
    params['mam'] = amountStr;
    params['mode'] = '02';
    final uri = originalUri.replace(queryParameters: params);
    
    // Proactively close the scanner viewport
    _scannerController.stop();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Launching external UPI app (GPay, PhonePe, Paytm)..."),
        backgroundColor: AppColors.amber,
        duration: Duration(seconds: 3),
      ),
    );

    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Could not launch UPI app: $e"),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }

    if (mounted) {
      _showCompletionDialog();
    }
  }

  void _showCompletionDialog() {
    final state = context.read<AppState>();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
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
                "UPI SCAN COMPLETED",
                style: GoogleFonts.jost(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                "Please verify that you completed the payment of ₹${widget.finalAmount.toStringAsFixed(2)} inside your selected UPI app.",
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.text2, fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: state.isLoading ? null : () async {
                    Navigator.pop(context); // Close dialog
                    _recordUpiPaymentAndShowSuccess(paymentMethod: 'ONLINE');
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
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context); // Exit scanner screen
                },
                child: Text(
                  "Cancel / Go Back",
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _recordUpiPaymentAndShowSuccess({String paymentMethod = 'ONLINE'}) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator(color: AppColors.amber)),
    );

    final state = context.read<AppState>();
    final success = await state.customerPay(widget.merchantId, widget.billAmount, paymentMethod: paymentMethod);

    if (!mounted) return;
    Navigator.pop(context); // Close loading spinner

    if (success) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => PaymentSuccessScreen(
            amount: widget.finalAmount.toStringAsFixed(0),
            message: paymentMethod == 'CASH'
                ? "Cash payment recorded and discount successfully applied! You saved ₹${widget.discountAmount.toStringAsFixed(0)}."
                : "Payment successfully recorded and discount applied! You saved ₹${widget.discountAmount.toStringAsFixed(0)}.",
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
      setState(() {
        _hasProcessed = false;
      });
    }
  }

  void _showManualUpiBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: const BoxDecoration(
            color: AppColors.ink2,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "ENTER MERCHANT UPI ID",
                style: GoogleFonts.jost(
                  color: AppColors.text2,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                "Type the merchant's UPI ID (Virtual Payment Address) shown at the counter to pay ₹${widget.finalAmount.toStringAsFixed(2)} directly:",
                style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _manualUpiController,
                autofocus: true,
                style: GoogleFonts.dmMono(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  labelText: "MERCHANT UPI ID",
                  labelStyle: const TextStyle(color: AppColors.text2, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1),
                  hintText: "example@okaxis or name@ybl",
                  hintStyle: const TextStyle(color: Colors.white12),
                  filled: true,
                  fillColor: Colors.black26,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                  prefixIcon: const Icon(Icons.alternate_email, color: AppColors.amber, size: 18),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    final String val = _manualUpiController.text.trim();
                    if (val.isEmpty || !val.contains('@')) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Please enter a valid UPI ID containing '@'"), backgroundColor: Colors.redAccent),
                      );
                      return;
                    }
                    Navigator.pop(context); // Close bottom sheet
                    setState(() {
                      _hasProcessed = true;
                    });
                    
                    String cleanName = widget.businessName.replaceAll(RegExp(r'[^a-zA-Z0-9 ]'), '');
                    String generatedUpiUrl = "upi://pay?pa=$val&pn=${Uri.encodeComponent(cleanName)}&am=${widget.finalAmount.toStringAsFixed(2)}&mam=${widget.finalAmount.toStringAsFixed(2)}&cu=INR&mode=02";
                    _processUpiPayment(generatedUpiUrl);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.amber,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text("PROCEED TO PAY", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "SCAN SHOP QR CODE",
          style: GoogleFonts.jost(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
            fontSize: 16,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on, color: AppColors.amber),
            onPressed: () => _scannerController.toggleTorch(),
          ),
        ],
      ),
      body: Stack(
        children: [
          // 1. Mobile Camera Scanner
          MobileScanner(
            controller: _scannerController,
            onDetect: _onDetect,
          ),

          // 2. Translucent dark overlay with focus box
          ColorFiltered(
            colorFilter: ColorFilter.mode(
              Colors.black.withValues(alpha: 0.6),
              BlendMode.srcOut,
            ),
            child: Stack(
              children: [
                Container(
                  color: Colors.transparent,
                ),
                Center(
                  child: Container(
                    height: 260,
                    width: 260,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 3. Glowing Amber focus frame and guide line
          Center(
            child: SizedBox(
              height: 260,
              width: 260,
              child: Stack(
                children: [
                  // Outer borders
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.amber.withValues(alpha: 0.5), width: 2),
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                  // Glowing Corner accents
                  Positioned(
                    top: 0,
                    left: 0,
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: const BoxDecoration(
                        border: Border(
                          top: BorderSide(color: AppColors.amber, width: 4),
                          left: BorderSide(color: AppColors.amber, width: 4),
                        ),
                        borderRadius: BorderRadius.only(topLeft: Radius.circular(28)),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: const BoxDecoration(
                        border: Border(
                          top: BorderSide(color: AppColors.amber, width: 4),
                          right: BorderSide(color: AppColors.amber, width: 4),
                        ),
                        borderRadius: BorderRadius.only(topRight: Radius.circular(28)),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: AppColors.amber, width: 4),
                          left: BorderSide(color: AppColors.amber, width: 4),
                        ),
                        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(28)),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: AppColors.amber, width: 4),
                          right: BorderSide(color: AppColors.amber, width: 4),
                        ),
                        borderRadius: BorderRadius.only(bottomRight: Radius.circular(28)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 4. Instructional HUD and Simulated Testing Tools
          Positioned(
            bottom: 48,
            left: 24,
            right: 24,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "POINT THE CAMERA AT THE SHOP'S QR CODE",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.jost(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  "Align QR inside the focus frame to scan and pay instantly",
                  style: TextStyle(color: Colors.white38, fontSize: 11),
                ),
                const SizedBox(height: 24),
                
                // Manual UPI ID trigger for customer
                ElevatedButton.icon(
                  onPressed: _showManualUpiBottomSheet,
                  icon: const Icon(Icons.edit_note, size: 18),
                  label: const Text("ENTER UPI ID MANUALLY"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white.withValues(alpha: 0.08),
                    foregroundColor: AppColors.amber,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    side: BorderSide(color: AppColors.amber.withValues(alpha: 0.2)),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
