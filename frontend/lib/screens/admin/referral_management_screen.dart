import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/app_theme.dart';
import '../../providers/app_state.dart';

class ReferralManagementScreen extends StatefulWidget {
  const ReferralManagementScreen({super.key});

  @override
  State<ReferralManagementScreen> createState() => _ReferralManagementScreenState();
}

class _ReferralManagementScreenState extends State<ReferralManagementScreen> {
  bool _isLoading = true;
  List<dynamic> _payouts = [];

  @override
  void initState() {
    super.initState();
    _fetchPayouts();
  }

  Future<void> _fetchPayouts() async {
    final state = Provider.of<AppState>(context, listen: false);
    try {
      final data = await state.getPayoutHistory();
      setState(() {
        _payouts = data;
        _isLoading = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Referral Payouts", style: GoogleFonts.dmSans(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text("Manage withdrawal requests and customer bonus payments.", style: TextStyle(color: Colors.white30, fontSize: 14)),
            const SizedBox(height: 32),
            Expanded(
              child: _isLoading 
                ? const Center(child: CircularProgressIndicator(color: AppColors.amber))
                : _payouts.isEmpty 
                  ? const Center(child: Text("No payout requests found", style: TextStyle(color: Colors.white30)))
                  : ListView.builder(
                      itemCount: _payouts.length,
                      itemBuilder: (context, index) => _buildPayoutCard(_payouts[index]),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPayoutCard(dynamic payout) {
    final user = payout['user_details'];
    final status = payout['status']?.toString() ?? 'pending';
    final bool isCompleted = status == 'completed';
    final bool isDeclined = status == 'declined';
    
    Color statusColor = AppColors.amber;
    if (isCompleted) statusColor = Colors.green;
    if (isDeclined) statusColor = Colors.redAccent;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: statusColor.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(user['name'] ?? "Unknown User", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  Text(user['email'] ?? "", style: const TextStyle(color: Colors.white30, fontSize: 12)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const Divider(height: 32, color: Colors.white10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("WITHDRAWAL AMOUNT", style: TextStyle(color: Colors.white30, fontSize: 10, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text("₹${payout['amount']}", style: GoogleFonts.dmMono(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                ],
              ),
              if (status == 'pending')
                ElevatedButton(
                  onPressed: () => _showAccountDetails(context, payout),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.amber,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text("Process Payment"),
                )
              else if (isDeclined && payout['notes'] != null && payout['notes'].toString().isNotEmpty)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 20),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.redAccent.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.redAccent.withOpacity(0.15)),
                      ),
                      child: Text(
                        "Remark: ${payout['notes']}",
                        style: const TextStyle(color: Colors.redAccent, fontSize: 11),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  void _showAccountDetails(BuildContext context, dynamic payout) {
    final user = payout['user_details'];
    final int payoutId = payout['id'];
    final List<dynamic> referredUsers = payout['referred_users'] ?? [];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text("Process Withdrawal Request"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("CUSTOMER BANK DETAILS", style: TextStyle(color: AppColors.amber, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
              const SizedBox(height: 10),
              _buildDetailRow("A/C Holder", user['bank_account_holder_name'] ?? "N/A"),
              _buildDetailRow("Bank Name", user['bank_name'] ?? "N/A"),
              _buildDetailRow("Account No", user['bank_account_number'] ?? "N/A"),
              _buildDetailRow("IFSC Code", user['bank_ifsc'] ?? "N/A"),
              _buildDetailRow("UPI ID", user['bank_upi_id'] ?? "N/A"),
              
              const SizedBox(height: 20),
              const Divider(color: Colors.white10),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("REFERRED PERSONS", style: TextStyle(color: AppColors.amber, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: AppColors.amber.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                    child: Text("${referredUsers.length}", style: const TextStyle(color: AppColors.amber, fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              referredUsers.isEmpty
                  ? const Text("No referred persons found.", style: TextStyle(color: Colors.white38, fontSize: 12, fontStyle: FontStyle.italic))
                  : Container(
                      height: 120,
                      decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(10)),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: referredUsers.length,
                        itemBuilder: (context, idx) {
                          final ru = referredUsers[idx];
                          final isPrime = ru['is_prime'] == true;
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            decoration: BoxDecoration(
                              border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.03))),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(ru['name'] ?? 'Unnamed', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                                      Text(ru['email'] ?? '', style: const TextStyle(fontSize: 10, color: Colors.white30)),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: (isPrime ? Colors.green : Colors.white10).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(isPrime ? "PRIME" : "FREE", 
                                    style: TextStyle(color: isPrime ? Colors.green : Colors.white38, fontSize: 8, fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
              
              const SizedBox(height: 20),
              const Text("Please transfer the amount manually if completed, or choose to decline the request.", 
                style: TextStyle(color: Colors.white30, fontSize: 11, fontStyle: FontStyle.italic)),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close", style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close details dialog
              _showDeclineDialog(context, payoutId);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            child: const Text("Decline request"),
          ),
          ElevatedButton(
            onPressed: () async {
              final state = Provider.of<AppState>(context, listen: false);
              try {
                await state.markPayoutCompleted(payoutId);
                if (context.mounted) Navigator.pop(context);
                _fetchPayouts();
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Payment marked as completed!")));
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
            child: const Text("Complete Payout"),
          ),
        ],
      ),
    );
  }

  void _showDeclineDialog(BuildContext context, int payoutId) {
    final remarkController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text("Decline Withdrawal"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Please enter a remark explaining why this withdrawal is being declined. This will be shown to the customer.", 
              style: TextStyle(color: Colors.white70, fontSize: 13)),
            const SizedBox(height: 16),
            TextField(
              controller: remarkController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: "Remark",
                labelStyle: const TextStyle(color: Colors.white60),
                hintText: "e.g., Invalid referral activity / Incorrect bank details",
                filled: true,
                fillColor: Colors.white.withOpacity(0.05),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              final state = Provider.of<AppState>(context, listen: false);
              try {
                await state.declinePayout(payoutId, remarkController.text);
                if (context.mounted) {
                  Navigator.pop(context); // Pop decline dialog
                }
                _fetchPayouts();
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Withdrawal request declined successfully!")));
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text("Decline & Refund"),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 80, child: Text(label, style: const TextStyle(color: Colors.white30, fontSize: 12))),
          const SizedBox(width: 12),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white))),
        ],
      ),
    );
  }
}
