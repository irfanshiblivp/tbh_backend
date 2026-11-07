import 'package:flutter/material.dart';
import '../../models/models.dart';
import 'package:intl/intl.dart';

class ActivityFeed extends StatelessWidget {
  final List<AdminLog> logs;
  const ActivityFeed({super.key, required this.logs});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Recent Activity", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 20),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: logs.length,
          itemBuilder: (context, index) {
            final log = logs[index];
            return _buildActivityItem(log);
          },
        ),
      ],
    );
  }

  Widget _buildActivityItem(AdminLog log) {
    IconData icon;
    Color color;
    
    if (log.action.contains("Blocked") || log.action.contains("Failed")) {
      icon = Icons.block;
      color = Colors.red;
    } else if (log.action.contains("Created") || log.action.contains("Received") || log.action.contains("Redeemed")) {
      icon = Icons.check_circle;
      color = Colors.green;
    } else if (log.action.contains("Pending")) {
      icon = Icons.hourglass_empty;
      color = Colors.amber;
    } else {
      icon = Icons.history;
      color = Colors.blue;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(log.action, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
                Text(
                  DateFormat('HH:mm - MMM d').format(log.timestamp),
                  style: const TextStyle(color: Colors.white30, fontSize: 11),
                ),
              ],
            ),
          ),
          Text(log.adminName, style: const TextStyle(color: Colors.white24, fontSize: 11)),
        ],
      ),
    );
  }
}
