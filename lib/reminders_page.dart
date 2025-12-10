import 'package:flutter/material.dart';
import 'theme/app_theme.dart';

class RemindersPage extends StatelessWidget {
  const RemindersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reminders'),
        backgroundColor: AppTheme.inspectorPrimary,
      ),
      body: const Center(child: Text('Reminders List Placeholder')),
    );
  }
}