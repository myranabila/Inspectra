import 'package:flutter/material.dart';
import 'theme/app_theme.dart';

class InspectionJobModule extends StatelessWidget {
  const InspectionJobModule({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Job Management'),
        backgroundColor: AppTheme.managerPrimary,
      ),
      body: const Center(child: Text('Job Management Placeholder')),
    );
  }
}