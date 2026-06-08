import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
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
  String _activeFilter = 'all'; // 'all', 'direct', 'referral'

  List<AppUser> _getFilteredUsers() {
    return _users.where((u) {
      if (_activeFilter == 'direct') {
        return u.signupMethod == 'Direct';
      } else if (_activeFilter == 'referral') {
        return u.signupMethod.startsWith('Referral');
      }
      return true;
    }).toList();
  }

  void _exportCSV() async {
    final listToExport = _getFilteredUsers();
    if (listToExport.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No customers to export in this filter")),
      );
      return;
    }

    String filterTitle = _activeFilter.toUpperCase();
    String csv = "ID,Name,Email,Phone,Role,Status,Signup Method\n";
    for (var u in listToExport) {
      String name = u.username.replaceAll('"', '""');
      String email = u.email.replaceAll('"', '""');
      String phone = (u.phone ?? '').replaceAll('"', '""');
      String method = u.signupMethod.replaceAll('"', '""');
      csv += '${u.id},"$name","$email","$phone",${u.role},${u.status},"$method"\n';
    }
    
    Clipboard.setData(ClipboardData(text: csv));
    
    final bytes = utf8.encode(csv);
    final base64Csv = base64Encode(bytes);
    final url = 'data:text/csv;base64,$base64Csv';
    
    try {
      final uri = Uri.parse(url);
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("$filterTitle Customer List Exported successfully! File download started & copied to clipboard.")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("$filterTitle list copied to clipboard! (Download failed)")),
        );
      }
    }
  }

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
        _users = users.where((u) => u.role == 'customer').toList();
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredUsers = _getFilteredUsers();
    final directCount = _users.where((u) => u.signupMethod == 'Direct').length;
    final referralCount = _users.where((u) => u.signupMethod.startsWith('Referral')).length;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 16,
              runSpacing: 12,
              children: [
                const Text("AppUser Management", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(12)),
                      child: Text("${filteredUsers.length} SHOWN", style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white54)),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: _exportCSV,
                      icon: const Icon(Icons.download, size: 14, color: Colors.black),
                      label: Text("Export ${(_activeFilter == 'all' ? 'All' : _activeFilter == 'direct' ? 'Direct' : 'Referrals')} CSV", style: const TextStyle(color: Colors.black, fontSize: 11, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.amber,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Premium Filter Tabs
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip("all", "All Customers (${_users.length})"),
                  const SizedBox(width: 10),
                  _buildFilterChip("direct", "Direct ($directCount)"),
                  const SizedBox(width: 10),
                  _buildFilterChip("referral", "Referrals ($referralCount)"),
                ],
              ),
            ),
          ),

          Expanded(
            child: _loading 
              ? const Center(child: CircularProgressIndicator(color: AppColors.amber))
              : filteredUsers.isEmpty
                  ? const Center(child: Text("No customers match this filter", style: TextStyle(color: Colors.white24)))
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      itemCount: filteredUsers.length,
                      itemBuilder: (context, index) {
                        final user = filteredUsers[index];
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
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: isMobile ? 20 : 24,
                backgroundColor: AppColors.amber.withValues(alpha: 0.1),
                child: Text(user.username.isNotEmpty ? user.username[0].toUpperCase() : 'U', style: const TextStyle(color: AppColors.amber, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user.username, style: TextStyle(fontWeight: FontWeight.bold, fontSize: isMobile ? 14 : 16)),
                    Text(user.email, style: const TextStyle(color: Colors.white30, fontSize: 11)),
                    const SizedBox(height: 6),
                    _buildSignupMethodBadge(user.signupMethod),
                  ],
                ),
              ),
              if (!isMobile)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
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
                    color: Colors.white.withValues(alpha: 0.05),
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

  Widget _buildSignupMethodBadge(String method) {
    final isReferral = method.startsWith("Referral");
    final color = isReferral ? AppColors.amber : Colors.white38;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isReferral ? Icons.people_outline : Icons.login_outlined,
            color: color,
            size: 10,
          ),
          const SizedBox(width: 4),
          Text(
            method.toUpperCase(),
            style: TextStyle(
              color: isReferral ? Colors.white : Colors.white38,
              fontSize: 9,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String filter, String label) {
    final isSelected = _activeFilter == filter;
    final color = isSelected ? AppColors.amber : Colors.white38;
    return InkWell(
      onTap: () => setState(() => _activeFilter = filter),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.amber.withValues(alpha: 0.08) : Colors.white.withValues(alpha: 0.02),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? AppColors.amber.withValues(alpha: 0.4) : Colors.white.withValues(alpha: 0.05)),
        ),
        child: Text(
          label.toUpperCase(),
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white60,
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}


