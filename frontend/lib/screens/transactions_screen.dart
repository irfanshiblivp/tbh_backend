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
      backgroundColor: const Color(0xFF07070A),
      body: Stack(
        children: [
          // Background ambient light orbs for premium visual depth
          Positioned(
            top: -100,
            right: -50,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [AppColors.amber.withValues(alpha: 0.15), Colors.transparent],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 50,
            left: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [AppColors.amber2.withValues(alpha: 0.06), Colors.transparent],
                ),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Custom Premium Header Section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Transactions",
                            style: GoogleFonts.playfairDisplay(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "PAST SPENDING & SAVINGS",
                            style: GoogleFonts.jost(
                              color: AppColors.text2,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.04),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                        ),
                        child: Text(
                          "${state.transactions.length} RECORDS",
                          style: GoogleFonts.dmMono(
                            color: AppColors.amber2,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Transactions List
                Expanded(
                  child: state.transactions.isEmpty
                      ? _buildEmptyState()
                      : RefreshIndicator(
                          color: AppColors.amber,
                          backgroundColor: AppColors.ink2,
                          onRefresh: state.refreshData,
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                            physics: const BouncingScrollPhysics(),
                            itemCount: state.transactions.length,
                            itemBuilder: (context, index) {
                              return _buildTransactionItem(state.transactions[index]);
                            },
                          ),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
            ),
            child: const Icon(Icons.receipt_long_outlined, size: 36, color: Colors.white24),
          ),
          const SizedBox(height: 20),
          Text(
            "No Transactions Yet",
            style: GoogleFonts.jost(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "Your spending and prime benefits history will appear here",
            textAlign: TextAlign.center,
            style: GoogleFonts.jost(
              color: AppColors.text2,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionItem(Transaction tx) {
    bool isPrimePayment = tx.merchantName.toLowerCase().contains('prime') || 
                          tx.merchantName.toLowerCase().contains('upgrade');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05), width: 1.1),
      ),
      child: Row(
        children: [
          // Elegant Icon Container
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isPrimePayment 
                  ? const Color(0xFFD4AF37).withValues(alpha: 0.08) 
                  : AppColors.amber.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: isPrimePayment 
                    ? const Color(0xFFD4AF37).withValues(alpha: 0.22) 
                    : AppColors.amber.withValues(alpha: 0.18),
                width: 1.2,
              ),
            ),
            child: Icon(
              isPrimePayment ? Icons.stars : Icons.payments_outlined, 
              color: isPrimePayment ? const Color(0xFFD4AF37) : AppColors.amber, 
              size: 22,
            ),
          ),
          const SizedBox(width: 16),

          // Merchant name and Date
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isPrimePayment ? "PRIME CLUB UPGRADE" : tx.merchantName.toUpperCase(), 
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.jost(
                    color: isPrimePayment ? const Color(0xFFD4AF37) : Colors.white, 
                    fontSize: 13, 
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    Text(
                      DateFormat('dd MMM yyyy • hh:mm a').format(tx.timestamp).toUpperCase(), 
                      style: GoogleFonts.dmMono(
                        color: AppColors.text2.withValues(alpha: 0.7), 
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: tx.paymentMethod.toUpperCase() == 'CASH'
                            ? Colors.green.withValues(alpha: 0.1)
                            : Colors.blue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: tx.paymentMethod.toUpperCase() == 'CASH'
                              ? Colors.green.withValues(alpha: 0.3)
                              : Colors.blue.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        tx.paymentMethod.toUpperCase(),
                        style: GoogleFonts.jost(
                          color: tx.paymentMethod.toUpperCase() == 'CASH'
                              ? Colors.greenAccent
                              : Colors.blueAccent,
                          fontSize: 7,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Pricing Column
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                "₹${tx.amountPaid.toStringAsFixed(2)}", 
                style: GoogleFonts.dmMono(
                  color: Colors.white, 
                  fontSize: 14, 
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              tx.amountSaved > 0
                  ? Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green.withValues(alpha: 0.18)),
                      ),
                      child: Text(
                        "SAVED ₹${tx.amountSaved.toStringAsFixed(0)}", 
                        style: GoogleFonts.jost(
                          color: Colors.greenAccent, 
                          fontSize: 8, 
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.2,
                        ),
                      ),
                    )
                  : Text(
                      "PRIME ACCESS", 
                      style: GoogleFonts.jost(
                        color: const Color(0xFFD4AF37), 
                        fontSize: 8, 
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
            ],
          ),
        ],
      ),
    );
  }
}
