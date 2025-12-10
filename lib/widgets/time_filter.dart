import 'package:flutter/material.dart';

enum TimeFilterPeriod { all, year, month, week, day }

extension TimeFilterPeriodExtension on TimeFilterPeriod {
  String toShortString() {
    return toString().split('.').last;
  }

  String get displayName {
    switch (this) {
      case TimeFilterPeriod.all: return 'All Time';
      case TimeFilterPeriod.year: return 'This Year';
      case TimeFilterPeriod.month: return 'This Month';
      case TimeFilterPeriod.week: return 'This Week';
      case TimeFilterPeriod.day: return 'Today';
    }
  }
}

class TimeFilter extends StatelessWidget {
  final TimeFilterPeriod selectedPeriod;
  final Function(TimeFilterPeriod) onPeriodSelected;

  const TimeFilter({
    super.key,
    required this.selectedPeriod,
    required this.onPeriodSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: TimeFilterPeriod.values.map((period) {
          final isSelected = period == selectedPeriod;
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: FilterChip(
              label: Text(
                period.displayName,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.black87,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  onPeriodSelected(period);
                }
              },
              backgroundColor: Colors.white,
              selectedColor: Theme.of(context).primaryColor,
              checkmarkColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}