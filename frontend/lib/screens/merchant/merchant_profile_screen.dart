import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_theme.dart';
import '../../providers/app_state.dart';
import '../../models/models.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

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
    final merchant = Provider.of<AppState>(context, listen: false).merchantProfile;
    _nameController = TextEditingController(text: merchant?.businessName ?? "");
    _addressController = TextEditingController(text: merchant?.address ?? "");
    _descController = TextEditingController(text: merchant?.description ?? "");
    _discountController = TextEditingController(text: merchant?.discountPercent.toString() ?? "50");
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
            _buildImageSections(merchant),
            const SizedBox(height: 30),
            _buildField("Business Name", _nameController, Icons.storefront),
            const SizedBox(height: 16),
            _buildField("Address", _addressController, Icons.location_on_outlined),
            const SizedBox(height: 16),
            _buildField("Discount Percentage (%)", _discountController, Icons.percent),
            const SizedBox(height: 16),
            _buildField("Description", _descController, Icons.description_outlined, maxLines: 3),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () async {
                await state.updateMerchant(merchant!.id, {
                  'business_name': _nameController.text,
                  'address': _addressController.text,
                  'description': _descController.text,
                  'discount_percent': int.parse(_discountController.text),
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
            const SizedBox(height: 40),
            _buildSecuritySection(state),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSections(Merchant? merchant) {
    return Column(
      children: [
        const Text("Identity & Branding", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
        const SizedBox(height: 20),
        _buildPhotoPicker(
          label: "Cover Card",
          imageUrl: merchant?.cardImage,
          isWide: true,
          onPick: (img) async {
            final bytes = await img.readAsBytes();
            final multipartFile = http.MultipartFile.fromBytes(
              'card_image',
              bytes,
              filename: img.name,
            );
            final state = Provider.of<AppState>(context, listen: false);
            await state.updateMerchant(merchant!.id, {}, imageFile: multipartFile);
          }
        ),
      ],
    );
  }

  Widget _buildPhotoPicker({required String label, String? imageUrl, required Function(XFile) onPick, bool isWide = false}) {
    return Column(
      children: [
        Stack(
          children: [
            Container(
              height: 100,
              width: isWide ? 160 : 100,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(20),
                image: imageUrl != null && imageUrl.isNotEmpty
                  ? DecorationImage(image: NetworkImage(imageUrl), fit: BoxFit.cover)
                  : null,
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: imageUrl == null || imageUrl.isEmpty
                ? Icon(isWide ? Icons.image_outlined : Icons.store, size: 32, color: Colors.white10)
                : null,
            ),
            Positioned(
              bottom: -5,
              right: -5,
              child: InkWell(
                onTap: () async {
                  final picker = ImagePicker();
                  final img = await picker.pickImage(source: ImageSource.gallery);
                  if (img != null) {
                    try {
                      await onPick(img);
                      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("$label updated!")));
                    } catch (e) {
                      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
                    }
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(color: AppColors.amber, shape: BoxShape.circle),
                  child: const Icon(Icons.edit, size: 14, color: Colors.black),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildField(String label, TextEditingController controller, IconData icon, {int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white60, fontSize: 12)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: Colors.white24, size: 20),
            filled: true,
            fillColor: Colors.white.withOpacity(0.05),
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
        decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: Colors.white54, size: 20),
      ),
      title: Text(title, style: const TextStyle(fontSize: 14)),
      trailing: const Icon(Icons.chevron_right, color: Colors.white24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      tileColor: Colors.white.withOpacity(0.02),
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
              try {
                await state.changePassword(oldPass.text, newPass.text);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Password changed")));
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
              }
            },
            child: const Text("Change"),
          ),
        ],
      ),
    );
  }
}
