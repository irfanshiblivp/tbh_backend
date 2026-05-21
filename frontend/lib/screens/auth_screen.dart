import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:frontend/core/app_theme.dart';
import 'package:frontend/providers/app_state.dart';
import 'package:frontend/screens/forgot_password_screen.dart';
import 'package:url_launcher/url_launcher.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool isLogin = true;
  bool isMerchantSignup = false;
  final TextEditingController _userController = TextEditingController();
  final TextEditingController _passController = TextEditingController();
  final TextEditingController _repeatPassController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  bool termsAccepted = false;
  bool _showPassword = false;
  String selectedState = 'Select State';
  final List<String> states = [
    'Select State',
    'Andhra Pradesh',
    'Arunachal Pradesh',
    'Assam',
    'Bihar',
    'Chhattisgarh',
    'Goa',
    'Gujarat',
    'Haryana',
    'Himachal Pradesh',
    'Jharkhand',
    'Karnataka',
    'Kerala',
    'Madhya Pradesh',
    'Maharashtra',
    'Manipur',
    'Meghalaya',
    'Mizoram',
    'Nagaland',
    'Odisha',
    'Punjab',
    'Rajasthan',
    'Sikkim',
    'Tamil Nadu',
    'Telangana',
    'Tripura',
    'Uttar Pradesh',
    'Uttarakhand',
    'West Bengal',
  ];

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return Scaffold(
      body: Stack(
        children: [
          // Background orbs simulation
          Positioned(
            top: -100,
            left: -50,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.amber.withOpacity(0.3),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 100,
            right: -50,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Colors.blueAccent.withOpacity(0.1),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          Positioned.fill(
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    const SizedBox(height: 60),
                    // Logo
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1A2E),
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.amber.withOpacity(0.4),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Image.asset(
                          'res/images/logo_transparent.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      "The Baron Club",
                      textAlign: TextAlign.center,
                      style: Theme.of(
                        context,
                      ).textTheme.displayLarge?.copyWith(fontSize: 28),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Experience luxury savings",
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 40),

                    // Auth Sheet
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.1),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Tabs
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.black26,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () => setState(() => isLogin = true),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 10,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isLogin
                                            ? AppColors.amber.withOpacity(0.2)
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(10),
                                        border: isLogin
                                            ? Border.all(
                                                color: AppColors.amber
                                                    .withOpacity(0.3),
                                              )
                                            : null,
                                      ),
                                      child: Text(
                                        "Login",
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: isLogin
                                              ? AppColors.amber
                                              : Colors.white38,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () =>
                                        setState(() => isLogin = false),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 10,
                                      ),
                                      decoration: BoxDecoration(
                                        color: !isLogin
                                            ? AppColors.amber.withOpacity(0.2)
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(10),
                                        border: !isLogin
                                            ? Border.all(
                                                color: AppColors.amber
                                                    .withOpacity(0.3),
                                              )
                                            : null,
                                      ),
                                      child: Text(
                                        "Sign Up",
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: !isLogin
                                              ? AppColors.amber
                                              : Colors.white38,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Fields
                          if (isLogin) ...[
                            _buildLabel("Email"),
                            _buildField(
                              _emailController,
                              placeholder: "you@example.com",
                            ),
                          ] else ...[
                            _buildLabel("Full Name"),
                            _buildField(
                              _userController,
                              placeholder: "e.g. John Doe",
                            ),
                            const SizedBox(height: 16),
                            _buildLabel("Email"),
                            _buildField(
                              _emailController,
                              placeholder: "you@example.com",
                            ),
                          ],
                          const SizedBox(height: 16),
                          _buildLabel("Password"),
                          _buildField(
                            _passController,
                            isPassword: true,
                            placeholder: "Min 8 characters",
                          ),

                          if (!isLogin) ...[
                            const SizedBox(height: 16),
                            _buildLabel("Repeat Password"),
                            _buildField(
                              _repeatPassController,
                              isPassword: true,
                              placeholder: "Confirm your password",
                            ),
                          ],

                          if (isLogin) ...[
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        const ForgotPasswordScreen(),
                                  ),
                                ),
                                child: const Text(
                                  "Forgot password?",
                                  style: TextStyle(color: AppColors.amber),
                                ),
                              ),
                            ),
                          ] else ...[
                            _buildLabel("Phone Number (Optional)"),
                            _buildField(
                              _phoneController,
                              placeholder: "+91 00000 00000",
                            ),
                            const SizedBox(height: 16),
                            _buildLabel("Select State"),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.white10),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButtonFormField<String>(
                                  value: selectedState,
                                  dropdownColor: AppColors.ink,
                                  style: GoogleFonts.jost(color: Colors.white, fontSize: 14),
                                  decoration: const InputDecoration(border: InputBorder.none),
                                  items: states.map((String stateName) {
                                    return DropdownMenuItem<String>(
                                      value: stateName,
                                      child: Text(
                                        stateName,
                                        style: TextStyle(
                                          color: stateName == 'Select State' ? Colors.white38 : Colors.white,
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (String? val) {
                                    if (val != null) {
                                      setState(() {
                                        selectedState = val;
                                      });
                                    }
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Checkbox(
                                  value: termsAccepted,
                                  activeColor: AppColors.amber,
                                  onChanged: (val) =>
                                      setState(() => termsAccepted = val!),
                                ),
                                 Expanded(
                                  child: Wrap(
                                    children: [
                                      const Text(
                                        "I agree to the ",
                                        style: TextStyle(color: Colors.white70, fontSize: 12),
                                      ),
                                      GestureDetector(
                                        onTap: () => _launchUrl("https://thebaronclub.com/legal#terms"),
                                        child: const Text(
                                          "Terms & Conditions",
                                          style: TextStyle(color: AppColors.amber, fontSize: 12, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                      const Text(
                                        " and ",
                                        style: TextStyle(color: Colors.white70, fontSize: 12),
                                      ),
                                      GestureDetector(
                                        onTap: () => _launchUrl("http://thebaronclub.com/legal#privacy"),
                                        child: const Text(
                                          "Privacy Policy",
                                          style: TextStyle(color: AppColors.amber, fontSize: 12, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                          ],

                          const SizedBox(height: 8),

                          ElevatedButton(
                            onPressed: state.isLoading
                                ? null
                                : () async {
                                    try {
                                      if (isLogin) {
                                        final success = await state.login(
                                          _emailController.text,
                                          _passController.text,
                                        );
                                        if (!success && mounted) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                "Login failed: Invalid credentials",
                                              ),
                                            ),
                                          );
                                        }
                                      } else {
                                        if (_passController.text !=
                                            _repeatPassController.text) {
                                          throw Exception(
                                            "Passwords do not match",
                                          );
                                        }
                                        if (_passController.text.length < 8) {
                                          throw Exception(
                                            "The password field must be at least 8 characters.",
                                          );
                                        }
                                        if (selectedState == 'Select State') {
                                          throw Exception(
                                            "Please select your state",
                                          );
                                        }
                                        if (!termsAccepted) {
                                          throw Exception(
                                            "Please accept the Terms & Conditions",
                                          );
                                        }

                                        final success = await state.signup({
                                          'name': _userController.text,
                                          'email': _emailController.text,
                                          'password': _passController.text,
                                          'role': 'customer',
                                          'phone': _phoneController.text,
                                          'state': selectedState,
                                        });
                                        if (!success && mounted) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text("Signup failed"),
                                            ),
                                          );
                                        }
                                      }
                                    } catch (e) {
                                      if (mounted) {
                                        String errorMsg = e
                                            .toString()
                                            .replaceAll('Exception: ', '');
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(errorMsg),
                                            backgroundColor: Colors.redAccent,
                                          ),
                                        );
                                      }
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.amber,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              elevation: 8,
                              shadowColor: AppColors.amber.withOpacity(0.5),
                            ),
                            child: state.isLoading
                                ? const CircularProgressIndicator(
                                    color: Colors.white,
                                  )
                                : Text(
                                    isLogin ? "Login" : "Create Account",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                          ),

                          const SizedBox(height: 12),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),
                    const Text(
                      "By continuing you agree to our Terms & Privacy Policy",
                      style: TextStyle(color: Colors.white24, fontSize: 10),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          color: AppColors.text2,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildField(
    TextEditingController controller, {
    bool isPassword = false,
    String? placeholder,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword && !_showPassword,
      style: const TextStyle(color: Colors.white, fontSize: 15),
      decoration: InputDecoration(
        hintText: placeholder,
        hintStyle: const TextStyle(color: Colors.white24),
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
        suffixIcon: isPassword ? IconButton(
          icon: Icon(
            _showPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
            color: Colors.white38,
            size: 20,
          ),
          onPressed: () => setState(() => _showPassword = !_showPassword),
        ) : null,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: const BorderSide(color: AppColors.amber),
        ),
      ),
    );
  }

  Widget _socialButton(String text) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
  void _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
