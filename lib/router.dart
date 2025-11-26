// lib/router.dart

import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';

// Ensure these imports correctly point to your screen files
import 'dashboard_screen.dart';
import 'profile_screen.dart'; 
import 'upload_screen.dart'; 

// --- Temporary Edit Screen Placeholder ---
// In a real app, this would be EditProfileScreen
class EditProfilePlaceholderScreen extends StatelessWidget {
  const EditProfilePlaceholderScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body: const Center(child: Text('Edit Profile Form Goes Here')),
    );
  }
}
// ------------------------------------------

final router = GoRouter(
  initialLocation: '/',
  routes: [
    // Dashboard Route (Home page)
    GoRoute(
      path: '/', 
      builder: (_, __) => const DashboardScreen(),
    ),
    // Profile Route (Parent Route)
    GoRoute(
      path: '/profile', 
      builder: (_, __) => const ProfileScreen(),
      routes: [
        // Nested Edit Route
        GoRoute(
          path: 'edit',
          builder: (_, __) => const EditProfilePlaceholderScreen(), // Placeholder
        ),
      ],
    ),
    // Media Manager/Upload Route
    GoRoute(
      path: '/upload', 
      builder: (_, __) => const UploadScreen(),
    ),
    // Inspection Jobs Route (Next planned feature)
    GoRoute(
      path: '/jobs',
      // NOTE: Placeholder for the InspectionJobsScreen you will create next
      builder: (_, __) => const DashboardScreen(), 
    ),
  ],
);