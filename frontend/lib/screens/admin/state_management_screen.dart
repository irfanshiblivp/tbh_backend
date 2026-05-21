import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_theme.dart';
import '../../providers/app_state.dart';
import '../../models/models.dart';

class StateManagementScreen extends StatefulWidget {
  const StateManagementScreen({super.key});

  @override
  State<StateManagementScreen> createState() => _StateManagementScreenState();
}

class _StateManagementScreenState extends State<StateManagementScreen> {
  @override
  void initState() {
    super.initState();
    // In a real app, you'd fetch states from API.
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    // Mocking states for now as we haven't implemented getStates in ApiService yet
    final List<StateRegion> states = [
      StateRegion(id: 1, name: "Kerala", code: "KL"),
      StateRegion(id: 2, name: "Tamil Nadu", code: "TN"),
      StateRegion(id: 3, name: "Karnataka", code: "KA"),
    ];

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Text("Region & State Management", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.add),
                  label: const Text("Add State"),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.amber, foregroundColor: Colors.black),
                ),
              ],
            ),
            const SizedBox(height: 32),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A2E),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.05)),
                ),
                child: ListView.separated(
                  itemCount: states.length,
                  separatorBuilder: (context, index) => Divider(color: Colors.white.withOpacity(0.05)),
                  itemBuilder: (context, index) {
                    final s = states[index];
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                      title: Text(s.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      subtitle: Text("Code: ${s.code}", style: const TextStyle(color: Colors.white38)),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(icon: const Icon(Icons.edit_outlined, color: Colors.white54), onPressed: () {}),
                          IconButton(icon: const Icon(Icons.delete_outline, color: Colors.redAccent), onPressed: () {}),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
