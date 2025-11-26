import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'firebase_options.dart'; 
import 'providers/inspector_provider.dart';
import 'router.dart'; // <-- NEW: Import the GoRouter instance
// Note: DashboardScreen, ProfileScreen, UploadScreen are now implicitly used by router.dart

// main.dart

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // ignore: avoid_print
  print('-------- USER UID: ${FirebaseAuth.instance.currentUser?.uid}');

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => InspectorProvider(), // ← share user doc everywhere
      child: MaterialApp.router( // <-- CHANGED TO MaterialApp.router
        title: 'ProjectWS Inspector UI',
        theme: ThemeData(
          textTheme: GoogleFonts.robotoCondensedTextTheme(
            Theme.of(context).textTheme,
          ),
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
        ),
        routerConfig: router, // <-- NEW: Use the GoRouter instance
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}