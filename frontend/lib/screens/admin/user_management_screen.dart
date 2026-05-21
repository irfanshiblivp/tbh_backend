import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_theme.dart';
import '../../providers/app_state.dart';
import '../../models/models.dart';

class AppUserManagementScreen extends StatefulWidget {
  const AppUserManagementScreen({super.key});

  @override
  State<AppUserManagementScreen> createState() => _AppUserManagementScreenState();
}

class _AppUserManagementScreenState extends State<AppUserManagementScreen> {
  List<AppUser> _users = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadAppUsers();
  }

  Future<void> _loadAppUsers() async {
    final state = Provider.of<AppState>(context, listen: false);
    try {
      final users = await state.getAppUsers();
      setState(() {
        _users = users;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 16,
              runSpacing: 12,
              children: [
                const Text("AppUser Management", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(12)),
                  child: Text("${_users.length} TOTAL USERS", style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white54)),
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
                    return _buildAppUserTile(user);
                  },
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppUserTile(AppUser user) {
    final state = Provider.of<AppState>(context, listen: false);
    final isBlocked = user.isBlocked;

    final isMobile = MediaQuery.of(context).size.width < 600;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: isMobile ? 20 : 24,
                backgroundColor: AppColors.amber.withOpacity(0.1),
                child: Text(user.username.isNotEmpty ? user.username[0].toUpperCase() : 'U', style: const TextStyle(color: AppColors.amber, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user.username, style: TextStyle(fontWeight: FontWeight.bold, fontSize: isMobile ? 14 : 16)),
                    Text(user.email, style: const TextStyle(color: Colors.white30, fontSize: 11)),
                  ],
                ),
              ),
              if (!isMobile)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(user.role, style: const TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
            ],
          ),
          if (isMobile) const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (isMobile)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(user.role, style: const TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              const Spacer(),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: Icon(user.isPrime ? Icons.star : Icons.star_border, color: AppColors.amber, size: 20),
                onPressed: () async {
                  if (user.isPrime) {
                    bool? confirm = await showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        backgroundColor: const Color(0xFF1A1A2E),
                        title: const Text("Revoke Prime?"),
                        content: const Text("Are you sure you want to revoke Prime membership for this user?"),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text("Cancel"),
                          ),
                          ElevatedButton(
                            onPressed: () => Navigator.pop(context, true),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                            child: const Text("Revoke"),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      try {
                        await state.revokePrime(user.id);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Prime membership revoked successfully")),
                        );
                        _loadAppUsers();
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Error: $e")),
                        );
                      }
                    }
                  } else {
                    bool? confirm = await showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        backgroundColor: const Color(0xFF1A1A2E),
                        title: const Text("Grant Prime?"),
                        content: const Text("Are you sure you want to grant 1 year Prime membership to this user?"),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text("Cancel"),
                          ),
                          ElevatedButton(
                            onPressed: () => Navigator.pop(context, true),
                            style: ElevatedButton.styleFrom(backgroundColor: AppColors.amber),
                            child: const Text("Grant", style: TextStyle(color: Colors.black)),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      try {
                        await state.grantPrime(user.id);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Prime membership granted successfully")),
                        );
                        _loadAppUsers();
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Error: $e")),
                        );
                      }
                    }
                  }
                },
                tooltip: user.isPrime ? "Prime Active" : "Grant Prime",
              ),
              const SizedBox(width: 12),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Icon(Icons.lock_reset, color: Colors.blueAccent, size: 20),
                onPressed: () => _showResetPasswordDialog(user.id, state),
                tooltip: "Reset Password",
              ),
              const SizedBox(width: 12),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: Icon(isBlocked ? Icons.lock_open : Icons.block, color: isBlocked ? Colors.green : Colors.redAccent, size: 20),
                onPressed: () async {
                  try {
                    await state.toggleAppUserBlock(user.id);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(isBlocked ? "User unblocked successfully" : "User blocked successfully")));
                    _loadAppUsers();
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
                  }
                },
                tooltip: isBlocked ? "Unblock" : "Block",
              ),
              if (user.role.toLowerCase() != 'admin') ...[
                const SizedBox(width: 12),
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                  tooltip: "Delete User",
                  onPressed: () async {
                    bool? confirm = await showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        backgroundColor: const Color(0xFF1A1A2E),
                        title: const Text("Delete User?"),
                        content: const Text("This action cannot be undone. User and all related data will be permanently deleted."),
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
                      try {
                        await state.deleteAppUser(user.id);
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("User deleted successfully")));
                        _loadAppUsers();
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error deleting user: $e")));
                      }
                    }
                  },
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  void _showResetPasswordDialog(int userId, AppState state) {
    final passController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text("Reset User Password"),
        content: TextField(
          controller: passController,
          obscureText: true,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(labelText: "New Password", labelStyle: TextStyle(color: Colors.white60)),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              try {
                await state.adminResetUserPassword(userId, passController.text);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Password reset successful")));
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
              }
            },
            child: const Text("Reset"),
          ),
        ],
      ),
    );
  }
}


