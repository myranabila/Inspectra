import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import 'package:intl/intl.dart';

class PerformanceBarChart extends StatelessWidget {
  final int completed;
  final int scheduled;

  const PerformanceBarChart({
    super.key,
    required this.completed,
    required this.scheduled,
  });

  @override
  Widget build(BuildContext context) {
    if (completed == 0 && scheduled == 0) {
      return Center(
        child: Text(
          'No data available',
          style: GoogleFonts.inter(color: Colors.grey),
        ),
      );
    }

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: (completed > scheduled ? completed : scheduled).toDouble() + 2,
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
             getTooltipColor: (group) => AppTheme.accentYellow, // Customize tooltip color
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                const style = TextStyle(
                  color: Color(0xff7589a2),
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                );
                String text;
                switch (value.toInt()) {
                  case 0:
                    text = 'Completed';
                    break;
                  case 1:
                    text = 'Scheduled';
                    break;
                  default:
                    text = '';
                }
                return Text(text, style: style);
              },
              reservedSize: 30,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toInt().toString(),
                  style: const TextStyle(
                    color: Color(0xff7589a2),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                );
              },
              interval: 1, // Ensure integer steps
            ),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        gridData: const FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 1,
        ),
        borderData: FlBorderData(
          show: false,
        ),
        barGroups: [
          BarChartGroupData(
            x: 0,
            barRods: [
              BarChartRodData(
                toY: completed.toDouble(),
                color: AppTheme.statusCompleted,
                width: 22,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(6),
                  topRight: Radius.circular(6),
                ),
              ),
            ],
          ),
          BarChartGroupData(
            x: 1,
            barRods: [
              BarChartRodData(
                toY: scheduled.toDouble(),
                color: AppTheme.statusScheduled,
                width: 22,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(6),
                  topRight: Radius.circular(6),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class StatusPieChart extends StatelessWidget {
  final int completed;
  final int pending;
  final int scheduled;

  const StatusPieChart({
    super.key,
    required this.completed,
    required this.pending,
    required this.scheduled,
  });

  @override
  Widget build(BuildContext context) {
    if (completed == 0 && pending == 0 && scheduled == 0) {
      return Center(
        child: Text(
          'No data available',
          style: GoogleFonts.inter(color: Colors.grey),
        ),
      );
    }
    
    return PieChart(
      PieChartData(
        sectionsSpace: 2,
        centerSpaceRadius: 40,
        sections: [
          if (completed > 0)
            PieChartSectionData(
              color: AppTheme.statusCompleted,
              value: completed.toDouble(),
              title: '${completed}',
              radius: 50,
              titleStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          if (pending > 0)
            PieChartSectionData(
              color: AppTheme.statusPendingReview,
              value: pending.toDouble(),
              title: '${pending}',
              radius: 50,
              titleStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          if (scheduled > 0)
            PieChartSectionData(
              color: AppTheme.statusScheduled,
              value: scheduled.toDouble(),
              title: '${scheduled}',
              radius: 50,
              titleStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
        ],
      ),
    );
  }
}

class ActivityListTile extends StatelessWidget {
  final Map<String, dynamic> activity;

  const ActivityListTile({super.key, required this.activity});

  @override
  Widget build(BuildContext context) {
    final status = activity['status'];
    Color iconColor;
    IconData iconData;

    switch (status) {
      case 'completed':
        iconColor = AppTheme.statusCompleted;
        iconData = Icons.check_circle_outline;
        break;
      case 'scheduled':
        iconColor = AppTheme.statusScheduled;
        iconData = Icons.schedule;
        break;
      case 'pending_review':
        iconColor = AppTheme.statusPendingReview;
        iconData = Icons.hourglass_empty;
        break;
      default:
        iconColor = Colors.grey;
        iconData = Icons.info_outline;
    }

    final timestamp = activity['timestamp'];
    String timeText = '';
    if (timestamp != null) {
        try {
            final date = DateTime.parse(timestamp);
            timeText = DateFormat('MMM d, h:mm a').format(date);
        } catch (_) {
            timeText = 'Just now';
        }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(iconData, color: iconColor, size: 20),
        ),
        title: Text(
          activity['title'] ?? 'Activity',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: AppTheme.textPrimary,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              activity['subtitle'] ?? activity['action'] ?? '',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              timeText,
              style: GoogleFonts.inter(
                fontSize: 10,
                color: AppTheme.textSecondary.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
        trailing: Icon(
          Icons.chevron_right_rounded,
          color: Colors.grey.shade400,
          size: 20,
        ),
      ),
    );
  }
}
