import 'package:flutter/material.dart';
import '../data/repositories/teacher_repository.dart';
import '../data/models/teacher_model.dart';

class AuthProvider extends ChangeNotifier {
  final TeacherRepository _teacherRepo = TeacherRepository();

  Map<String, dynamic>? _currentUser;
  bool _isLoading = false;
  String? _error;

  // Getters
  Map<String, dynamic>? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAdmin => _currentUser?['role'] == 'admin';
  bool get isTeacher => _currentUser?['role'] == 'teacher';

  // Login
  Future<bool> login(String username, String password, String role) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      print('🔑 Login attempt: $username as $role');

      // Special case for admin
      if (role == 'admin' && username == 'admin' && password == 'admin123') {
        _currentUser = {
          'id': 0,
          'name': 'Admin User',
          'username': 'admin',
          'role': 'admin',
          'email': 'admin@university.edu',
        };
        print('✅ Admin login successful');
        _isLoading = false;
        notifyListeners();
        return true;
      }

      // Teacher login
      final teacher = await _teacherRepo.getTeacherByUsername(username);

      if (teacher != null) {
        print('📚 Teacher found: ${teacher.name}, ID: ${teacher.id}');

        if (teacher.password == password && teacher.role == role) {
          _currentUser = {
            'id': teacher.id,
            'name': teacher.name,
            'username': teacher.username,
            'role': teacher.role,
            'email': '${teacher.username}@university.edu',
          };
          print('✅ Teacher login successful, ID: ${teacher.id}');
          _isLoading = false;
          notifyListeners();
          return true;
        } else {
          print('❌ Password mismatch');
          _error = 'Invalid password';
        }
      } else {
        print('❌ Teacher not found');
        _error = 'User not found';
      }

      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      print('❌ Login error: $e');
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ========== NEW: Change Password Method ==========
  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      print('🔑 Changing password for user: ${_currentUser?['username']}');

      // Validate current user
      if (_currentUser == null) {
        _error = 'No user logged in';
        return false;
      }

      // For admin (special case)
      if (_currentUser?['role'] == 'admin') {
        // In a real app, you would verify admin password here
        // For now, just accept any password for demo
        print('✅ Admin password changed successfully');
        _isLoading = false;
        notifyListeners();
        return true;
      }

      // For teacher
      if (_currentUser?['role'] == 'teacher') {
        final teacherId = _currentUser?['id'];
        if (teacherId == null) {
          _error = 'Teacher ID not found';
          return false;
        }

        // Get teacher from database
        final teacher = await _teacherRepo.getTeacherById(teacherId);

        if (teacher == null) {
          _error = 'Teacher not found';
          return false;
        }

        // Verify current password
        if (teacher.password != currentPassword) {
          _error = 'Current password is incorrect';
          return false;
        }

        // Update password in database using existing resetPassword method
        final success = await _teacherRepo.resetPassword(teacherId, newPassword);

        if (success) {
          print('✅ Teacher password changed successfully');
          _isLoading = false;
          notifyListeners();
          return true;
        } else {
          _error = 'Failed to update password';
          return false;
        }
      }

      _error = 'Invalid user role';
      return false;
    } catch (e) {
      print('❌ Password change error: $e');
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Logout
  void logout() {
    _currentUser = null;
    notifyListeners();
  }
}