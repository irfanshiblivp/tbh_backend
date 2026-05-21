import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/app_theme.dart';

class AnalyticsSection extends StatelessWidget {
  final Map<String, dynamic>? data;
  const AnalyticsSection({super.key, this.data});

  @override
  Widget build(BuildContext context) {
    if (data == null) return const Center(child: CircularProgressIndicator());

    final revenueOverTime = (data!['revenue_over_time'] as List? ?? []);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(child: Text("Revenue Overview", style: GoogleFonts.dmSans(fontSize: 18, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)),
            const SizedBox(width: 8),
            _buildDateFilter(),
          ],
        ),
        const SizedBox(height: 20),
        Container(
          height: 300,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: LineChart(_buildRevenueChart(revenueOverTime)),
        ),
      ],
    );
  }

  Widget _buildDateFilter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: const [
          Text("Last 30 Days", style: TextStyle(color: Colors.white54, fontSize: 12)),
          Icon(Icons.keyboard_arrow_down, color: Colors.white54, size: 16),
        ],
      ),
    );
  }


  LineChartData _buildRevenueChart(List revenueData) {
    return LineChartData(
      gridData: FlGridData(show: false),
      titlesData: FlTitlesData(show: false),
      borderData: FlBorderData(show: false),
      lineBarsData: [
        LineChartBarData(
          spots: revenueData.asMap().entries.map((e) => FlSpot(e.key.toDouble(), (e.value['value'] as num).toDouble())).toList(),
          isCurved: true,
          color: AppColors.amber,
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: FlDotData(show: false),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              colors: [AppColors.amber.withOpacity(0.3), AppColors.amber.withOpacity(0)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ],
    );
  }
}
