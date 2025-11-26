

import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';


import 'dashboard_screen.dart';
import 'profile_screen.dart'; 
import 'upload_screen.dart'; 


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


final router = GoRouter(
  initialLocation: '/',
  routes: [
    
    GoRoute(
      path: '/', 
      builder: (_, __) => const DashboardScreen(),
    ),
    
    GoRoute(
      path: '/profile', 
      builder: (_, __) => const ProfileScreen(),
      routes: [
        
        GoRoute(
          path: 'edit',
          builder: (_, __) => const EditProfilePlaceholderScreen(), 
        ),
      ],
    ),
    
    GoRoute(
      path: '/upload', 
      builder: (_, __) => const UploadScreen(),
    ),
    
    GoRoute(
      path: '/jobs',
      
      builder: (_, __) => const DashboardScreen(), 
    ),
  ],
);
