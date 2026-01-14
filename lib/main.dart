// Main.dart
import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:google_fonts/google_fonts.dart';
import 'login_page.dart';
import 'dashboard_page.dart';
import 'manager_dashboard_page.dart';
import 'job_management_page.dart';
import 'report_review_page.dart';
import 'history_page.dart';
import 'my_tasks_page.dart';
import 'threads_list_page.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const WorkshopApp());
}

class WorkshopApp extends StatelessWidget {
  const WorkshopApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Use Google Fonts Inter for a professional look
    final textTheme = GoogleFonts.interTextTheme(
      Theme.of(context).textTheme,
    );

    return MaterialApp(
      title: "iPETRO - Inspection Management System",
      debugShowCheckedModeBanner: false,
      scrollBehavior: const MaterialScrollBehavior().copyWith(
        dragDevices: {
          PointerDeviceKind.mouse,
          PointerDeviceKind.touch,
          PointerDeviceKind.stylus,
          PointerDeviceKind.trackpad,
        },
      ),
      theme: ThemeData(
        useMaterial3: true,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        splashFactory: InkRipple.splashFactory,
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: ZoomPageTransitionsBuilder(),
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
            TargetPlatform.windows: ZoomPageTransitionsBuilder(),
            TargetPlatform.macOS: ZoomPageTransitionsBuilder(),
            TargetPlatform.linux: ZoomPageTransitionsBuilder(),
          },
        ),
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppTheme.primaryRed,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: AppTheme.backgroundGrey,
        textTheme: textTheme,
        appBarTheme: AppBarTheme(
          elevation: 0,
          centerTitle: false,
          backgroundColor: AppTheme.primaryRed,
          foregroundColor: Colors.white,
          titleTextStyle: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
            letterSpacing: -0.2,
          ),
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: AppTheme.radiusLG,
            side: BorderSide(
              color: AppTheme.divider.withValues(alpha: 0.5),
            ),
          ),
          color: AppTheme.surfaceWhite,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: AppTheme.primaryButton,
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: AppTheme.outlinedButton,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFF1F5F9),
          border: OutlineInputBorder(
            borderRadius: AppTheme.radiusMD,
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: AppTheme.radiusMD,
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: AppTheme.radiusMD,
            borderSide: const BorderSide(
              color: AppTheme.primaryRed,
              width: 2,
            ),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 18,
          ),
          labelStyle: GoogleFonts.inter(
            color: AppTheme.textSecondary,
          ),
        ),
        dividerTheme: DividerThemeData(
          color: AppTheme.divider,
          thickness: 1,
        ),
        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: AppTheme.radiusMD,
          ),
        ),
        dialogTheme: DialogThemeData(
          shape: RoundedRectangleBorder(
            borderRadius: AppTheme.radiusXL,
          ),
        ),
        bottomSheetTheme: BottomSheetThemeData(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(24),
            ),
          ),
        ),
        progressIndicatorTheme: const ProgressIndicatorThemeData(
          color: AppTheme.primaryRed,
          linearTrackColor: Colors.transparent,
          circularTrackColor: Colors.transparent,
        ),
      ),

      initialRoute: '/login',

      routes: {
        // Login Page
        '/login': (context) => const LoginPage(),

        // Dashboard Page
        '/dashboard': (context) => const DashboardModule(),
        
        // Manager Dashboard Page
        '/manager-dashboard': (context) => const ManagerDashboardPage(),

        // Job Management Page
        '/jobs': (context) => const InspectionJobModule(),

        // Report Review Page
        '/review': (context) => const ReportReviewPage(),

        // History Page
        '/history': (context) => const HistoryPage(),

        // My Tasks Page (Inspector)
        '/my-tasks': (context) => const MyTasksPage(),

        // Threads / Messages Page
        '/messages': (context) => const ThreadsListPage(),

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
        backgroundColor: AppTheme.primaryRed,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.construction_rounded,
              size: 64,
              color: AppTheme.textMuted,
            ),
            const SizedBox(height: 16),
            Text(
              "$title Coming Soon",
              style: AppTheme.headingMedium,
            ),
            const SizedBox(height: 8),
            Text(
              "This feature is under development",
              style: AppTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
