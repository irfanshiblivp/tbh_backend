import 'package:flutter/material.dart';
import '../../core/app_theme.dart';
import '../../models/models.dart';
import 'package:google_fonts/google_fonts.dart';

class MerchantDetailScreen extends StatelessWidget {
  final Merchant merchant;
  const MerchantDetailScreen({super.key, required this.merchant});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(merchant.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProfileHeader(),
            const SizedBox(height: 30),
            _buildStatsGrid(),
            const SizedBox(height: 30),
            _buildSectionTitle("Business Documents"),
            _buildDocumentList(),
            const SizedBox(height: 30),
            _buildSectionTitle("Active Offers"),
            _buildOffersList(),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: AppColors.amber.withOpacity(0.1),
            child: const Icon(Icons.store, color: AppColors.amber, size: 40),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(merchant.name, style: GoogleFonts.dmSans(fontSize: 24, fontWeight: FontWeight.bold)),
                Text(merchant.categoryName, style: const TextStyle(color: AppColors.amber)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 14, color: Colors.white30),
                    const SizedBox(width: 4),
                    Text("${merchant.city}, ${merchant.state}", style: const TextStyle(color: Colors.white30)),
                  ],
                ),
              ],
            ),
          ),
          _buildStatusBadge(),
        ],
      ),
    );
  }

  Widget _buildStatusBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.withOpacity(0.2)),
      ),
      child: const Text(
        "VERIFIED",
        style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12),
      ),
    );
  }

  Widget _buildStatsGrid() {
    return GridView.count(
      shrinkWrap: true,
      crossAxisCount: 3,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 2,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _buildDetailStat("Total Revenue", "₹45,230", Icons.payments_outlined),
        _buildDetailStat("Transactions", "124", Icons.receipt_outlined),
        _buildDetailStat("Prime Customers", "56", Icons.star_outline),
      ],
    );
  }

  Widget _buildDetailStat(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white24, size: 20),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          Text(label, style: const TextStyle(color: Colors.white30, fontSize: 10)),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildDocumentList() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _buildDocItem("GST Certificate", "Verified", true),
          const Divider(color: Colors.white10),
          _buildDocItem("ID Proof", "Verified", true),
          const Divider(color: Colors.white10),
          _buildDocItem("Shop License", "Pending", false),
        ],
      ),
    );
  }

  Widget _buildDocItem(String title, String status, bool verified) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.description_outlined, color: Colors.white24),
      title: Text(title, style: const TextStyle(fontSize: 14)),
      trailing: Text(status, style: TextStyle(color: verified ? Colors.green : Colors.orange, fontSize: 12)),
    );
  }

  Widget _buildOffersList() {
    return const Center(child: Text("No active offers found", style: TextStyle(color: Colors.white24)));
  }
}
