import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:frontend/core/app_theme.dart';
import 'package:frontend/providers/app_state.dart';

class VerificationScreen extends StatefulWidget {
  const VerificationScreen({super.key});

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  bool isResending = false;
  final TextEditingController _otpController = TextEditingController();

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return Scaffold(
      backgroundColor: AppColors.ink,
      body: Stack(
        children: [
          // Decorative orbs
          Positioned(
            top: -100,
            right: -50,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [AppColors.amber.withOpacity(0.15), Colors.transparent],
                ),
              ),
            ),
          ),
          
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: AppColors.amber.withOpacity(0.1),
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.amber.withOpacity(0.3)),
                    ),
                    child: const Icon(Icons.email_outlined, size: 48, color: AppColors.amber),
                  ),
                  const SizedBox(height: 40),
                  Text(
                    "Verify your email",
                    style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 32),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Please enter the 6-digit OTP sent to\n${state.profile?.email ?? 'your email'}",
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white70, fontSize: 16, height: 1.5),
                  ),
                  const SizedBox(height: 32),
                  
                  TextField(
                    controller: _otpController,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 16,
                    ),
                    decoration: InputDecoration(
                      counterText: "",
                      hintText: "000000",
                      hintStyle: TextStyle(color: Colors.white12, letterSpacing: 16),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.05),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: AppColors.amber.withOpacity(0.3)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: AppColors.amber),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  ElevatedButton(
                    onPressed: state.isLoading ? null : () async {
                      if (_otpController.text.length != 6) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Please enter a valid 6-digit OTP")),
                        );
                        return;
                      }
                      
                      try {
                        final success = await state.verifyOtp(_otpController.text);
                        if (success) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Email verified successfully!")),
                            );
                          }
                        } else {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Verification failed. Please check the OTP."),
                                backgroundColor: Colors.redAccent,
                              ),
                            );
                          }
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(e.toString().replaceAll('Exception: ', '')),
                              backgroundColor: Colors.redAccent,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.amber,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 56),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: Text(
                      state.isLoading ? "Verifying..." : "Verify OTP",
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  TextButton(
                    onPressed: isResending ? null : () async {
                      setState(() => isResending = true);
                      try {
                        await state.resendVerification();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("New OTP sent to your email!")),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(e.toString()), backgroundColor: Colors.redAccent),
                          );
                        }
                      } finally {
                        if (mounted) setState(() => isResending = false);
                      }
                    },
                    child: Text(
                      isResending ? "Resending..." : "Resend OTP",
                      style: const TextStyle(color: AppColors.amber, fontWeight: FontWeight.bold),
                    ),
                  ),
                  
                  const SizedBox(height: 40),
                  TextButton(
                    onPressed: () => state.logout(),
                    child: const Text("Use another account", style: TextStyle(color: Colors.white38)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
