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
import 'merchant_form_screen.dart';

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
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const MerchantFormScreen(),
            ),
          ).then((_) {
            state.refreshData();
          });
        },
        backgroundColor: AppColors.amber,
        icon: const Icon(Icons.add, color: Colors.black),
        label: const Text("Add Merchant", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
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
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.end,
            children: [
              _actionButton("Edit Banners / Info", Icons.edit_outlined, AppColors.amber, () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MerchantFormScreen(merchant: merchant),
                  ),
                ).then((_) {
                  state.refreshData();
                });
              }),
              if (merchant.status != 'active')
                _actionButton("Restore", Icons.restore, Colors.greenAccent, () async {
                  try {
                    await state.restoreMerchant(merchant.id);
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
                  }
                }),
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
