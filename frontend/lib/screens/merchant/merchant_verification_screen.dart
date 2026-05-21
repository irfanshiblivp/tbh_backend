import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/app_theme.dart';
import '../../providers/app_state.dart';
import '../../models/models.dart' as models;

class MerchantVerificationScreen extends StatefulWidget {
  const MerchantVerificationScreen({super.key});

  @override
  State<MerchantVerificationScreen> createState() => _MerchantVerificationScreenState();
}

class _MerchantVerificationScreenState extends State<MerchantVerificationScreen> {
  final _searchController = TextEditingController();
  final _billController = TextEditingController();
  Map<String, dynamic>? _foundUser;
  bool _searching = false;
  
  double _billAmount = 0;
  double _discountAmount = 0;
  double _finalAmount = 0;

  @override
  void dispose() {
    _searchController.dispose();
    _billController.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    if (_searchController.text.isEmpty) return;
    
    setState(() {
      _searching = true;
      _foundUser = null;
      _billAmount = 0;
      _discountAmount = 0;
      _finalAmount = 0;
      _billController.clear();
    });

    final state = Provider.of<AppState>(context, listen: false);
    final user = await state.verifyUser(_searchController.text);
    
    setState(() {
      _searching = false;
      _foundUser = user;
    });

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Member not found. Check phone or email."),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  void _calculateAmounts(double percent) {
    setState(() {
      _billAmount = double.tryParse(_billController.text) ?? 0;
      _discountAmount = (_billAmount * percent) / 100;
      _finalAmount = _billAmount - _discountAmount;
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final merchant = state.merchantProfile;

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1E),
      appBar: AppBar(
        title: Text(
          "Sales POS Register",
          style: GoogleFonts.dmSans(fontWeight: FontWeight.bold, fontSize: 22),
        ),
        backgroundColor: const Color(0xFF151521),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPOSOverview(),
            const SizedBox(height: 24),
            Text(
              "CUSTOMER LOOKUP",
              style: GoogleFonts.jost(
                color: Colors.white60,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 12),
            _buildSearchInput(),
            const SizedBox(height: 32),
            if (_searching)
              const Center(child: CircularProgressIndicator(color: AppColors.amber))
            else if (_foundUser != null)
              _buildUserCard(_foundUser!, merchant)
            else
              _buildRecentStoreRedemptions(state),
          ],
        ),
      ),
    );
  }

  Widget _buildPOSOverview() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1C1C30), Color(0xFF121224)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.03)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.amber.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.qr_code_scanner, color: AppColors.amber, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Discount Redemption Hub",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                ),
                const SizedBox(height: 4),
                Text(
                  "Verify members and redeem discount transactions instantly in real-time.",
                  style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchInput() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF16162A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.04)),
      ),
      child: TextField(
        controller: _searchController,
        style: const TextStyle(color: Colors.white, fontSize: 15),
        onSubmitted: (_) => _search(),
        decoration: InputDecoration(
          hintText: "Enter customer phone or email...",
          hintStyle: const TextStyle(color: Colors.white24, fontSize: 14),
          prefixIcon: const Icon(Icons.search, color: AppColors.amber, size: 22),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          suffixIcon: IconButton(
            icon: const Icon(Icons.arrow_forward_rounded, color: AppColors.amber),
            onPressed: _search,
          ),
        ),
      ),
    );
  }

  Widget _buildUserCard(Map<String, dynamic> user, models.Merchant? merchant) {
    final isPrime = user['is_prime'] == true;
    final discountPercent = merchant?.discountPercent.toDouble() ?? 50.0;
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF16162A),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: isPrime ? Colors.green.withOpacity(0.2) : Colors.redAccent.withOpacity(0.2),
        ),
        gradient: LinearGradient(
          colors: [
            isPrime ? Colors.green.withOpacity(0.04) : Colors.redAccent.withOpacity(0.04),
            Colors.transparent,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: (isPrime ? Colors.green : Colors.redAccent).withOpacity(0.1),
                child: Icon(
                  isPrime ? Icons.verified_user_rounded : Icons.gpp_bad_rounded,
                  size: 28,
                  color: isPrime ? Colors.green : Colors.redAccent,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user['name'] ?? "Club Member",
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      user['email'] ?? "",
                      style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 12),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: (isPrime ? Colors.green : Colors.redAccent).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  isPrime ? "PRIME" : "STANDARD",
                  style: TextStyle(
                    color: isPrime ? Colors.green : Colors.redAccent,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Divider(color: Colors.white10),
          const SizedBox(height: 20),
          if (isPrime) ...[
            TextField(
              controller: _billController,
              keyboardType: TextInputType.number,
              style: GoogleFonts.dmMono(color: Colors.white, fontSize: 16),
              onChanged: (_) => _calculateAmounts(discountPercent),
              decoration: InputDecoration(
                labelText: "ENTER TOTAL BILL AMOUNT",
                labelStyle: const TextStyle(color: Colors.white30, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5),
                prefixText: "₹ ",
                prefixStyle: const TextStyle(color: AppColors.amber, fontWeight: FontWeight.bold),
                filled: true,
                fillColor: Colors.black26,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              ),
            ),
            if (_billAmount > 0) ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    _buildCalcRow("Total Bill Amount", "₹${_billAmount.toStringAsFixed(2)}", Colors.white70),
                    const SizedBox(height: 8),
                    _buildCalcRow("Prime Discount (${discountPercent.toStringAsFixed(0)}%)", "-₹${_discountAmount.toStringAsFixed(2)}", AppColors.amber),
                    const SizedBox(height: 12),
                    const Divider(color: Colors.white10),
                    const SizedBox(height: 12),
                    _buildCalcRow("Customer Pays", "₹${_finalAmount.toStringAsFixed(2)}", Colors.white, isBold: true),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _billAmount <= 0 ? null : () async {
                  final state = Provider.of<AppState>(context, listen: false);
                  final success = await state.redeemDiscount(user['id'], _billAmount);
                  if (success) {
                    setState(() {
                      _foundUser = null;
                      _billAmount = 0;
                      _discountAmount = 0;
                      _finalAmount = 0;
                    });
                    _searchController.clear();
                    _billController.clear();
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Discount Redeemed Successfully! Voucher registered."),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } else {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Redemption failed. Please try again."),
                        backgroundColor: Colors.redAccent,
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.amber,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text(
                  "CONFIRM & REDEEM",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, letterSpacing: 1),
                ),
              ),
            ),
          ] else ...[
            const Icon(Icons.info_outline, color: Colors.orangeAccent, size: 36),
            const SizedBox(height: 16),
            const Text(
              "Standard members are not eligible for exclusive merchant discounts. Advise customer to upgrade to Prime Membership inside their app screen.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white30, fontSize: 13, height: 1.5),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCalcRow(String label, String value, Color color, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: isBold ? Colors.white : Colors.white54, fontSize: 13, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
        Text(value, style: GoogleFonts.dmMono(color: color, fontSize: 14, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildRecentStoreRedemptions(AppState state) {
    final transactions = state.transactions;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "RECENT STORE REDEMPTIONS",
          style: GoogleFonts.jost(
            color: Colors.white60,
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 16),
        if (transactions.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              color: const Color(0xFF16162A),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withOpacity(0.02)),
            ),
            child: Column(
              children: [
                Icon(Icons.history_toggle_off_rounded, color: Colors.white10, size: 48),
                const SizedBox(height: 16),
                const Text(
                  "No redemptions registered yet today.",
                  style: TextStyle(color: Colors.white30, fontSize: 13),
                ),
              ],
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: transactions.length > 5 ? 5 : transactions.length,
            itemBuilder: (context, index) {
              final tx = transactions[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF16162A),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.02)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.greenAccent.withOpacity(0.08),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check_circle_outline_rounded, color: Colors.greenAccent, size: 20),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tx.userName,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            DateFormat('MMM d, h:mm a').format(tx.timestamp),
                            style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          "₹${tx.amountPaid.toStringAsFixed(0)}",
                          style: GoogleFonts.dmMono(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Saved ₹${tx.amountSaved?.toStringAsFixed(0) ?? '0'}",
                          style: GoogleFonts.dmMono(color: AppColors.amber, fontSize: 11, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }
}
