import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/app_theme.dart';
import '../../providers/app_state.dart';

class AnnouncementScreen extends StatefulWidget {
  const AnnouncementScreen({super.key});

  @override
  State<AnnouncementScreen> createState() => _AnnouncementScreenState();
}

class _AnnouncementScreenState extends State<AnnouncementScreen> {
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();
  String _target = "BOTH";
  List<dynamic> _sentAnnouncements = [];
  bool _loadingHistory = true;

  @override
  void initState() {
    super.initState();
    _loadSentAnnouncements();
  }

  Future<void> _loadSentAnnouncements() async {
    final state = Provider.of<AppState>(context, listen: false);
    try {
      final list = await state.getAnnouncements();
      setState(() {
        _sentAnnouncements = list;
        _loadingHistory = false;
      });
    } catch (e) {
      setState(() => _loadingHistory = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Push Announcements", style: GoogleFonts.dmSans(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text("Send real-time notifications to your users and merchants.", style: TextStyle(color: Colors.white30, fontSize: 14)),
            const SizedBox(height: 32),
            
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final isWide = constraints.maxWidth > 900;
                        
                        return isWide 
                          ? Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(flex: 2, child: _buildForm(state)),
                                const SizedBox(width: 24),
                                Expanded(flex: 1, child: _buildPreview(state)),
                              ],
                            )
                          : Column(
                              children: [
                                _buildForm(state),
                                const SizedBox(height: 32),
                                _buildPreview(state),
                              ],
                            );
                      },
                    ),
                    const SizedBox(height: 40),
                    _buildHistorySection(state),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForm(AppState state) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("New Announcement", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 24),
          
          const Text("Target Audience", style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _target,
                dropdownColor: const Color(0xFF1A1A2E),
                isExpanded: true,
                style: const TextStyle(color: Colors.white),
                items: const [
                  DropdownMenuItem(value: "BOTH", child: Text("All Registered Users")),
                  DropdownMenuItem(value: "CUSTOMER", child: Text("Customers Only")),
                  DropdownMenuItem(value: "MERCHANT", child: Text("Merchants Only")),
                ],
                onChanged: (val) => setState(() => _target = val!),
              ),
            ),
          ),
          
          const SizedBox(height: 20),
          const Text("Notification Title", style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextField(
            controller: _titleController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: "Enter a catchy title",
              hintStyle: const TextStyle(color: Colors.white24),
              filled: true,
              fillColor: Colors.white.withOpacity(0.05),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
            onChanged: (_) => setState(() {}),
          ),
          
          const SizedBox(height: 20),
          const Text("Detailed Message", style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextField(
            controller: _messageController,
            maxLines: 5,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: "What do you want to announce?",
              hintStyle: const TextStyle(color: Colors.white24),
              filled: true,
              fillColor: Colors.white.withOpacity(0.05),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
            onChanged: (_) => setState(() {}),
          ),
          
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: () async {
                if (_titleController.text.isEmpty || _messageController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please fill all fields")));
                  return;
                }
                try {
                  await state.sendNotification(_target, _titleController.text, _messageController.text);
                  _titleController.clear();
                  _messageController.clear();
                  setState(() {});
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Announcement broadcasted successfully!")));
                  _loadSentAnnouncements();
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.amber,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: const Text("Broadcast Announcement", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreview(AppState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Preview", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.amber.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.notifications_active, color: AppColors.amber, size: 18),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Platform Update", style: TextStyle(color: Colors.white30, fontSize: 10, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                        Text("NOW", style: TextStyle(color: Colors.white30, fontSize: 8)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                _titleController.text.isEmpty ? "Announcement Title" : _titleController.text,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 4),
              Text(
                _messageController.text.isEmpty ? "Your message will appear here..." : _messageController.text,
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        const Text("Recent Activity", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 16),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: state.adminActivity.where((a) => a.action.contains("notification")).length,
          itemBuilder: (context, index) {
            final activity = state.adminActivity.where((a) => a.action.contains("notification")).toList()[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.02),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_outline, color: Colors.green, size: 16),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(activity.action, style: const TextStyle(fontSize: 11, color: Colors.white70)),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildHistorySection(AppState state) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Broadcast History", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              if (_loadingHistory)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(color: AppColors.amber, strokeWidth: 2),
                ),
            ],
          ),
          const SizedBox(height: 24),
          if (!_loadingHistory && _sentAnnouncements.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Text("No announcements sent yet.", style: TextStyle(color: Colors.white30)),
              ),
            ),
          if (_sentAnnouncements.isNotEmpty)
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _sentAnnouncements.length,
              itemBuilder: (context, index) {
                final a = _sentAnnouncements[index];
                final id = a['id'] ?? 0;
                final title = a['title'] ?? 'No Title';
                final message = a['message'] ?? '';
                final target = a['target'] ?? 'BOTH';
                final isAuto = a['is_auto'] ?? false;
                
                Color targetColor;
                String targetText;
                if (target == 'CUSTOMER') {
                  targetColor = Colors.blueAccent;
                  targetText = 'Customers';
                } else if (target == 'MERCHANT') {
                  targetColor = Colors.greenAccent;
                  targetText = 'Merchants';
                } else {
                  targetColor = AppColors.amber;
                  targetText = 'All Users';
                }

                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.02),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withOpacity(0.02)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: targetColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          isAuto ? Icons.auto_awesome : Icons.campaign,
                          color: targetColor,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    title,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: targetColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    targetText.toUpperCase(),
                                    style: TextStyle(color: targetColor, fontSize: 9, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              message,
                              style: const TextStyle(color: Colors.white60, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                        onPressed: () async {
                          bool? confirm = await showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              backgroundColor: const Color(0xFF1A1A2E),
                              title: const Text("Delete Announcement?"),
                              content: const Text("Are you sure you want to delete this announcement? This cannot be undone."),
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
                              await state.deleteAnnouncement(id);
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Announcement deleted successfully")));
                              _loadSentAnnouncements();
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
                            }
                          }
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
