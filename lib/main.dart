// lib/main.dart - FINAL VERSION

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/dashboard_provider.dart';
import 'providers/department_provider.dart';
import 'providers/teacher_provider.dart';
import 'providers/batch_provider.dart';
import 'providers/course_provider.dart';
import 'providers/routine_provider.dart';
import 'providers/room_provider.dart';
import 'providers/merge_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/profile_provider.dart';
import 'data/services/database_helper.dart';
import 'presentation/screens/splash_screen.dart';
import 'presentation/screens/login_screen.dart';
import 'presentation/screens/admin/admin_dashboard.dart';
import 'presentation/screens/teacher/teacher_dashboard.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize database with error handling
  try {
    final dbHelper = DatabaseHelper();
    final db = await dbHelper.database;

    // Debug-only logging (won't run in release builds)
    if (kDebugMode) {
      final routines = await db.query('routines');
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      debugPrint('📊 DATABASE ROUTINES COUNT: ${routines.length}');
      for (var r in routines) {
        debugPrint(
          ' 📌 ID: ${r['id']} | Type: ${r['type']} | '
          'Course: ${r['courseCode']} | Day: ${r['day']} | Slot: ${r['slot']}',
        );
      }
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    }
  } catch (e, stack) {
    debugPrint('❌ Database initialization error: $e');
    debugPrint('$stack');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => DashboardProvider()),
        ChangeNotifierProvider(create: (_) => DepartmentProvider()),
        ChangeNotifierProvider(create: (_) => TeacherProvider()),
        ChangeNotifierProvider(create: (_) => BatchProvider()),
        ChangeNotifierProvider(create: (_) => RoutineProvider()),
        ChangeNotifierProvider(create: (_) => CourseProvider()),
        ChangeNotifierProvider(create: (_) => RoomProvider()),
        ChangeNotifierProvider(create: (_) => MergeProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => ProfileProvider()),
      ],
      child: MaterialApp(
        title: 'Smart Academic Scheduler',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.blue,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF1976D2),
          ),
          useMaterial3: true,
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF1976D2),
            foregroundColor: Colors.white,
            elevation: 2,
          ),
        ),
        initialRoute: '/',
        routes: {
          '/': (context) => const SplashScreen(),
          '/login': (context) => const LoginScreen(),
          '/admin/dashboard': (context) => const AdminDashboard(),
          '/teacher/dashboard': (context) => const TeacherDashboard(),
        },
      ),
    );
  }
} // ⬅️ THIS WAS MISSING — closes MyApp class