import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/app_theme.dart';
import '../../providers/app_state.dart';
import '../../models/models.dart';

class MerchantTransactionsScreen extends StatelessWidget {
  const MerchantTransactionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final transactions = state.transactions;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text("Transaction History"),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: transactions.isEmpty 
        ? _buildEmptyState()
        : RefreshIndicator(
            onRefresh: () => state.refreshData(),
            color: AppColors.amber,
            child: ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: transactions.length,
              itemBuilder: (context, index) {
                final tx = transactions[index];
                return _buildTxCard(tx);
              },
            ),
          ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.03), shape: BoxShape.circle),
            child: const Icon(Icons.receipt_long, color: Colors.white10, size: 64),
          ),
          const SizedBox(height: 16),
          const Text("No transactions found", style: TextStyle(color: Colors.white24, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text("When you redeem vouchers, they will appear here.", style: TextStyle(color: Colors.white10, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildTxCard(Transaction tx) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.receipt_long, color: Colors.white60, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tx.userName ?? "User", style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(DateFormat('MMM d, HH:mm').format(tx.timestamp), style: const TextStyle(color: Colors.white30, fontSize: 11)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text("₹${tx.amountPaid}", style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
              Text("Saved ₹${tx.amountSaved}", style: const TextStyle(color: Colors.white24, fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }
}
