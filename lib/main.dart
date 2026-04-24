// lib/main.dart
import 'package:flutter/material.dart';
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

  final dbHelper = DatabaseHelper();
  await dbHelper.database;

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>(create: (_) => AuthProvider()),
        ChangeNotifierProvider<DashboardProvider>(create: (_) => DashboardProvider()),
        ChangeNotifierProvider<DepartmentProvider>(create: (_) => DepartmentProvider()),
        ChangeNotifierProvider<TeacherProvider>(create: (_) => TeacherProvider()),
        ChangeNotifierProvider<BatchProvider>(create: (_) => BatchProvider()),
        ChangeNotifierProvider<RoutineProvider>(create: (_) => RoutineProvider()),
        ChangeNotifierProvider<CourseProvider>(create: (_) => CourseProvider()),
        ChangeNotifierProvider<RoomProvider>(create: (_) => RoomProvider()),
        ChangeNotifierProvider<MergeProvider>(create: (_) => MergeProvider()),
        ChangeNotifierProvider<SettingsProvider>(create: (_) => SettingsProvider()),
        ChangeNotifierProvider<ThemeProvider>(create: (_) => ThemeProvider()),
        ChangeNotifierProvider<ProfileProvider>(create: (_) => ProfileProvider()),
      ],
      child: MaterialApp(
        title: 'SAS',  // ← Changed to SAS
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.blue,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF1976D2),
          ),
          useMaterial3: true,
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
}