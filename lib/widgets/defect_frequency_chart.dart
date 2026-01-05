import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class DefectFrequencyChart extends StatelessWidget {
  final List<dynamic> data;

  const DefectFrequencyChart({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const Center(
        child: Text(
          'No analytics data available',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    // =====================================================
    // GROUP DATA: Equipment -> Defect Type -> Count
    // =====================================================
    final Map<String, Map<String, int>> grouped = {};

    for (final row in data) {
      final equipment = (row['equipment_type'] ?? 'Unknown').toString();
      final defect = (row['defect_type'] ?? 'Unknown').toString();
      final count = row['count'] as int? ?? 0;

      grouped.putIfAbsent(equipment, () => {});
      grouped[equipment]![defect] =
          (grouped[equipment]![defect] ?? 0) + count;
    }

    final equipmentTypes = grouped.keys.toList();

    // Max Y = highest total defects for one equipment
    final maxValue = grouped.values
        .map((defects) => defects.values.fold<int>(0, (a, b) => a + b))
        .fold<int>(0, (a, b) => a > b ? a : b);

    // =====================================================
    // BUILD CHART
    // =====================================================
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxValue.toDouble() + 1,
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final equipment = equipmentTypes[group.x.toInt()];
              final defects = grouped[equipment]!;

              final tooltipText = defects.entries
                  .map((e) => '${e.key}: ${e.value}')
                  .join('\n');

              return BarTooltipItem(
                '$equipment\n$tooltipText',
                const TextStyle(color: Colors.white, fontSize: 12),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= equipmentTypes.length) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    equipmentTypes[index],
                    style: const TextStyle(fontSize: 11),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: true, reservedSize: 32),
          ),
          rightTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        gridData: FlGridData(
          show: true,
          horizontalInterval: 1,
          getDrawingHorizontalLine: (value) =>
              FlLine(color: Colors.grey.shade300, strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),

        // =====================================================
        // STACKED BARS
        // =====================================================
        barGroups: List.generate(equipmentTypes.length, (index) {
          final equipment = equipmentTypes[index];
          final defects = grouped[equipment]!;

          double runningTotal = 0;

          final stackItems = defects.entries.map((entry) {
            final fromY = runningTotal;
            final toY = runningTotal + entry.value;
            runningTotal = toY;

            return BarChartRodStackItem(
              fromY,
              toY,
              _defectColor(entry.key),
            );
          }).toList();

          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: runningTotal,
                rodStackItems: stackItems,
                width: 22,
                borderRadius: BorderRadius.circular(6),
              ),
            ],
          );
        }),
      ),
    );
  }

  // =====================================================
  // DEFECT COLOR MAPPING
  // =====================================================
  Color _defectColor(String defect) {
    switch (defect) {
      case 'Corrosion':
        return Colors.orange;
      case 'Crack':
        return Colors.red;
      case 'Leakage':
        return Colors.blue;
      case 'Mechanical Damage':
        return Colors.purple;
      case 'Other':
        return Colors.grey;
      default:
        return Colors.black;
    }
  }
}
