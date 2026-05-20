import 'package:flutter/material.dart';
import '../data/repositories/teacher_repository.dart';
import '../data/repositories/department_repository.dart';
import '../data/models/teacher_model.dart';
import '../data/models/course_model.dart';
import '../data/models/department_model.dart';

class TeacherProvider extends ChangeNotifier {
  final TeacherRepository _repository = TeacherRepository();
  final DepartmentRepository _deptRepository = DepartmentRepository();

  List<Teacher> _teachers = [];
  List<Department> _departments = [];
  List<Course> _availableCourses = [];
  bool _isLoading = false;
  String? _error;
  bool _isSearching = false;
  List<Teacher> _searchResults = [];
  Department? _selectedDepartment;

  // Getters
  List<Teacher> get teachers => _isSearching ? _searchResults : _teachers;
  List<Department> get departments => _departments;
  List<Course> get availableCourses => _availableCourses;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isSearching => _isSearching;
  int get totalTeachers => _teachers.length;
  Department? get selectedDepartment => _selectedDepartment;

  // Load all teachers
  Future<void> loadTeachers() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _teachers = await _repository.getAllTeachers();
      print('✅ Loaded ${_teachers.length} teachers');
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      print('❌ Error loading teachers: $e');
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load departments for dropdown
  Future<void> loadDepartments() async {
    try {
      _departments = await _deptRepository.getAllDepartments();
      notifyListeners();
    } catch (e) {
      print('❌ Error loading departments: $e');
    }
  }

  // Load courses by department (for interested courses)
  Future<void> loadCoursesByDepartment(int departmentId) async {
    _isLoading = true;
    notifyListeners();

    try {
      _availableCourses = await _repository.getCoursesByDepartment(departmentId);
      print('✅ Loaded ${_availableCourses.length} courses for department $departmentId');
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      print('❌ Error loading courses: $e');
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Add new teacher (Admin creates)
  Future<bool> addTeacher(Teacher teacher) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Check if username exists
      bool exists = await _repository.isUsernameExists(teacher.username);
      if (exists) {
        _error = 'Username already exists';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      int id = await _repository.addTeacher(teacher);
      if (id > 0) {
        print('✅ Teacher added with ID: $id');
        await loadTeachers();
        return true;
      } else {
        _error = 'Failed to add teacher';
        return false;
      }
    } catch (e) {
      print('❌ Error adding teacher: $e');
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // FIXED: Update teacher profile
  Future<bool> updateTeacher(Teacher teacher) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      print('🔄 Updating teacher: ${teacher.id} - ${teacher.name}');

      // Check if username exists (excluding current teacher)
      bool exists = await _repository.isUsernameExists(
        teacher.username,
        excludeId: teacher.id,
      );
      if (exists) {
        _error = 'Username already exists';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      int rowsAffected = await _repository.updateTeacher(teacher);
      print('✅ Update result: $rowsAffected rows affected');

      if (rowsAffected > 0) {
        await loadTeachers();
        return true;
      } else {
        _error = 'Failed to update teacher';
        return false;
      }
    } catch (e) {
      print('❌ Error updating teacher: $e');
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Complete profile after first login
  Future<bool> completeProfile(Teacher teacher) async {
    Teacher updatedTeacher = Teacher(
      id: teacher.id,
      name: teacher.name,
      shortName: teacher.shortName,
      username: teacher.username,
      password: teacher.password,
      phone: teacher.phone,
      departmentId: teacher.departmentId,
      role: teacher.role,
      interestedCourses: teacher.interestedCourses,
      availableDays: teacher.availableDays,
      availableSlots: teacher.availableSlots,
      maxLoad: teacher.maxLoad,
      isProfileCompleted: true,
    );
    return await updateTeacher(updatedTeacher);
  }

  // Delete teacher
  Future<bool> deleteTeacher(int id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      print('🗑️ Deleting teacher ID: $id');
      int rowsAffected = await _repository.deleteTeacher(id);
      print('✅ Delete result: $rowsAffected');

      if (rowsAffected > 0) {
        await loadTeachers();
        return true;
      } else {
        _error = 'Failed to delete teacher';
        return false;
      }
    } catch (e) {
      print('❌ Error deleting teacher: $e');
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Reset password
  Future<bool> resetPassword(int teacherId, String newPassword) async {
    try {
      bool success = await _repository.resetPassword(teacherId, newPassword);
      if (success) {
        print('✅ Password reset for teacher ID: $teacherId');
      }
      return success;
    } catch (e) {
      print('❌ Error resetting password: $e');
      _error = e.toString();
      return false;
    }
  }

  // Search teachers
  void searchTeachers(String query) {
    if (query.isEmpty) {
      _isSearching = false;
      _searchResults = [];
    } else {
      _isSearching = true;
      _searchResults = _teachers.where((teacher) =>
      teacher.name.toLowerCase().contains(query.toLowerCase()) ||
          teacher.shortName.toLowerCase().contains(query.toLowerCase()) ||
          teacher.username.toLowerCase().contains(query.toLowerCase())
      ).toList();
    }
    notifyListeners();
  }

  // Filter teachers by department
  void filterByDepartment(int? departmentId) {
    if (departmentId == null) {
      _isSearching = false;
      _searchResults = [];
    } else {
      _isSearching = true;
      _searchResults = _teachers.where((teacher) =>
      teacher.departmentId == departmentId
      ).toList();
    }
    notifyListeners();
  }

  // Clear search/filter
  void clearFilter() {
    _isSearching = false;
    _searchResults = [];
    _selectedDepartment = null;
    notifyListeners();
  }

  // Get teacher by id
  Teacher? getTeacherById(int id) {
    try {
      return _teachers.firstWhere((teacher) => teacher.id == id);
    } catch (e) {
      return null;
    }
  }

  // Get teachers by department
  List<Teacher> getTeachersByDepartment(int departmentId) {
    return _teachers.where((teacher) => teacher.departmentId == departmentId).toList();
  }

  // Refresh data
  Future<void> refresh() async {
    await loadTeachers();
  }
}