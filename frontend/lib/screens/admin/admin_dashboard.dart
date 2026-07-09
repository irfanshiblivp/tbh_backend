import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:intl/intl.dart';
import '../../core/app_theme.dart';
import '../../providers/app_state.dart';
import 'activity_feed.dart';

import '../../models/models.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  List<AppUser> _staffUsers = [];
  bool _loadingStaff = true;

  @override
  void initState() {
    super.initState();
    _loadStaff();
  }

  Future<void> _loadStaff() async {
    final state = Provider.of<AppState>(context, listen: false);
    try {
      final users = await state.getAppUsers();
      if (mounted) {
        setState(() {
          _staffUsers = users.where((u) => u.role == 'staff').toList();
          _loadingStaff = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loadingStaff = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final stats = state.dashboardStats;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 700;
    final isSmall = screenWidth < 450;

    return RefreshIndicator(
      onRefresh: () async {
        await state.refreshData();
        await _loadStaff();
      },
      color: AppColors.amber,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
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
            FadeInUp(
              child: _buildStaffSection(context, state),
            ),
            SizedBox(height: isMobile ? 24 : 40),
            const Text("Recent System Activity", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            FadeInUp(
              child: ActivityFeed(logs: state.adminActivity),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStaffSection(BuildContext context, AppState state) {
    final isMobile = MediaQuery.of(context).size.width < 700;
    if (_loadingStaff) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(child: CircularProgressIndicator(color: AppColors.amber)),
      );
    }

    if (_staffUsers.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.03),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: const Center(
          child: Text(
            "No staff accounts registered yet.",
            style: TextStyle(color: Colors.white30, fontSize: 13),
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Staff Registration Activity", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _staffUsers.length,
            itemBuilder: (context, index) {
              final staff = _staffUsers[index];
              final addedMerchants = state.merchants.where((m) => m.addedBy == staff.id).toList();

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.03),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.05)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: Colors.blue.withOpacity(0.1),
                          child: Text(
                            staff.username.isEmpty ? "S" : staff.username.substring(0, 1).toUpperCase(),
                            style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(staff.username, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              const SizedBox(height: 2),
                              Text(staff.email, style: const TextStyle(color: Colors.white30, fontSize: 12)),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.amber.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.amber.withOpacity(0.2)),
                          ),
                          child: Text(
                            "${addedMerchants.length} Added",
                            style: const TextStyle(color: AppColors.amber, fontWeight: FontWeight.bold, fontSize: 11),
                          ),
                        ),
                      ],
                    ),
                    if (addedMerchants.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      const Text(
                        "Registered Businesses:",
                        style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: addedMerchants.map((m) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.white.withOpacity(0.05)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.storefront, size: 12, color: AppColors.amber2),
                                const SizedBox(width: 6),
                                Text(
                                  m.businessName,
                                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w500),
                                ),
                                if (m.categoryName.isNotEmpty) ...[
                                  const SizedBox(width: 4),
                                  Text(
                                    "(${m.categoryName})",
                                    style: const TextStyle(color: Colors.white30, fontSize: 9),
                                  ),
                                ],
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              );
            },
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text("Broadcast Message", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: target,
                dropdownColor: const Color(0xFF1A1A2E),
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: "Target Audience"),
                items: const [
                  DropdownMenuItem(value: "BOTH", child: Text("All Users")),
                  DropdownMenuItem(value: "CUSTOMER", child: Text("Customers Only")),
                  DropdownMenuItem(value: "MERCHANT", child: Text("Merchants Only")),
                ],
                onChanged: (val) => setDialogState(() => target = val ?? "BOTH"),
              ),
              TextField(
                controller: titleController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: "Title"),
              ),
              TextField(
                controller: messageController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: "Message"),
                maxLines: 3,
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
