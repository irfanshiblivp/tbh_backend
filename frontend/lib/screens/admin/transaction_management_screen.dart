import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:frontend/providers/app_state.dart';
import 'package:frontend/models/models.dart';
import 'package:frontend/core/app_theme.dart';
import 'package:intl/intl.dart';

class TransactionManagementScreen extends StatefulWidget {
  const TransactionManagementScreen({super.key});

  @override
  State<TransactionManagementScreen> createState() => _TransactionManagementScreenState();
}

class _TransactionManagementScreenState extends State<TransactionManagementScreen> {
  String _searchQuery = "";
  String _statusFilter = "ALL";
  int? _selectedMerchantId;
  DateTimeRange? _dateRange;
  List<Transaction> _filteredTransactions = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchTransactions();
  }

  Future<void> _fetchTransactions() async {
    final state = Provider.of<AppState>(context, listen: false);
    setState(() => _loading = true);
    try {
      final txs = await state.getAdminTransactions(
        merchantId: _selectedMerchantId,
        dateFrom: _dateRange?.start != null ? DateFormat('yyyy-MM-dd').format(_dateRange!.start) : null,
        dateTo: _dateRange?.end != null ? DateFormat('yyyy-MM-dd').format(_dateRange!.end) : null,
      );
      if (mounted) setState(() { _filteredTransactions = txs; _loading = false; });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          _buildToolbar(state),
          _buildFilters(state),
          Expanded(
            child: _loading 
              ? const Center(child: CircularProgressIndicator(color: AppColors.amber))
              : _buildTransactionTable(_filteredTransactions),
          ),
        ],
      ),
    );
  }

  Widget _buildToolbar(AppState state) {
    final isMobile = MediaQuery.of(context).size.width < 700;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Wrap(
        spacing: 16,
        runSpacing: 16,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text("Financial Transactions", style: TextStyle(fontSize: isMobile ? 18 : 20, fontWeight: FontWeight.bold)),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: isMobile ? 150 : 200,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(12)),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    isExpanded: true,
                    value: _selectedMerchantId,
                    hint: const Text("Filter Merchant", style: TextStyle(color: Colors.white24, fontSize: 11)),
                    dropdownColor: const Color(0xFF1A1A2E),
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                    items: [
                      const DropdownMenuItem(value: null, child: Text("All Merchants")),
                      ...state.merchants.map((m) => DropdownMenuItem(value: m.id, child: Text(m.name))),
                    ],
                    onChanged: (val) {
                      setState(() => _selectedMerchantId = val);
                      _fetchTransactions();
                    },
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: () async {
                  final picked = await showDateRangePicker(
                    context: context,
                    firstDate: DateTime(2023),
                    lastDate: DateTime.now(),
                    builder: (context, child) => Theme(
                      data: Theme.of(context).copyWith(
                        colorScheme: const ColorScheme.dark(primary: AppColors.amber, onPrimary: Colors.black, surface: Color(0xFF1A1A2E)),
                      ),
                      child: child!,
                    ),
                  );
                  if (picked != null) {
                    setState(() => _dateRange = picked);
                    _fetchTransactions();
                  }
                },
                icon: const Icon(Icons.calendar_today, size: 14),
                label: Text(
                  _dateRange == null ? "Select Date" : "${DateFormat('MMM d').format(_dateRange!.start)}",
                  style: const TextStyle(fontSize: 11),
                ),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.white.withOpacity(0.05), padding: const EdgeInsets.symmetric(horizontal: 12)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilters(AppState state) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          _filterChip("ALL"),
          _filterChip("SUCCESS"),
          _filterChip("REDEEMED"),
          _filterChip("FAILED"),
          _filterChip("PENDING"),
          if (_selectedMerchantId != null || _dateRange != null)
            TextButton.icon(
              onPressed: () {
                setState(() { _selectedMerchantId = null; _dateRange = null; });
                _fetchTransactions();
              },
              icon: const Icon(Icons.clear, size: 14, color: Colors.redAccent),
              label: const Text("Clear Filters", style: TextStyle(color: Colors.redAccent, fontSize: 12)),
            ),
        ],
      ),
    );
  }

  Widget _filterChip(String label) {
    final isSelected = _statusFilter == label;
    return InkWell(
      onTap: () => setState(() => _statusFilter = label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.amber : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.black : Colors.white54,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionTable(List<Transaction> transactions) {
    final filtered = transactions.where((t) => _statusFilter == "ALL" || t.status == _statusFilter).toList();
    
    return Container(
      margin: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(24),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingTextStyle: const TextStyle(color: Colors.white54, fontWeight: FontWeight.bold),
          dataTextStyle: const TextStyle(color: Colors.white, fontSize: 13),
          columns: const [
            DataColumn(label: Text("TRANSACTION ID")),
            DataColumn(label: Text("DATE")),
            DataColumn(label: Text("USER")),
            DataColumn(label: Text("MERCHANT")),
            DataColumn(label: Text("AMOUNT")),
            DataColumn(label: Text("STATUS")),
          ],
          rows: filtered.map((t) => DataRow(
            cells: [
              DataCell(Text(t.transactionId.length > 8 ? t.transactionId.substring(0, 8) : t.transactionId)),
              DataCell(Text(DateFormat('MMM d, HH:mm').format(t.timestamp))),
              DataCell(Text(t.userName)),
              DataCell(Text(t.merchantName)),
              DataCell(Text("₹${t.amountPaid}")),
              DataCell(_statusBadge(t.status)),
            ],
          )).toList(),
        ),
      ),
    );
  }

  Widget _statusBadge(String status) {
    Color color;
    switch (status) {
      case 'SUCCESS': color = Colors.green; break;
      case 'REDEEMED': color = Colors.blue; break;
      case 'FAILED': color = Colors.red; break;
      default: color = Colors.orange;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
      child: Text(status, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }
}

