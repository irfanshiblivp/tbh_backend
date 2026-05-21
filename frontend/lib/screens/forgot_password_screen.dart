import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_theme.dart';
import '../providers/app_state.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  final _otpController = TextEditingController();
  final _passController = TextEditingController();
  final _confirmPassController = TextEditingController();
  bool otpSent = false;
  bool _showPassword = false;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1E),
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            Text(
              otpSent ? "Verify & Reset" : "Forgot Password", 
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)
            ),
            const SizedBox(height: 8),
            Text(
              otpSent 
                ? "Enter the 6-digit code sent to ${_emailController.text}" 
                : "Enter your registered email to receive a password reset code.", 
              style: const TextStyle(color: Colors.white54)
            ),
            const SizedBox(height: 40),
            
            if (!otpSent) ...[
              _buildLabel("Email Address"),
              TextField(
                controller: _emailController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: "you@example.com",
                  hintStyle: const TextStyle(color: Colors.white24),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.05),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                  prefixIcon: const Icon(Icons.email_outlined, color: Colors.white24),
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: state.isLoading ? null : () async {
                  if (_emailController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please enter your email")));
                    return;
                  }
                  try {
                    await state.forgotPassword(_emailController.text);
                    setState(() => otpSent = true);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Verification code sent!"))
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: Colors.redAccent)
                      );
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.amber,
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 8,
                  shadowColor: AppColors.amber.withOpacity(0.3),
                ),
                child: state.isLoading 
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                  : const Text("Get Reset Code", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
              ),
            ] else ...[
              _buildLabel("6-Digit Code"),
              TextField(
                controller: _otpController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 28, letterSpacing: 12, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  counterText: "",
                  hintText: "000000",
                  hintStyle: const TextStyle(color: Colors.white10, letterSpacing: 12),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.05),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 24),
              _buildLabel("New Password"),
              TextField(
                controller: _passController,
                obscureText: !_showPassword,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: "Min. 8 characters",
                  hintStyle: const TextStyle(color: Colors.white24),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.05),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                  prefixIcon: const Icon(Icons.lock_outline, color: Colors.white24),
                  suffixIcon: IconButton(
                    icon: Icon(_showPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: Colors.white24),
                    onPressed: () => setState(() => _showPassword = !_showPassword),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _buildLabel("Confirm New Password"),
              TextField(
                controller: _confirmPassController,
                obscureText: !_showPassword,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: "Repeat new password",
                  hintStyle: const TextStyle(color: Colors.white24),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.05),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                  prefixIcon: const Icon(Icons.lock_reset, color: Colors.white24),
                  suffixIcon: IconButton(
                    icon: Icon(_showPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: Colors.white24),
                    onPressed: () => setState(() => _showPassword = !_showPassword),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: state.isLoading ? null : () async {
                  if (_passController.text != _confirmPassController.text) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Passwords do not match"), backgroundColor: Colors.redAccent));
                    return;
                  }
                  if (_passController.text.length < 8) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Password must be at least 8 characters"), backgroundColor: Colors.redAccent));
                    return;
                  }
                  try {
                    await state.resetPassword(
                      _emailController.text, 
                      _otpController.text, 
                      _passController.text
                    );
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Password reset successfully! You can now login."), backgroundColor: Colors.green)
                      );
                      Navigator.pop(context);
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: Colors.redAccent)
                      );
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.amber,
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 8,
                  shadowColor: AppColors.amber.withOpacity(0.3),
                ),
                child: state.isLoading 
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                  : const Text("Reset Password", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 16),
              Center(
                child: TextButton(
                  onPressed: () => setState(() => otpSent = false),
                  child: const Text("Change Email", style: TextStyle(color: AppColors.amber)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(color: AppColors.text2, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2),
      ),
    );
  }
}
