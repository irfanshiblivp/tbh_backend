import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_theme.dart';
import '../../providers/app_state.dart';

class PlatformSettingsScreen extends StatefulWidget {
  const PlatformSettingsScreen({super.key});

  @override
  State<PlatformSettingsScreen> createState() => _PlatformSettingsScreenState();
}

class _PlatformSettingsScreenState extends State<PlatformSettingsScreen> {
  @override
  void initState() {
    super.initState();
    context.read<AppState>().loadSettings();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final settings = state.settings.where((s) => !s.key.startsWith('PRIME_')).toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Platform Settings", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 10),
            const Text("Global configuration, API keys, and platform constants", style: TextStyle(color: Colors.white38, fontSize: 14)),
            const SizedBox(height: 32),
            Expanded(
              child: ListView.builder(
                itemCount: settings.length,
                itemBuilder: (context, index) {
                  final s = settings[index];
                  return _buildSettingItem(s, state);
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddSettingDialog(context, state),
        backgroundColor: AppColors.amber,
        child: const Icon(Icons.add, color: Colors.black),
      ),
    );
  }

  Widget _buildSettingItem(dynamic s, AppState state) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.key, style: const TextStyle(color: AppColors.amber, fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 4),
                Text(s.value, style: const TextStyle(color: Colors.white, fontSize: 16)),
                const SizedBox(height: 8),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: Colors.white54),
            onPressed: () => _showEditDialog(context, state, s),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
            onPressed: () => state.deleteAppSetting(s.id),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(BuildContext context, AppState state, dynamic setting) {
    final controller = TextEditingController(text: setting.value);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: Text("Edit ${setting.key}"),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(labelText: "Value", labelStyle: TextStyle(color: Colors.white54)),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              state.updateAppSetting(setting.id, controller.text);
              Navigator.pop(context);
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  void _showAddSettingDialog(BuildContext context, AppState state) {
    final keyController = TextEditingController();
    final valController = TextEditingController();
    final descController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text("Add New Setting"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: keyController, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: "Key (e.g. RAZORPAY_KEY)")),
            TextField(controller: valController, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: "Value")),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              state.createAppSetting(keyController.text, valController.text);
              Navigator.pop(context);
            },
            child: const Text("Create"),
          ),
        ],
      ),
    );
  }
}
