import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import '../../core/app_theme.dart';
import '../../providers/app_state.dart';
import '../../models/models.dart';
import '../../services/api_service.dart';

class StaffPerformanceScreen extends StatefulWidget {
  const StaffPerformanceScreen({super.key});

  @override
  State<StaffPerformanceScreen> createState() => _StaffPerformanceScreenState();
}

class _StaffPerformanceScreenState extends State<StaffPerformanceScreen> {
  List<AppUser> _staffUsers = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadStaffData();
  }

  Future<void> _loadStaffData() async {
    final state = Provider.of<AppState>(context, listen: false);
    try {
      final users = await state.getAppUsers();
      if (mounted) {
        setState(() {
          _staffUsers = users.where((u) => u.role == 'staff').toList();
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: RefreshIndicator(
        onRefresh: () async {
          await state.refreshData();
          await _loadStaffData();
        },
        color: AppColors.amber,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Staff Business Tracker",
                          style: GoogleFonts.dmSans(fontSize: 24, fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const Text(
                          "Monitor staff performance & approve registered merchants",
                          style: TextStyle(color: Colors.white30, fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.amber))
                  : _staffUsers.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          itemCount: _staffUsers.length,
                          itemBuilder: (context, index) {
                            final staff = _staffUsers[index];
                            return FadeInUp(
                              delay: Duration(milliseconds: index * 100),
                              child: _buildStaffCard(context, staff, state),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, size: 64, color: Colors.white.withOpacity(0.1)),
          const SizedBox(height: 16),
          const Text(
            "No staff accounts registered yet.",
            style: TextStyle(color: Colors.white30, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildStaffCard(BuildContext context, AppUser staff, AppState state) {
    final addedMerchants = state.merchants.where((m) => m.addedBy == staff.id).toList();

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Staff Profile Row
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: Colors.blue.withOpacity(0.1),
                child: Text(
                  staff.username.isEmpty ? "S" : staff.username.substring(0, 1).toUpperCase(),
                  style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(staff.username, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 2),
                    Text(staff.email, style: const TextStyle(color: Colors.white30, fontSize: 12)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.amber.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.amber.withOpacity(0.2)),
                ),
                child: Text(
                  "${addedMerchants.length} Registered",
                  style: const TextStyle(color: AppColors.amber, fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
            ],
          ),
          
          if (addedMerchants.isNotEmpty) ...[
            const SizedBox(height: 20),
            const Divider(color: Colors.white10),
            const SizedBox(height: 12),
            Text(
              "REGISTERED BUSINESSES",
              style: GoogleFonts.jost(color: Colors.white30, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5),
            ),
            const SizedBox(height: 12),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: addedMerchants.length,
              itemBuilder: (context, idx) {
                final merchant = addedMerchants[idx];
                return _buildMerchantApprovalRow(context, merchant, state);
              },
            ),
          ] else ...[
            const SizedBox(height: 20),
            const Divider(color: Colors.white10),
            const SizedBox(height: 12),
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  "No businesses registered by this staff member.",
                  style: TextStyle(color: Colors.white24, fontSize: 12, fontStyle: FontStyle.italic),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMerchantApprovalRow(BuildContext context, Merchant merchant, AppState state) {
    bool isPending = merchant.status == 'pending' || merchant.status == 'inactive';
    bool isActive = merchant.status == 'active';
    Color statusColor = isActive ? Colors.green : (merchant.status == 'rejected' ? Colors.redAccent : Colors.orangeAccent);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.02),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.03)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: 36,
                  height: 36,
                  color: AppColors.amber.withOpacity(0.1),
                  child: merchant.logo.isNotEmpty
                      ? Image.network(
                          merchant.logo,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(Icons.storefront, color: AppColors.amber, size: 18),
                        )
                      : const Icon(Icons.storefront, color: AppColors.amber, size: 18),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      merchant.businessName,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    if (merchant.categoryName.isNotEmpty)
                      Text(
                        merchant.categoryName.toUpperCase(),
                        style: const TextStyle(color: Colors.white30, fontSize: 10),
                      ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: statusColor.withOpacity(0.2)),
                ),
                child: Text(
                  merchant.status.toUpperCase(),
                  style: TextStyle(color: statusColor, fontSize: 9, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          
          // Approve & Reject Buttons
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (isPending || merchant.status == 'rejected') ...[
                ElevatedButton.icon(
                  onPressed: () async {
                    try {
                      await state.approveMerchant(merchant.id);
                      _loadStaffData();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("${merchant.businessName} approved successfully!")),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ApiService.parseError(e).message), backgroundColor: Colors.redAccent));
                      }
                    }
                  },
                  icon: const Icon(Icons.check_circle_outline, size: 14),
                  label: const Text("Approve", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    minimumSize: Size.zero,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              if (isActive || isPending) ...[
                OutlinedButton.icon(
                  onPressed: () async {
                    try {
                      await state.rejectMerchant(merchant.id);
                      _loadStaffData();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("${merchant.businessName} rejected.")),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ApiService.parseError(e).message), backgroundColor: Colors.redAccent));
                      }
                    }
                  },
                  icon: const Icon(Icons.cancel_outlined, size: 14),
                  label: const Text("Reject", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.redAccent,
                    side: const BorderSide(color: Colors.redAccent),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    minimumSize: Size.zero,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
