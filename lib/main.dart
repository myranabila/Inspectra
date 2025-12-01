// Main.dart
import 'package:flutter/material.dart';
import 'login_page.dart';
import 'signup_page.dart';
import 'dashboard_page.dart';
import 'job_management_page.dart';
import 'report_review_page.dart';

void main() {
  runApp(const WorkshopApp());
}

class WorkshopApp extends StatelessWidget {
  const WorkshopApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Workshop Desktop App",
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xffe6e6e6),
        fontFamily: 'Arial',
      ),

      initialRoute: '/login',

      routes: {
        // Login Page
        '/login': (context) => const LoginPage(),

        // Signup Page
        '/signup': (context) => SignUpPage(
          onBackToLogin: () {
            Navigator.pushReplacementNamed(context, '/login');
          },
        ),

        // Dashboard Page
        '/dashboard': (context) => const DashboardModule(),

        // Job Management Page
        '/jobs': (context) => const InspectionJobModule(),

        // FIXED — Now this works
        '/review': (context) => const ReportReviewPage(),

        // Placeholder routes
        //'/repository': (context) =>
        //const PlaceholderPage(title: "Report Repository"),
        //'/maintenance': (context) =>
        //const PlaceholderPage(title: "Maintenance Tasks"),
        //'/analytics': (context) =>
        //const PlaceholderPage(title: "Analytics & Reports"),
        //'/notifications': (context) =>
        //const PlaceholderPage(title: "Notifications"),

        // Logout
        '/logout': (context) => const LoginPage(),
      },
    );
  }
}

// Temporary placeholder widget
class PlaceholderPage extends StatelessWidget {
  final String title;

  const PlaceholderPage({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Colors.grey.shade800,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Text(
          "$title Page Coming Soon",
          style: const TextStyle(fontSize: 22),
        ),
      ),
    );
  }
}
