import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_theme.dart';
import '../../providers/app_state.dart';
import '../../models/models.dart';

class PrimeManagementScreen extends StatefulWidget {
  const PrimeManagementScreen({super.key});

  @override
  State<PrimeManagementScreen> createState() => _PrimeManagementScreenState();
}

class _PrimeManagementScreenState extends State<PrimeManagementScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppState>().loadSettings();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    final allSettings = state.settings;
    final primeSettings = allSettings.where((s) => s.key.startsWith('PRIME_PLAN_')).toList();
    
    // For preview, we'll use the first one or default
    final previewPlan = primeSettings.isNotEmpty ? primeSettings.first : AppSetting(id: 0, key: 'PRIME_PLAN', value: '999|999|Unlimited discounts');
    final parts = previewPlan.value.split('|');
    final previewOldPrice = parts[0];
    final previewNewPrice = parts.length > 1 ? parts[1] : previewOldPrice;
    final previewBenefits = parts.length > 2 ? parts[2] : "";

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.amber.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.workspace_premium, color: AppColors.amber, size: 28),
                ),
                const SizedBox(width: 16),
                const Text("Prime Membership Plan", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 40),
            if (MediaQuery.of(context).size.width < 900) ...[
              Column(
                children: [
                  _buildPlansList(primeSettings, state),
                  const SizedBox(height: 40),
                  _buildPreviewCard(previewOldPrice, previewNewPrice, previewBenefits, previewPlan.key),
                ],
              ),
            ] else
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: _buildPlansList(primeSettings, state),
                  ),
                  const SizedBox(width: 40),
                  Expanded(
                    flex: 1,
                    child: _buildPreviewCard(previewOldPrice, previewNewPrice, previewBenefits, previewPlan.key),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlansList(List<AppSetting> plans, AppState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("Active Plans", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white70)),
            ElevatedButton.icon(
              onPressed: () => _showPlanDialog(context, state),
              icon: const Icon(Icons.add, size: 16),
              label: const Text("Add Plan"),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.amber.withOpacity(0.1), foregroundColor: AppColors.amber),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (plans.isEmpty)
          const Center(child: Text("No plans found. Add one to get started.", style: TextStyle(color: Colors.white24)))
        else
          ...plans.map((plan) => Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _buildPlanCard(context, plan, state),
          )).toList(),
      ],
    );
  }

  Widget _buildPlanCard(BuildContext context, AppSetting plan, AppState state) {
    final parts = plan.value.split('|');
    final oldPrice = parts[0];
    final newPrice = parts.length > 1 ? parts[1] : oldPrice;
    final benefits = parts.length > 2 ? parts[2] : "";

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppColors.amber.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.card_membership, color: AppColors.amber),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(plan.key.replaceAll('PRIME_PLAN_', '').replaceAll('_', ' '), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Row(
                  children: [
                    if (oldPrice != newPrice) ...[
                      Text("₹$oldPrice", style: const TextStyle(color: Colors.white38, fontSize: 13, decoration: TextDecoration.lineThrough)),
                      const SizedBox(width: 8),
                    ],
                    Text("₹$newPrice", style: const TextStyle(color: AppColors.amber, fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: Colors.white54),
            onPressed: () => _showPlanDialog(context, state, plan: plan),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
            onPressed: () async {
              bool? confirm = await showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  backgroundColor: const Color(0xFF1A1A2E),
                  title: const Text("Delete Plan?"),
                  content: Text("Are you sure you want to delete ${plan.key}?"),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      child: const Text("Delete"),
                    ),
                  ],
                ),
              );
              if (confirm == true) {
                await state.deleteAppSetting(plan.id);
              }
            },
          ),
        ],
      ),
    );
  }

  void _showPlanDialog(BuildContext context, AppState state, {AppSetting? plan}) {
    final parts = plan?.value.split('|') ?? [];
    String planType = plan != null ? (plan.key.contains('MONTHLY') ? 'MONTHLY' : 'YEARLY') : 'MONTHLY';
    final oldPriceController = TextEditingController(text: parts.isNotEmpty ? parts[0] : '');
    final newPriceController = TextEditingController(text: parts.length > 1 ? parts[1] : '');
    final benefitsController = TextEditingController(text: parts.length > 2 ? parts[2] : '');
    final nameController = TextEditingController(text: plan?.key.replaceAll('PRIME_PLAN_', '').replaceAll('_MONTHLY', '').replaceAll('_YEARLY', '') ?? '');

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF1A1A2E),
          title: Text(plan == null ? "Add Prime Plan" : "Edit Plan"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: planType,
                  dropdownColor: const Color(0xFF1A1A2E),
                  decoration: const InputDecoration(labelText: "Plan Type", labelStyle: TextStyle(color: Colors.white60)),
                  items: const [
                    DropdownMenuItem(value: "MONTHLY", child: Text("Monthly", style: TextStyle(color: Colors.white))),
                    DropdownMenuItem(value: "YEARLY", child: Text("Yearly", style: TextStyle(color: Colors.white))),
                  ],
                  onChanged: plan == null ? (val) => setDialogState(() => planType = val!) : null,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: nameController,
                  enabled: plan == null,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(labelText: "Plan Name (e.g., SILVER, GOLD)", labelStyle: TextStyle(color: Colors.white60)),
                ),
                TextField(
                  controller: oldPriceController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(labelText: "Original Price (MRP)", labelStyle: TextStyle(color: Colors.white60)),
                ),
                TextField(
                  controller: newPriceController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(labelText: "Discounted Price", labelStyle: TextStyle(color: Colors.white60)),
                ),
                TextField(
                  controller: benefitsController,
                  style: const TextStyle(color: Colors.white),
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: "Benefits (comma separated)", labelStyle: TextStyle(color: Colors.white60)),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
            ElevatedButton(
              onPressed: () async {
                final val = "${oldPriceController.text}|${newPriceController.text}|${benefitsController.text}";
                if (plan == null) {
                  final key = "PRIME_PLAN_${nameController.text.toUpperCase().trim()}_$planType";
                  await state.createAppSetting(key, val);
                } else {
                  await state.updateAppSetting(plan.id, val);
                }
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text("Save"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewCard(String oldPrice, String newPrice, String benefits, String planName) {
    final benefitList = benefits.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.amber.withOpacity(0.1), AppColors.amber.withOpacity(0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.amber.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.star, color: AppColors.amber),
              const SizedBox(width: 8),
              Text("${planName.replaceAll('PRIME_PLAN_', '').replaceAll('_', ' ')} Preview", style: const TextStyle(color: AppColors.amber, fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 24),
          const Text("Prime Membership", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              if (oldPrice != newPrice) ...[
                Text("₹$oldPrice", style: const TextStyle(color: Colors.white38, fontSize: 16, decoration: TextDecoration.lineThrough)),
                const SizedBox(width: 8),
              ],
              Text("₹$newPrice", style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
              const Text(" / month", style: TextStyle(color: Colors.white54, fontSize: 16)),
            ],
          ),
          const SizedBox(height: 24),
          const Divider(color: Colors.white10),
          const SizedBox(height: 24),
          ...benefitList.map((benefit) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 20),
                const SizedBox(width: 12),
                Expanded(child: Text(benefit, style: const TextStyle(color: Colors.white, fontSize: 14))),
              ],
            ),
          )).toList(),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.amber,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text("Join Prime (Preview)", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

}
