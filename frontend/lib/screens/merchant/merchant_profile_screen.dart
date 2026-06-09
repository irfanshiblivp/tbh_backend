import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/app_theme.dart';
import '../../providers/app_state.dart';
import '../../models/models.dart';

class MerchantProfileScreen extends StatefulWidget {
  const MerchantProfileScreen({super.key});

  @override
  State<MerchantProfileScreen> createState() => _MerchantProfileScreenState();
}

class _MerchantProfileScreenState extends State<MerchantProfileScreen> {
  late TextEditingController _nameController;
  late TextEditingController _addressController;
  late TextEditingController _descController;
  late TextEditingController _discountController;
  
  @override
  void initState() {
    super.initState();
    final state = Provider.of<AppState>(context, listen: false);
    final merchant = state.merchantProfile;
    _nameController = TextEditingController(text: merchant?.businessName ?? "");
    _addressController = TextEditingController(text: merchant?.address ?? "");
    _descController = TextEditingController(text: merchant?.description ?? "");
    _discountController = TextEditingController(text: merchant?.discountPercent.toString() ?? "50");
    if (state.settings.isEmpty) {
      state.loadSettings();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final merchant = state.merchantProfile;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text("Shop Profile"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.logout, color: Colors.redAccent), onPressed: () => state.logout()),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 10),
            _buildField("Business Name", _nameController, Icons.storefront),
            const SizedBox(height: 16),
            _buildField("Address", _addressController, Icons.location_on_outlined),
            const SizedBox(height: 16),
            _buildField("Discount Percentage (%)", _discountController, Icons.percent, readOnly: true),
            const SizedBox(height: 16),
            _buildField("Description", _descController, Icons.description_outlined, maxLines: 3),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () async {
                await state.updateMerchant(merchant!.id, {
                  'business_name': _nameController.text,
                  'address': _addressController.text,
                  'description': _descController.text,
                });
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Profile updated")));
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.amber,
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text("Save Changes", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 30),
            _buildSupportSection(state),
            const SizedBox(height: 30),
            _buildSecuritySection(state),
          ],
        ),
      ),
    );
  }



  Widget _buildField(String label, TextEditingController controller, IconData icon, {int maxLines = 1, bool readOnly = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white60, fontSize: 12)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          readOnly: readOnly,
          style: TextStyle(color: readOnly ? Colors.white54 : Colors.white),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: Colors.white24, size: 20),
            filled: true,
            fillColor: readOnly ? Colors.white.withValues(alpha: 0.02) : Colors.white.withValues(alpha: 0.05),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
          ),
        ),
      ],
    );
  }

  Widget _buildSecuritySection(AppState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Security Settings", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 20),
        _buildSettingsTile("Change Password", Icons.lock_outline, () => _showChangePasswordDialog(state)),
      ],
    );
  }

  Widget _buildSettingsTile(String title, IconData icon, VoidCallback onTap) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: Colors.white54, size: 20),
      ),
      title: Text(title, style: const TextStyle(fontSize: 14)),
      trailing: const Icon(Icons.chevron_right, color: Colors.white24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      tileColor: Colors.white.withValues(alpha: 0.02),
    );
  }

  void _showChangePasswordDialog(AppState state) {
    final oldPass = TextEditingController();
    final newPass = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text("Change Password"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: oldPass, obscureText: true, decoration: const InputDecoration(labelText: "Old Password")),
            TextField(controller: newPass, obscureText: true, decoration: const InputDecoration(labelText: "New Password")),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              final oldText = oldPass.text.trim();
              final newText = newPass.text.trim();
              if (oldText.isEmpty || newText.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("All fields are required!"), backgroundColor: Colors.redAccent),
                );
                return;
              }
              if (newText.length < 6) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("New password must be at least 6 characters long!"), backgroundColor: Colors.redAccent),
                );
                return;
              }
              try {
                await state.changePassword(oldText, newText);
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Password changed successfully!"), backgroundColor: Colors.green),
                  );
                }
              } catch (e) {
                if (mounted) {
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
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.amber, foregroundColor: Colors.black),
            child: const Text("Change"),
          ),
        ],
      ),
    );
  }

  Widget _buildSupportSection(AppState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Help & Support", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 20),
        _buildSettingsTile("Contact Us", Icons.support_agent_outlined, () => _showContactUsDialog(state)),
      ],
    );
  }

  void _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _showContactUsDialog(AppState state) {
    final emailSetting = state.settings.firstWhere(
      (s) => s.key == 'CONTACT_EMAIL', 
      orElse: () => AppSetting(id: 0, key: 'CONTACT_EMAIL', value: 'info@thebaronclub.com')
    );
    final phoneSetting = state.settings.firstWhere(
      (s) => s.key == 'CONTACT_PHONE', 
      orElse: () => AppSetting(id: 0, key: 'CONTACT_PHONE', value: '+91 99999 99999')
    );
    final addressSetting = state.settings.firstWhere(
      (s) => s.key == 'CONTACT_ADDRESS',
      orElse: () => AppSetting(id: 0, key: 'CONTACT_ADDRESS', value: 'LOREM ELEVATE LLP\nBuilding No.24/1701, Suite No.922, 2nd Floor KC Arcade, Near TV Centre Cochin Special Economic Zone')
    );

    final String contactEmail = emailSetting.value;
    final String contactPhone = phoneSetting.value;
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
                child: const Icon(Icons.phone_outlined, color: AppColors.amber),
              ),
              title: const Text("Call Support", style: TextStyle(color: Colors.white70, fontSize: 12)),
              subtitle: Text(contactPhone, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
              onTap: () {
                Navigator.pop(context);
                _launchUrl("tel:$contactPhone");
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
