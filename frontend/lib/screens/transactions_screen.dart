import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../core/app_theme.dart';
import '../providers/app_state.dart';
import '../models/models.dart';

class TransactionsScreen extends StatelessWidget {
  const TransactionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text("Transactions", style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 22)),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 20),
              child: Text("${state.transactions.length} RECORDS", style: const TextStyle(color: AppColors.amber, fontSize: 10, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
      body: state.transactions.isEmpty
          ? _buildEmptyState()
          : RefreshIndicator(
              onRefresh: state.refreshData,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                itemCount: state.transactions.length,
                itemBuilder: (context, index) {
                  return _buildTransactionItem(state.transactions[index]);
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
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.04),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
            ),
            child: const Icon(Icons.history, size: 36, color: Colors.white12),
          ),
          const SizedBox(height: 16),
          const Text("No transactions yet", style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          const Text("Your spending history will appear here", style: TextStyle(color: AppColors.text2, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildTransactionItem(Transaction tx) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.045),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: AppColors.amber.withOpacity(0.11),
              borderRadius: BorderRadius.circular(13),
              border: Border.all(color: AppColors.amber.withOpacity(0.18)),
            ),
            child: const Icon(Icons.shopping_bag_outlined, color: AppColors.amber, size: 24),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tx.merchantName, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                const SizedBox(height: 3),
                Text(DateFormat('dd MMM yyyy, hh:mm a').format(tx.timestamp), style: const TextStyle(color: AppColors.text2, fontSize: 10)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text("₹${tx.amountPaid.toStringAsFixed(2)}", style: GoogleFonts.dmMono(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
              Text("Saved ₹${tx.amountSaved.toStringAsFixed(0)}", style: const TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }
}
