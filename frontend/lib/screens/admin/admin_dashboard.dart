import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:intl/intl.dart';
import '../../core/app_theme.dart';
import '../../providers/app_state.dart';
import 'activity_feed.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final stats = state.dashboardStats;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 700;
    final isSmall = screenWidth < 450;

    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Platform Insights", style: GoogleFonts.dmSans(fontSize: 24, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                    const Text("Real-time performance overview", style: TextStyle(color: Colors.white30, fontSize: 12), overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 14, color: AppColors.amber),
                    const SizedBox(width: 8),
                    Text(DateFormat('MMMM yyyy').format(DateTime.now()), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          FadeInDown(
            delay: const Duration(milliseconds: 100),
            child: _buildSummaryGrid(stats, isMobile, isSmall),
          ),
          SizedBox(height: isMobile ? 24 : 40),
          FadeInDown(
            delay: const Duration(milliseconds: 200),
            child: _buildPlansSummary(context, state),
          ),
          SizedBox(height: isMobile ? 24 : 40),
          const Text("Recent System Activity", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          FadeInUp(
            child: ActivityFeed(logs: state.adminActivity),
          ),
        ],
      ),
    );
  }



  Widget _buildSummaryGrid(Map<String, dynamic>? stats, bool isMobile, bool isSmall) {
    return GridView.count(
      shrinkWrap: true,
      crossAxisCount: isSmall ? 1 : (isMobile ? 2 : 4),
      crossAxisSpacing: isMobile ? 16 : 24,
      mainAxisSpacing: isMobile ? 16 : 24,
      childAspectRatio: isSmall ? 2.5 : (isMobile ? 1.4 : 1.5),
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _buildStatCard("Transactions", "${stats?['total_transactions'] ?? 0}", Icons.receipt_long, Colors.blue, isMobile),
        _buildStatCard("Active Users", "${stats?['total_users'] ?? 0}", Icons.people, Colors.orange, isMobile),
        _buildStatCard("Partners", "${stats?['total_merchants'] ?? 0}", Icons.storefront, Colors.purple, isMobile),
        _buildStatCard("Prime Subscriptions", "${stats?['total_prime_users'] ?? 0}", Icons.stars, AppColors.amber, isMobile),
      ],
    );
  }

  Widget _buildPlansSummary(BuildContext context, AppState state) {
    final primeSettings = state.settings.where((s) => s.key.startsWith('PRIME_PLAN_')).toList();
    final isMobile = MediaQuery.of(context).size.width < 700;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Active Prime Plans", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          if (primeSettings.isEmpty)
            const Text("No plans configured", style: TextStyle(color: Colors.white24))
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: primeSettings.map((plan) {
                  final price = plan.value.split('|')[0];
                  return Container(
                    margin: const EdgeInsets.only(right: 16),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.amber.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.amber.withOpacity(0.2)),
                    ),
                    child: Column(
                      children: [
                        Text(plan.key.replaceAll('PRIME_PLAN_', '').replaceAll('_', ' '), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        Text("₹$price", style: const TextStyle(color: AppColors.amber, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color, bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: EdgeInsets.all(isMobile ? 8 : 12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: isMobile ? 18 : 24),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.dmSans(fontSize: isMobile ? 18 : 24, fontWeight: FontWeight.bold, color: Colors.white),
            overflow: TextOverflow.ellipsis,
          ),
          Flexible(
            child: Text(
              label,
              style: TextStyle(color: Colors.white30, fontSize: isMobile ? 10 : 12, fontWeight: FontWeight.w500),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  void _showNotificationDialog(BuildContext context, AppState state) {
    final titleController = TextEditingController();
    final messageController = TextEditingController();
    String target = "BOTH";

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF1A1A2E),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Text("Create Announcement"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButton<String>(
                value: target,
                dropdownColor: const Color(0xFF1A1A2E),
                isExpanded: true,
                style: const TextStyle(color: Colors.white),
                items: const [
                  DropdownMenuItem(value: "BOTH", child: Text("All Users")),
                  DropdownMenuItem(value: "CUSTOMER", child: Text("Customers Only")),
                  DropdownMenuItem(value: "MERCHANT", child: Text("Merchants Only")),
                ],
                onChanged: (val) => setDialogState(() => target = val!),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: titleController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: "Title", labelStyle: TextStyle(color: Colors.white60)),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: messageController,
                maxLines: 3,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: "Message", labelStyle: TextStyle(color: Colors.white60)),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
            ElevatedButton(
              onPressed: () async {
                try {
                  await state.sendNotification(target, titleController.text, messageController.text);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Announcement sent successfully!")));
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
                }
              },
              child: const Text("Send Now"),
            ),
          ],
        ),
      ),
    );
  }
}


