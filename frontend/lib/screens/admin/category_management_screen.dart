import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_theme.dart';
import '../../providers/app_state.dart';
import '../../models/models.dart';

class CategoryManagementScreen extends StatefulWidget {
  const CategoryManagementScreen({super.key});

  @override
  State<CategoryManagementScreen> createState() => _CategoryManagementScreenState();
}

class _CategoryManagementScreenState extends State<CategoryManagementScreen> {

  final _nameController = TextEditingController();

  void _showAddDialog(AppState state, {Category? category}) {
    if (category != null) {
      _nameController.text = category.name;
    } else {
      _nameController.clear();
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(category == null ? "Add Category" : "Edit Category", style: const TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _dialogField(_nameController, "Name"),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              if (_nameController.text.isEmpty) return;
              try {
                await state.addCategory(_nameController.text);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Category added successfully!")));
                Navigator.pop(context);
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
              }
            },
            child: Text(category == null ? "Add" : "Save"),
          ),
        ],
      ),
    );
  }

  Widget _dialogField(TextEditingController controller, String label) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(labelText: label, labelStyle: const TextStyle(color: Colors.white60)),
    );
  }


  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Platform Categories", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                ElevatedButton.icon(
                  onPressed: () => _showAddDialog(state),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text("Add New", style: TextStyle(fontSize: 12)),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.amber, foregroundColor: Colors.black),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              itemCount: state.categories.length,
              itemBuilder: (context, index) {
                final category = state.categories[index];
                return _buildCategoryCard(category, state);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(Category category, AppState state) {
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
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppColors.amber.withOpacity(0.1), borderRadius: BorderRadius.circular(14)),
            child: const Icon(Icons.category, color: AppColors.amber, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(category.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  backgroundColor: const Color(0xFF1A1A2E),
                  title: const Text("Delete Category?"),
                  content: Text("Are you sure you want to delete '${category.name}'?"),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
                    TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Delete", style: TextStyle(color: Colors.redAccent))),
                  ],
                ),
              );
              if (confirm == true) {
                try {
                  await state.deleteCategory(category.id);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Category deleted")));
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
                }
              }
            },
          ),
        ],
      ),
    );
  }
}
