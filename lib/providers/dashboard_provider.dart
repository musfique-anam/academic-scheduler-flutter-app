import 'package:flutter/material.dart';
import '../data/services/database_helper.dart';

class DashboardProvider extends ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  // Statistics
  int totalDepartments = 0;
  int totalTeachers = 0;
  int totalBatches = 0;
  int totalStudents = 1250;
  int totalCourses = 0;
  int totalRooms = 0;
  int activeClasses = 12;
  int todayRoutines = 8;

  // Notifications
  bool hasUnreadNotifications = true;
  int unreadCount = 3;

  // Today's info
  int todayClasses = 8;
  int pendingTasks = 3;

  // Recent Activities
  List<Map<String, dynamic>> recentActivities = [
    {
      'title': 'New batch added',
      'time': '5 minutes ago',
      'status': 'Completed',
      'icon': Icons.group_add,
      'color': Colors.green,
    },
    {
      'title': 'Routine generated for CSE',
      'time': '1 hour ago',
      'status': 'Success',
      'icon': Icons.schedule,
      'color': Colors.blue,
    },
    {
      'title': 'Teacher assignment updated',
      'time': '2 hours ago',
      'status': 'Pending',
      'icon': Icons.person,
      'color': Colors.orange,
    },
    {
      'title': 'Room merged for merged class',
      'time': '3 hours ago',
      'status': 'Completed',
      'icon': Icons.merge_type,
      'color': Colors.purple,
    },
    {
      'title': 'New department added',
      'time': '5 hours ago',
      'status': 'Completed',
      'icon': Icons.business,
      'color': Colors.teal,
    },
  ];

  DashboardProvider() {
    refreshDashboard(); // Auto-load when provider created
  }

  // Refresh all dashboard data from database
  Future<void> refreshDashboard() async {
    await _loadDepartmentCount();
    await _loadTeacherCount();
    await _loadBatchCount();
    await _loadCourseCount();
    await _loadRoomCount();

    notifyListeners();
  }

  Future<void> _loadDepartmentCount() async {
    try {
      totalDepartments = await _dbHelper.getCount('departments');
    } catch (e) {
      debugPrint('Error loading department count: $e');
    }
  }

  Future<void> _loadTeacherCount() async {
    try {
      totalTeachers = await _dbHelper.getCount('teachers');
    } catch (e) {
      debugPrint('Error loading teacher count: $e');
    }
  }

  Future<void> _loadBatchCount() async {
    try {
      totalBatches = await _dbHelper.getCount('batches');
    } catch (e) {
      debugPrint('Error loading batch count: $e');
    }
  }

  Future<void> _loadCourseCount() async {
    try {
      totalCourses = await _dbHelper.getCount('courses');
    } catch (e) {
      debugPrint('Error loading course count: $e');
    }
  }

  Future<void> _loadRoomCount() async {
    try {
      totalRooms = await _dbHelper.getCount('rooms');
    } catch (e) {
      debugPrint('Error loading room count: $e');
    }
  }

  void markNotificationsAsRead() {
    hasUnreadNotifications = false;
    unreadCount = 0;
    notifyListeners();
  }

  void addRecentActivity(String title, IconData icon, Color color) {
    recentActivities.insert(0, {
      'title': title,
      'time': 'Just now',
      'status': 'New',
      'icon': icon,
      'color': color,
    });

    if (recentActivities.length > 10) {
      recentActivities.removeLast();
    }

    hasUnreadNotifications = true;
    unreadCount++;
    notifyListeners();
  }
}