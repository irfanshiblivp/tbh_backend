import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_theme.dart';
import '../../providers/app_state.dart';
import '../../models/models.dart';

class AdminManagementScreen extends StatefulWidget {
  const AdminManagementScreen({super.key});

  @override
  State<AdminManagementScreen> createState() => _AdminManagementScreenState();
}

class _AdminManagementScreenState extends State<AdminManagementScreen> {
  List<AppUser> _users = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    final state = Provider.of<AppState>(context, listen: false);
    try {
      final users = await state.getAppUsers();
      if (mounted) {
        setState(() {
          _users = users.where((u) => u.role == 'admin' || u.role == 'staff').toList();
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showAddUserDialog(String role) {
    final userController = TextEditingController();
    final passController = TextEditingController();
    final emailController = TextEditingController();
    final state = Provider.of<AppState>(context, listen: false);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: Text("Add New ${role == 'admin' ? 'Admin' : 'Staff'}"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _dialogField(userController, "Username"),
            _dialogField(passController, "Password", obscure: true),
            _dialogField(emailController, "Email"),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              try {
                if (role == 'admin') {
                   // This endpoint might need to be created if not exists, for now using createStaff for both for demo
                   await state.adminCreateStaff({
                    'username': userController.text,
                    'password': passController.text,
                    'email': emailController.text,
                    'role': 'admin'
                  });
                } else {
                  await state.adminCreateStaff({
                    'username': userController.text,
                    'password': passController.text,
                    'email': emailController.text,
                    'role': 'staff'
                  });
                }
                Navigator.pop(context);
                _loadUsers();
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
              }
            },
            child: const Text("Add"),
          ),
        ],
      ),
    );
  }

  Widget _dialogField(TextEditingController ctrl, String label, {bool obscure = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: ctrl,
        obscureText: obscure,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white60),
          filled: true,
          fillColor: Colors.white.withOpacity(0.05),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("User Management", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                Row(
                  children: [
                    ElevatedButton(
                      onPressed: () => _showAddUserDialog('staff'),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
                      child: const Text("Add Staff", style: TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: _loading 
              ? const Center(child: CircularProgressIndicator(color: AppColors.amber))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  itemCount: _users.length,
                  itemBuilder: (context, index) {
                    final user = _users[index];
                    return _buildUserTile(user);
                  },
                ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddUserDialog('admin'),
        backgroundColor: AppColors.amber,
        icon: const Icon(Icons.add, color: Colors.black),
        label: const Text("Add Admin", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildUserTile(AppUser user) {
    bool isStaff = user.role == 'staff';
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: (isStaff ? Colors.blue : AppColors.amber).withOpacity(0.1),
            child: Text(user.username[0].toUpperCase(), style: TextStyle(color: isStaff ? Colors.blue : AppColors.amber)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(user.username, style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: (isStaff ? Colors.blue : AppColors.amber).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(user.role.toUpperCase(), style: TextStyle(fontSize: 8, color: isStaff ? Colors.blue : AppColors.amber, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                Text(user.email, style: const TextStyle(color: Colors.white30, fontSize: 12)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
            onPressed: () async {
              final state = Provider.of<AppState>(context, listen: false);
              try {
                await state.deleteAppUser(user.id);
                _loadUsers();
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
              }
            },
          ),
        ],
      ),
    );
  }
}
