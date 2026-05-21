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

class ProfileScreen extends StatelessWidget {
  // Profile screen display
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final profile = state.profile;

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
                    AppColors.amber.withOpacity(0.12),
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
                      border: Border.all(color: AppColors.amber.withOpacity(0.3), width: 2),
                      boxShadow: [
                        BoxShadow(color: AppColors.amber.withOpacity(0.15), blurRadius: 40, spreadRadius: 5),
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
                  if (profile?.isPrime == true) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFFD4AF37), // Metallic gold
                            Color(0xFFFFDF73), // Light gold
                            Color(0xFFAA7C11), // Dark gold
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFD4AF37).withOpacity(0.3),
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
                      "Validity: ${_formatDate(profile?.primeStartsAt)} - ${_formatDate(profile?.primeExpiresAt)}",
                      style: GoogleFonts.jost(
                        color: const Color(0xFFD4AF37).withOpacity(0.85),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                  const SizedBox(height: 32),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    decoration: BoxDecoration(
                      color: AppColors.ink2,
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: AppColors.line),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 20),
                      ],
                    ),
                    child: Row(
                      children: [
                        _buildStatItem("₹${profile?.referralBalance.toStringAsFixed(0) ?? "0"}", "BALANCE"),
                        Container(width: 1, height: 40, color: AppColors.line),
                        _buildStatItem("₹${profile?.referralTotalEarned.toStringAsFixed(0) ?? "0"}", "EARNINGS"),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Referral Section
                  InkWell(
                    onTap: () {
                      final code = profile?.referralCode ?? "TBH000";
                      final text = "Join The Baron Club and save 1-100% at the finest merchants! Use my referral code: $code\nDownload the app now!";
                      if (kIsWeb) {
                        Clipboard.setData(ClipboardData(text: text));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Referral message copied to clipboard!"), backgroundColor: AppColors.amber),
                        );
                      } else {
                        Share.share(text);
                      }
                    },
                    borderRadius: BorderRadius.circular(18),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.amber.withOpacity(0.09),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AppColors.amber.withOpacity(0.22)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(
                              color: const Color(0xFF1A1A2E),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppColors.amber.withOpacity(0.22)),
                            ),
                            child: const Icon(Icons.share_outlined, color: AppColors.amber),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text("Referral Program", style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                                Text("Your Code: ${profile?.referralCode ?? "TBH000"}", style: const TextStyle(color: AppColors.text2, fontSize: 11)),
                              ],
                            ),
                          ),
                          const Icon(Icons.copy, color: AppColors.amber, size: 16),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 14),
                  
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

  Widget _buildStatItem(String val, String label) {
    return Expanded(
      child: Column(
        children: [
          Text(val, style: GoogleFonts.dmMono(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(label.toUpperCase(), style: const TextStyle(color: Colors.white30, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
        ],
      ),
    );
  }

  Widget _buildMenuCard(List<Widget> items) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.045),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.09)),
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
          border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.06))),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isDanger ? Colors.red.withOpacity(0.08) : Colors.white.withOpacity(0.07),
                borderRadius: BorderRadius.circular(11),
                border: Border.all(color: isDanger ? Colors.red.withOpacity(0.14) : Colors.white.withOpacity(0.09)),
              ),
              child: Icon(icon, size: 18, color: isDanger ? Colors.redAccent : Colors.white54),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label, style: TextStyle(color: isDanger ? Colors.redAccent : Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
            ),
            Icon(Icons.chevron_right, size: 18, color: Colors.white.withOpacity(0.2)),
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
              fillColor: Colors.white.withOpacity(0.05),
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
              await state.updateProfile({
                'name': nameController.text,
                'phone': phoneController.text,
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
                                        color: statusColor.withOpacity(0.1),
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
                                      color: Colors.redAccent.withOpacity(0.05),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.redAccent.withOpacity(0.15)),
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
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Error: $e"), backgroundColor: Colors.redAccent),
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
}


