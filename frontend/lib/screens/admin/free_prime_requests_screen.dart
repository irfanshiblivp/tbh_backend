import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/app_theme.dart';
import '../../providers/app_state.dart';

class FreePrimeRequestsScreen extends StatefulWidget {
  const FreePrimeRequestsScreen({super.key});

  @override
  State<FreePrimeRequestsScreen> createState() => _FreePrimeRequestsScreenState();
}

class _FreePrimeRequestsScreenState extends State<FreePrimeRequestsScreen> {
  bool _isLoading = true;
  List<dynamic> _requests = [];

  @override
  void initState() {
    super.initState();
    _fetchRequests();
  }

  Future<void> _fetchRequests() async {
    final state = Provider.of<AppState>(context, listen: false);
    try {
      final data = await state.getFreePrimeRequests();
      setState(() {
        _requests = data;
        _isLoading = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Free Prime Requests",
              style: GoogleFonts.dmSans(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              "Manage premium access requests from customers who successfully referred 10+ members.",
              style: TextStyle(color: Colors.white30, fontSize: 14),
            ),
            const SizedBox(height: 32),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.amber))
                  : _requests.isEmpty
                      ? const Center(
                          child: Text(
                            "No premium requests found",
                            style: TextStyle(color: Colors.white30),
                          ),
                        )
                      : ListView.builder(
                          itemCount: _requests.length,
                          itemBuilder: (context, index) => _buildRequestCard(_requests[index]),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRequestCard(dynamic request) {
    final user = request['user_details'] ?? {};
    final status = request['status']?.toString() ?? 'pending';
    final int requestId = request['id'];
    final int referralCount = request['referred_membership_count'] ?? 0;
    
    final bool isPending = status == 'pending';
    final bool isApproved = status == 'approved';
    final bool isDeclined = status == 'declined';
    
    Color statusColor = AppColors.amber;
    if (isApproved) statusColor = Colors.green;
    if (isDeclined) statusColor = Colors.redAccent;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: statusColor.withValues(alpha: 0.2)),
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
                  Row(
                    children: [
                      Text(
                        user['name'] ?? "Unknown User",
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                      if (user['customer_number'] != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.amber.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            "ID: ${user['customer_id'] ?? 'TBC${user['customer_number']}'}",
                            style: const TextStyle(color: AppColors.amber, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ],
                  ),
                  Text(user['email'] ?? "", style: const TextStyle(color: Colors.white30, fontSize: 12)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
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
                  const Text(
                    "REFERRED PRIME MEMBERS",
                    style: TextStyle(color: Colors.white30, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "$referralCount / 10",
                    style: GoogleFonts.dmMono(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ],
              ),
              if (isPending)
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => _showProcessDialog(request),
                      icon: const Icon(Icons.payment, size: 16),
                      label: const Text("View Details & Pay"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.amber,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                )
              else
                Text(
                  isApproved ? "Membership Granted" : "Request Declined",
                  style: TextStyle(
                    color: isApproved ? Colors.green : Colors.redAccent,
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  void _showProcessDialog(dynamic request) {
    final user = request['user_details'] ?? {};
    final int requestId = request['id'];

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text("Process Premium Request"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "CUSTOMER BANK DETAILS",
                style: TextStyle(color: AppColors.amber, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5),
              ),
              const SizedBox(height: 10),
              _buildDetailRow("A/C Holder", user['bank_account_holder_name'] ?? "N/A"),
              _buildDetailRow("Bank Name", user['bank_name'] ?? "N/A"),
              _buildDetailRow("Account No", user['bank_account_number'] ?? "N/A"),
              _buildDetailRow("IFSC Code", user['bank_ifsc'] ?? "N/A"),
              _buildDetailRow("UPI ID", user['bank_upi_id'] ?? "N/A"),
              
              const SizedBox(height: 20),
              const Text(
                "If there is any cash bonus reward or administrative payment associated with this referral milestone, you can pay their money manually and then grant them premium membership below.",
                style: TextStyle(color: Colors.white30, fontSize: 11, fontStyle: FontStyle.italic, height: 1.4),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text("Cancel", style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext); // Close dialog
              _declineRequest(requestId);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            child: const Text("Decline"),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext); // Close dialog
              _approveRequest(requestId);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
            child: const Text("Approve & Grant Prime"),
          ),
        ],
      ),
    );
  }

  Future<void> _approveRequest(int id) async {
    final state = Provider.of<AppState>(context, listen: false);
    try {
      await state.approveFreePrimeRequest(id);
      _fetchRequests();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Request approved and 365 days of Prime membership granted!"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  Future<void> _declineRequest(int id) async {
    final state = Provider.of<AppState>(context, listen: false);
    try {
      await state.declineFreePrimeRequest(id);
      _fetchRequests();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Request declined successfully."),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(label, style: const TextStyle(color: Colors.white30, fontSize: 12)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(value, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
