import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:frontend/core/app_theme.dart';
import 'package:frontend/providers/app_state.dart';
import 'package:frontend/main.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'prime_screen.dart';
import 'package:frontend/models/models.dart';


class ProfileScreen extends StatelessWidget {
  // Profile screen display
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final profile = state.profile;

    if (state.settings.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        state.loadSettings();
      });
    }

    return Scaffold(
      backgroundColor: const Color(0xFF07070A),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Profile Hero
            Container(
              padding: const EdgeInsets.only(top: 80, bottom: 40),
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.amber.withValues(alpha: 0.12),
                    const Color(0xFF07070A),
                  ],
                ),
              ),
              child: Column(
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: AppColors.ink2,
                      borderRadius: BorderRadius.circular(35),
                      border: Border.all(color: AppColors.amber.withValues(alpha: 0.3), width: 2),
                      boxShadow: [
                        BoxShadow(color: AppColors.amber.withValues(alpha: 0.15), blurRadius: 40, spreadRadius: 5),
                      ],
                    ),
                    child: const Icon(Icons.person_outline, size: 48, color: AppColors.amber),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    profile?.username.toUpperCase() ?? "USER",
                    style: GoogleFonts.playfairDisplay(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    profile?.email ?? "",
                    style: GoogleFonts.jost(color: AppColors.text2, fontSize: 13),
                  ),
                  if (profile?.customerNumber != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      "CUSTOMER ID: ${profile!.customerNumber}",
                      style: GoogleFonts.dmMono(
                        color: AppColors.amber,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                  (() {
                    final bool isActivePrime = profile?.isPrime == true;
                    final bool isExpiredPrime = !isActivePrime && profile?.primeExpiresAt != null;
                    if (isActivePrime) {
                      return Column(
                        children: [
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFFD4AF37),
                                  Color(0xFFFFDF73),
                                  Color(0xFFAA7C11),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFD4AF37).withValues(alpha: 0.3),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.star, color: Color(0xFF1A1A2E), size: 16),
                                const SizedBox(width: 6),
                                Text(
                                  "PRIME MEMBER",
                                  style: GoogleFonts.dmSans(
                                    color: const Color(0xFF1A1A2E),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Valid till ${_formatDate(profile?.primeExpiresAt)}",
                            style: GoogleFonts.jost(
                              color: const Color(0xFFD4AF37).withValues(alpha: 0.85),
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      );
                    } else if (isExpiredPrime) {
                      return Column(
                        children: [
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.red.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.redAccent.withValues(alpha: 0.4)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 16),
                                const SizedBox(width: 6),
                                Text(
                                  "MEMBERSHIP EXPIRED",
                                  style: GoogleFonts.dmSans(
                                    color: Colors.redAccent,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Expired on ${_formatDate(profile?.primeExpiresAt)}",
                            style: GoogleFonts.jost(
                              color: Colors.redAccent.withValues(alpha: 0.75),
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      );
                    }
                    return const SizedBox.shrink();
                  })(),
                ],
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _buildReferralCard(context, state),
                  const SizedBox(height: 20),
                  
                  _buildMenuCard([
                    _buildMenuItem(Icons.edit_outlined, "Edit Profile", () {
                      _showEditProfileDialog(context, state);
                    }),
                    _buildMenuItem(Icons.account_balance_outlined, "Bank Details", () {
                      _showBankDetailsDialog(context, profile);
                    }),
                    _buildMenuItem(Icons.account_balance_wallet_outlined, "Withdraw Bonus", () {
                      _showWithdrawDialog(context, state);
                    }),
                    _buildMenuItem(Icons.history_outlined, "Withdrawal History", () {
                      _showWithdrawalHistory(context, state);
                    }),
                    _buildMenuItem(Icons.lock_outline, "Change Password", () {
                      _showChangePasswordDialog(context, state);
                    }),
                    _buildMenuItem(Icons.support_agent_outlined, "Contact Us", () {
                      _showContactUsDialog(context, state);
                    }),
                    _buildMenuItem(Icons.logout, "Logout", () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          backgroundColor: const Color(0xFF1A1A2E),
                          title: const Text("Logout"),
                          content: const Text("Are you sure you want to logout?"),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true), 
                              child: const Text("Logout", style: TextStyle(color: Colors.redAccent)),
                            ),
                          ],
                        ),
                      );

                      if (confirm == true) {
                        await state.logout();
                        if (context.mounted) {
                          Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
                            MaterialPageRoute(builder: (_) => const RootScreen()),
                            (route) => false,
                          );
                        }
                      }
                    }, isDanger: true),
                  ]),
                  
                  const SizedBox(height: 24),
                  
                  // Legal Section
                  const Padding(
                    padding: EdgeInsets.only(left: 4, bottom: 12),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text("LEGAL & POLICIES", style: TextStyle(color: Colors.white30, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
                    ),
                  ),
                  _buildMenuCard([
                    _buildMenuItem(Icons.description_outlined, "Terms & Conditions", () {
                      _launchUrl("https://thebaronclub.com/legal#terms");
                    }),
                    _buildMenuItem(Icons.privacy_tip_outlined, "Privacy Policy", () {
                      _launchUrl("http://thebaronclub.com/legal#privacy");
                    }),
                    _buildMenuItem(Icons.assignment_return_outlined, "Refund Policy", () {
                      _launchUrl("https://thebaronclub.com/legal#refund");
                    }),
                  ]),
                  
                  const SizedBox(height: 30),
                  const Text("The Baron Club", style: TextStyle(color: Colors.white12, fontSize: 10, letterSpacing: 0.5)),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReferralCard(BuildContext context, AppState state) {
    final profile = state.profile;
    final bool isPrime = profile?.isPrime ?? false;
    final bool isExpiredPrime = !isPrime && profile?.primeExpiresAt != null;
    final String referralCode = profile?.referralCode ?? "TBC000";

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isPrime 
            ? [const Color(0xFF1C1810), const Color(0xFF0C0C11)]
            : isExpiredPrime
              ? [const Color(0xFF1A0A0A), const Color(0xFF0C0C11)]
              : [const Color(0xFF140E0E), const Color(0xFF0C0C11)],
        ),
        border: Border.all(
          color: isPrime 
            ? AppColors.amber.withValues(alpha: 0.3) 
            : isExpiredPrime 
              ? Colors.redAccent.withValues(alpha: 0.2) 
              : AppColors.line,
          width: 1,
        ),
        boxShadow: [
          if (isPrime) BoxShadow(color: AppColors.amber.withValues(alpha: 0.05), blurRadius: 30, spreadRadius: 5),
          if (isExpiredPrime) BoxShadow(color: Colors.redAccent.withValues(alpha: 0.04), blurRadius: 20, spreadRadius: 3),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "REFERRAL BALANCE",
                      style: GoogleFonts.jost(
                        color: AppColors.text2,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "₹${profile?.referralBalance.toStringAsFixed(0) ?? "0"}",
                      style: GoogleFonts.dmMono(
                        color: Colors.white,
                        fontSize: 38,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.line),
                  ),
                  child: Icon(
                    isPrime ? Icons.auto_awesome : Icons.card_giftcard,
                    color: AppColors.amber,
                    size: 24,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Middle section: Totals
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "TOTAL EARNED",
                        style: GoogleFonts.jost(color: AppColors.text2, fontSize: 9, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "₹${profile?.referralTotalEarned.toStringAsFixed(0) ?? "0"}",
                        style: GoogleFonts.dmMono(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "TOTAL SAVED",
                        style: GoogleFonts.jost(color: AppColors.text2, fontSize: 9, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "₹${state.totalSaved.toStringAsFixed(0)}",
                        style: GoogleFonts.dmMono(color: AppColors.amber, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "REFERRED MEMBERS",
                        style: GoogleFonts.jost(color: AppColors.text2, fontSize: 9, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "${profile?.referredMembershipCount ?? 0}",
                        style: GoogleFonts.dmMono(color: Colors.greenAccent, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Referral Code Box
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.amber.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.confirmation_number_outlined, color: AppColors.amber, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "YOUR REFERRAL CODE",
                          style: GoogleFonts.jost(
                            color: AppColors.text2,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          referralCode,
                          style: GoogleFonts.dmMono(
                            color: AppColors.amber,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: referralCode));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("Referral code \"$referralCode\" copied!"),
                          backgroundColor: AppColors.amber,
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.amber.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(9),
                        border: Border.all(color: AppColors.amber.withValues(alpha: 0.3)),
                      ),
                      child: const Icon(Icons.copy_rounded, color: AppColors.amber, size: 16),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Divider(color: AppColors.line, height: 1),
            const SizedBox(height: 16),
            // Bottom section: Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Share button
                TextButton.icon(
                  onPressed: () {
                    final text = "Join The Baron Club and save 1-100% at the finest merchants! Use my referral code: $referralCode\nDownload the app now!";
                    if (kIsWeb) {
                      Clipboard.setData(ClipboardData(text: text));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Referral message copied to clipboard!"), backgroundColor: AppColors.amber),
                      );
                    } else {
                      Share.share(text);
                    }
                  },
                  icon: const Icon(Icons.share, color: AppColors.amber, size: 16),
                  label: Text(
                    "SHARE",
                    style: GoogleFonts.jost(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    backgroundColor: Colors.white.withValues(alpha: 0.04),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                if (!isPrime && !isExpiredPrime)
                  ElevatedButton(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PrimeScreen())),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.amber,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 8,
                      shadowColor: AppColors.amber.withValues(alpha: 0.4),
                    ),
                    child: const Text(
                      "JOIN PRIME",
                      style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 1),
                    ),
                  )
                else if (isExpiredPrime)
                  ElevatedButton.icon(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PrimeScreen())),
                    icon: const Icon(Icons.refresh_rounded, size: 16),
                    label: const Text(
                      "RENEW MEMBERSHIP",
                      style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 0.5),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 8,
                      shadowColor: Colors.redAccent.withValues(alpha: 0.4),
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.amber.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.amber.withValues(alpha: 0.2)),
                    ),
                    child: const Text(
                      "MEMBERSHIP ACTIVE",
                      style: TextStyle(color: AppColors.amber, fontWeight: FontWeight.bold, fontSize: 10),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuCard(List<Widget> items) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.045),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.09)),
      ),
      child: Column(children: items),
    );
  }

  Widget _buildMenuItem(IconData icon, String label, VoidCallback onTap, {bool isDanger = false}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.06))),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isDanger ? Colors.red.withValues(alpha: 0.08) : Colors.white.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(11),
                border: Border.all(color: isDanger ? Colors.red.withValues(alpha: 0.14) : Colors.white.withValues(alpha: 0.09)),
              ),
              child: Icon(icon, size: 18, color: isDanger ? Colors.redAccent : Colors.white54),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label, style: TextStyle(color: isDanger ? Colors.redAccent : Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
            ),
            Icon(Icons.chevron_right, size: 18, color: Colors.white.withValues(alpha: 0.2)),
          ],
        ),
      ),
    );
  }

  void _showBankDetailsDialog(BuildContext context, dynamic profile) {
    final state = context.read<AppState>();
    final nameController = TextEditingController(text: profile?.bankAccountHolderName);
    final numberController = TextEditingController(text: profile?.bankAccountNumber);
    final ifscController = TextEditingController(text: profile?.bankIfsc);
    final bankController = TextEditingController(text: profile?.bankName);
    final upiController = TextEditingController(text: profile?.bankUpiId);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text("Update Bank Details"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildEditField("Account Holder", nameController),
              _buildEditField("Account Number", numberController),
              _buildEditField("IFSC Code", ifscController),
              _buildEditField("Bank Name", bankController),
              _buildEditField("UPI ID", upiController),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              await state.updateProfile({
                'bank_account_holder_name': nameController.text,
                'bank_account_number': numberController.text,
                'bank_ifsc': ifscController.text,
                'bank_name': bankController.text,
                'bank_upi_id': upiController.text,
              });
              if (context.mounted) Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.amber, foregroundColor: Colors.black),
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  Widget _buildEditField(String label, TextEditingController controller, {bool obscureText = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(), style: const TextStyle(color: AppColors.amber, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1)),
          const SizedBox(height: 6),
          TextField(
            controller: controller,
            obscureText: obscureText,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.05),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bankInfoTile(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.white38, fontSize: 10)),
          Text(value ?? "Not set", style: const TextStyle(color: Colors.white, fontSize: 14)),
        ],
      ),
    );
  }
  void _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
  void _showEditProfileDialog(BuildContext context, AppState state) {
    final nameController = TextEditingController(text: state.profile?.username);
    final phoneController = TextEditingController(text: state.profile?.phone);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text("Edit Profile"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildEditField("Full Name", nameController),
            _buildEditField("Phone Number", phoneController),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              final phone = phoneController.text.trim();
              if (phone.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Phone number is required"), backgroundColor: Colors.redAccent),
                );
                return;
              }
              final digitsOnly = phone.replaceAll(RegExp(r'\D'), '');
              if (digitsOnly.length != 10) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Please enter a valid 10-digit phone number"), backgroundColor: Colors.redAccent),
                );
                return;
              }
              await state.updateProfile({
                'name': nameController.text,
                'phone': phone,
              });
              if (context.mounted) Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Profile updated!")));
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.amber, foregroundColor: Colors.black),
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  void _showWithdrawDialog(BuildContext context, AppState state) {
    final profile = state.profile;
    final hasBank = (profile?.bankAccountNumber != null && profile!.bankAccountNumber!.isNotEmpty) ||
                    (profile?.bankUpiId != null && profile!.bankUpiId!.isNotEmpty);

    if (!hasBank) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF1A1A2E),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: AppColors.amber),
              SizedBox(width: 10),
              Text("Bank Details Required"),
            ],
          ),
          content: const Text(
            "To withdraw your referral bonus, you must first add your bank account or UPI details.",
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel", style: TextStyle(color: Colors.white54)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _showBankDetailsDialog(context, profile);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.amber,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text("Add Bank Details"),
            ),
          ],
        ),
      );
      return;
    }

    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text("Withdraw Bonus"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Available Balance: ₹${state.profile?.referralBalance.toStringAsFixed(2)}", 
              style: const TextStyle(color: AppColors.amber, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: "Amount to Withdraw",
                hintText: "Min ₹100",
                labelStyle: TextStyle(color: Colors.white60),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.isEmpty) return;
              try {
                await state.requestWithdrawal(double.parse(controller.text));
                if (context.mounted) Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Withdrawal request submitted!")));
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.amber, foregroundColor: Colors.black),
            child: const Text("Submit Request"),
          ),
        ],
      ),
    );
  }

  void _showWithdrawalHistory(BuildContext context, AppState state) async {
    showDialog(
      context: context,
      builder: (context) => FutureBuilder<List<dynamic>>(
        future: state.getPayoutHistory(),
        builder: (context, snapshot) {
          return AlertDialog(
            backgroundColor: const Color(0xFF1A1A2E),
            title: const Text("Withdrawal History"),
            content: SizedBox(
              width: double.maxFinite,
              height: 300,
              child: snapshot.connectionState == ConnectionState.waiting
                ? const Center(child: CircularProgressIndicator(color: AppColors.amber))
                : snapshot.hasError
                  ? Center(child: Text("Error: ${snapshot.error}", style: const TextStyle(color: Colors.redAccent)))
                  : snapshot.data == null || snapshot.data!.isEmpty
                    ? const Center(child: Text("No history found", style: TextStyle(color: Colors.white24)))
                    : ListView.builder(
                        itemCount: snapshot.data!.length,
                        itemBuilder: (context, index) {
                          final p = snapshot.data![index];
                          final status = p['status']?.toString() ?? 'pending';
                          final isCompleted = status == 'completed';
                          final isDeclined = status == 'declined';
                          
                          Color statusColor = AppColors.amber;
                          if (isCompleted) statusColor = Colors.green;
                          if (isDeclined) statusColor = Colors.redAccent;

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text("₹${p['amount']}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: statusColor.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        status.toUpperCase(), 
                                        style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  p['created_at'].toString().split('T')[0],
                                  style: const TextStyle(color: Colors.white38, fontSize: 11),
                                ),
                                if (isDeclined && p['notes'] != null && p['notes'].toString().isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.redAccent.withValues(alpha: 0.05),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.redAccent.withValues(alpha: 0.15)),
                                    ),
                                    child: Text(
                                      "Remark: ${p['notes']}",
                                      style: const TextStyle(color: Colors.redAccent, fontSize: 11),
                                    ),
                                  ),
                                ],
                                const Divider(color: Colors.white10, height: 16),
                              ],
                            ),
                          );
                        },
                      ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text("Close")),
            ],
          );
        },
      ),
    );
  }

  void _showChangePasswordDialog(BuildContext context, AppState state) {
    final oldPassController = TextEditingController();
    final newPassController = TextEditingController();
    final confirmPassController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text("Change Password"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildEditField("Old Password", oldPassController, obscureText: true),
              _buildEditField("New Password", newPassController, obscureText: true),
              _buildEditField("Confirm New Password", confirmPassController, obscureText: true),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel", style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () async {
              final oldPass = oldPassController.text.trim();
              final newPass = newPassController.text.trim();
              final confirmPass = confirmPassController.text.trim();

              if (oldPass.isEmpty || newPass.isEmpty || confirmPass.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("All fields are required!"), backgroundColor: Colors.redAccent),
                );
                return;
              }

              if (newPass != confirmPass) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("New passwords do not match!"), backgroundColor: Colors.redAccent),
                );
                return;
              }

              if (newPass.length < 6) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("New password must be at least 6 characters long!"), backgroundColor: Colors.redAccent),
                );
                return;
              }

              try {
                await state.changePassword(oldPass, newPass);
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Password changed successfully!"), backgroundColor: Colors.green),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  String errMsg = e.toString().replaceAll('Exception: ', '').replaceAll('Failed to change password:', '').trim();
                  if (errMsg.toLowerCase().contains('incorrect old password')) {
                    errMsg = 'The current password you entered is incorrect. Please try again.';
                  } else if (errMsg.isEmpty) {
                    errMsg = 'Unable to change password. Please verify your connection and try again.';
                  }
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(errMsg), backgroundColor: Colors.redAccent),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.amber,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text("Change"),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return "N/A";
    final months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
    return "${date.day} ${months[date.month - 1]} ${date.year}";
  }

  void _showContactUsDialog(BuildContext context, AppState state) {
    final emailSetting = state.settings.firstWhere(
      (s) => s.key == 'CONTACT_EMAIL', 
      orElse: () => AppSetting(id: 0, key: 'CONTACT_EMAIL', value: 'contact@thebaronclub.com')
    );
    final addressSetting = state.settings.firstWhere(
      (s) => s.key == 'CONTACT_ADDRESS',
      orElse: () => AppSetting(id: 0, key: 'CONTACT_ADDRESS', value: '24/1701, 2nd Floor, KC Arcade, Near CSEZ , Kakkanad,Ernakulam- 682037, Kerala')
    );

    final String contactEmail = emailSetting.value;
    final String contactAddress = addressSetting.value;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          "Contact Us",
          style: GoogleFonts.playfairDisplay(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.amber.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.email_outlined, color: AppColors.amber),
              ),
              title: const Text("Email Support", style: TextStyle(color: Colors.white70, fontSize: 12)),
              subtitle: Text(contactEmail, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
              onTap: () {
                Navigator.pop(context);
                _launchUrl("mailto:$contactEmail");
              },
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.amber.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.location_on_outlined, color: AppColors.amber),
              ),
              title: const Text("Address", style: TextStyle(color: Colors.white70, fontSize: 12)),
              subtitle: Text(contactAddress, style: const TextStyle(color: Colors.white, fontSize: 12, height: 1.4)),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close", style: TextStyle(color: AppColors.amber)),
          ),
        ],
      ),
    );
  }
}


