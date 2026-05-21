import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_theme.dart';
import '../../providers/app_state.dart';
import '../../models/models.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'map_picker_screen.dart';

class MerchantManagementScreen extends StatefulWidget {
  const MerchantManagementScreen({super.key});

  @override
  State<MerchantManagementScreen> createState() => _MerchantManagementScreenState();
}

class _MerchantManagementScreenState extends State<MerchantManagementScreen> {

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AppState>(context, listen: false).refreshData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          _buildToolbar(),
          Expanded(
            child: state.isLoading 
              ? const Center(child: CircularProgressIndicator(color: AppColors.amber))
              : ListView.builder(
                  padding: const EdgeInsets.all(24),
                  itemCount: state.merchants.length,
                  itemBuilder: (context, index) {
                    final merchant = state.merchants[index];
                    return _buildMerchantTile(merchant, state);
                  },
                ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddMerchantDialog(context, state),
        backgroundColor: AppColors.amber,
        icon: const Icon(Icons.add, color: Colors.black),
        label: const Text("Add Merchant", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
      ),
    );
  }

  void _showAddMerchantDialog(BuildContext context, AppState state) {
    final businessNameController = TextEditingController();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    final phoneController = TextEditingController();
    final addressController = TextEditingController();
    final descriptionController = TextEditingController();
    final discountController = TextEditingController(text: "50");
    final latController = TextEditingController();
    final lngController = TextEditingController();
    
    String status = "active";
    bool showPassword = false;
    String? selectedCategory = state.categories.isNotEmpty ? state.categories.first.name : null;
    XFile? pickedImage;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF1A1A2E),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Text("Add New Merchant"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _dialogField(businessNameController, "Business Name (Merchant Name)"),
                _dialogField(emailController, "Login Email"),
                _dialogField(passwordController, "Login Password", 
                  isObscured: !showPassword, 
                  onToggle: () => setDialogState(() => showPassword = !showPassword)
                ),
                _dialogField(phoneController, "Phone Number", isNumber: true),
                
                // Category Dropdown
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: DropdownButtonFormField<String>(
                    value: selectedCategory,
                    dropdownColor: const Color(0xFF1A1A2E),
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: "Category",
                      labelStyle: const TextStyle(color: Colors.white60),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.05),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                    items: state.categories.map((c) => DropdownMenuItem(value: c.name, child: Text(c.name))).toList(),
                    onChanged: (val) => setDialogState(() => selectedCategory = val),
                  ),
                ),

                // Image Picker
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: InkWell(
                    onTap: () async {
                      final picker = ImagePicker();
                      final image = await picker.pickImage(source: ImageSource.gallery);
                      if (image != null) {
                        setDialogState(() => pickedImage = image);
                      }
                    },
                    child: Container(
                      height: 100,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white.withOpacity(0.1)),
                      ),
                      child: pickedImage != null 
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: kIsWeb 
                              ? Image.network(pickedImage!.path, fit: BoxFit.cover)
                              : Image.file(File(pickedImage!.path), fit: BoxFit.cover),
                          )
                        : const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_a_photo, color: Colors.white30),
                              SizedBox(height: 4),
                              Text("Upload Card Image", style: TextStyle(color: Colors.white30, fontSize: 12)),
                            ],
                          ),
                    ),
                  ),
                ),

                // Status Dropdown
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: DropdownButtonFormField<String>(
                    value: status,
                    dropdownColor: const Color(0xFF1A1A2E),
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: "Status",
                      labelStyle: const TextStyle(color: Colors.white60),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.05),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                    items: const [
                      DropdownMenuItem(value: "active", child: Text("Active")),
                      DropdownMenuItem(value: "inactive", child: Text("Inactive")),
                    ],
                    onChanged: (val) => setDialogState(() => status = val!),
                  ),
                ),

                _dialogField(discountController, "Discount %", isNumber: true),
                _dialogField(addressController, "Full Address"),
                _dialogField(descriptionController, "Description", maxLines: 3),
                
                Row(
                  children: [
                    Expanded(child: _dialogField(latController, "Latitude", isNumber: true)),
                    const SizedBox(width: 12),
                    Expanded(child: _dialogField(lngController, "Longitude", isNumber: true)),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      double? initialLat = double.tryParse(latController.text.trim());
                      double? initialLng = double.tryParse(lngController.text.trim());
                      LatLng? initialLatLng;
                      if (initialLat != null && initialLng != null) {
                        initialLatLng = LatLng(initialLat, initialLng);
                      }
                      
                      final LatLng? pickedLatLng = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => MapPickerScreen(initialLocation: initialLatLng),
                        ),
                      );
                      
                      if (pickedLatLng != null) {
                        setDialogState(() {
                          latController.text = pickedLatLng.latitude.toStringAsFixed(6);
                          lngController.text = pickedLatLng.longitude.toStringAsFixed(6);
                        });
                      }
                    },
                    icon: const Icon(Icons.map_outlined, color: AppColors.amber),
                    label: const Text("PICK LOCATION ON MAP", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1)),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: AppColors.amber.withOpacity(0.3)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
            ElevatedButton(
              onPressed: () async {
                FocusScope.of(context).unfocus(); // Force sync controllers on Web/Mobile
                
                if (businessNameController.text.trim().isEmpty || emailController.text.trim().isEmpty || 
                    passwordController.text.trim().isEmpty || phoneController.text.trim().isEmpty ||
                    addressController.text.trim().isEmpty || discountController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Name, Email, Password, Phone, Address and Discount are mandatory!")));
                  return;
                }
                try {
                  http.MultipartFile? imageFile;
                  if (pickedImage != null) {
                    final bytes = await pickedImage!.readAsBytes();
                    imageFile = http.MultipartFile.fromBytes(
                      'card_image',
                      bytes,
                      filename: 'card_image.jpg',
                      contentType: MediaType('image', 'jpeg'),
                    );
                  }

                  final postData = {
                    'business_name': businessNameController.text.trim(),
                    'email': emailController.text.trim(),
                    'password': passwordController.text.trim(),
                    'phone': phoneController.text.trim(),
                    'category': selectedCategory,
                    'address': addressController.text.trim(),
                    'description': descriptionController.text.trim(),
                    'status': status,
                    'discount_percent': int.tryParse(discountController.text.trim()) ?? 50,
                    'latitude': double.tryParse(latController.text.trim()),
                    'longitude': double.tryParse(lngController.text.trim()),
                  };
                  debugPrint("Sending merchant data: $postData");
                  await state.adminCreateMerchant(postData, imageFile: imageFile);
                  
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Merchant added successfully!")));
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
                }
              },
              child: const Text("Create"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dialogField(TextEditingController ctrl, String label, {bool obscure = false, bool isNumber = false, int maxLines = 1, VoidCallback? onToggle, bool? isObscured}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: ctrl,
        obscureText: isObscured ?? obscure,
        maxLines: maxLines,
        keyboardType: isNumber 
          ? (label.contains("Phone") ? TextInputType.phone : const TextInputType.numberWithOptions(decimal: true)) 
          : TextInputType.text,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white60),
          filled: true,
          fillColor: Colors.white.withOpacity(0.05),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          suffixIcon: onToggle != null ? IconButton(
            icon: Icon(isObscured! ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: Colors.white38, size: 20),
            onPressed: onToggle,
          ) : null,
        ),
      ),
    );
  }

  Widget _buildToolbar() {
    return const Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Text("Merchant Directory", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildMerchantTile(Merchant merchant, AppState state) {
    bool isActive = merchant.status == 'active';
    Color statusColor = isActive ? Colors.green : Colors.orange;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 48,
                  height: 48,
                  color: AppColors.amber.withOpacity(0.1),
                  child: (merchant.logo.isNotEmpty || merchant.cardImage.isNotEmpty)
                    ? Image.network(
                        merchant.logo.isNotEmpty ? merchant.logo : merchant.cardImage,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(Icons.store, color: AppColors.amber),
                      )
                    : const Icon(Icons.store, color: AppColors.amber),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(merchant.businessName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Text(merchant.address, style: const TextStyle(color: Colors.white30, fontSize: 12)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: statusColor.withOpacity(0.2)),
                ),
                child: Text(
                  merchant.status.toUpperCase(), 
                  style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold)
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (merchant.status != 'active')
                _actionButton("Restore", Icons.restore, Colors.greenAccent, () async {
                  try {
                    await state.restoreMerchant(merchant.id);
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
                  }
                }),
              if (merchant.status != 'active')
                const SizedBox(width: 8),
              _actionButton("Delete", Icons.delete_outline, Colors.redAccent, () async {
                try {
                  await state.deleteMerchant(merchant.id);
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
                }
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _actionButton(String label, IconData icon, Color color, VoidCallback onPressed) {
    return InkWell(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
