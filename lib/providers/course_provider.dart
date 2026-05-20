import 'package:flutter/material.dart';
import '../data/repositories/course_repository.dart';
import '../data/repositories/batch_repository.dart';
import '../data/repositories/teacher_repository.dart';
import '../data/models/course_model.dart';
import '../data/models/batch_model.dart';
import '../data/models/teacher_model.dart';

class CourseProvider extends ChangeNotifier {
  final CourseRepository _repository = CourseRepository();
  final BatchRepository _batchRepository = BatchRepository();
  final TeacherRepository _teacherRepository = TeacherRepository();

  List<Course> _courses = [];
  List<Batch> _batches = [];
  List<Teacher> _teachers = [];
  bool _isLoading = false;
  String? _error;
  bool _isSearching = false;
  List<Course> _searchResults = [];
  int? _selectedBatchId;
  int? _selectedTeacherId;

  // Getters
  List<Course> get courses => _isSearching ? _searchResults : _courses;
  List<Batch> get batches => _batches;
  List<Teacher> get teachers => _teachers;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isSearching => _isSearching;
  int get totalCourses => _courses.length;
  int? get selectedBatchId => _selectedBatchId;
  int? get selectedTeacherId => _selectedTeacherId;

  // Load all courses
  Future<void> loadCourses() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _courses = await _repository.getAllCourses();

      // Load batches and teachers for display names
      await loadBatches();
      await loadTeachers();

      // Attach batch and teacher names to courses
      for (var course in _courses) {
        final batch = _batches.firstWhere(
              (b) => b.id == course.batchId,
          orElse: () => Batch(
              id: course.batchId,
              departmentId: 0,
              batchNo: 0,
              programType: '',
              totalStudents: 0
          ),
        );
        course.batchName = 'Batch ${batch.batchNo}';

        if (course.teacherId != null) {
          final teacher = _teachers.firstWhere(
                (t) => t.id == course.teacherId,
            orElse: () => Teacher(
              id: course.teacherId!,
              name: 'Unknown',
              shortName: '',
              username: '',
              password: '',
              phone: '',
              departmentId: 0,
            ),
          );
          course.teacherName = teacher.name;
        }
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load batches for dropdown
  Future<void> loadBatches() async {
    try {
      _batches = await _batchRepository.getAllBatches();
    } catch (e) {
      debugPrint('Error loading batches: $e');
    }
  }

  // Load teachers for dropdown
  Future<void> loadTeachers() async {
    try {
      _teachers = await _teacherRepository.getAllTeachers();
    } catch (e) {
      debugPrint('Error loading teachers: $e');
    }
  }

  // Add new course
  Future<bool> addCourse(Course course) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Check if course code already exists in this batch
      bool exists = await _repository.isCourseCodeExists(
          course.code,
          course.batchId
      );

      if (exists) {
        _error = 'Course code already exists in this batch';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      int id = await _repository.addCourse(course);
      if (id > 0) {
        await loadCourses();
        return true;
      } else {
        _error = 'Failed to add course';
        return false;
      }
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update course
  Future<bool> updateCourse(Course course) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Check if course code already exists (excluding current course)
      bool exists = await _repository.isCourseCodeExists(
        course.code,
        course.batchId,
        excludeId: course.id,
      );

      if (exists) {
        _error = 'Course code already exists in this batch';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      int rowsAffected = await _repository.updateCourse(course);
      if (rowsAffected > 0) {
        await loadCourses();
        return true;
      } else {
        _error = 'Failed to update course';
        return false;
      }
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Delete course
  Future<bool> deleteCourse(int id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      int rowsAffected = await _repository.deleteCourse(id);
      if (rowsAffected > 0) {
        await loadCourses();
        return true;
      } else {
        _error = 'Failed to delete course';
        return false;
      }
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Assign teacher to course
  Future<bool> assignTeacher(int courseId, int teacherId) async {
    try {
      int rowsAffected = await _repository.assignTeacher(courseId, teacherId);
      if (rowsAffected > 0) {
        await loadCourses();
        return true;
      }
      return false;
    } catch (e) {
      _error = e.toString();
      return false;
    }
  }

  // Remove teacher from course
  Future<bool> removeTeacher(int courseId) async {
    try {
      int rowsAffected = await _repository.removeTeacher(courseId);
      if (rowsAffected > 0) {
        await loadCourses();
        return true;
      }
      return false;
    } catch (e) {
      _error = e.toString();
      return false;
    }
  }

  // Filter by batch
  void filterByBatch(int? batchId) {
    _selectedBatchId = batchId;
    _applyFilters();
  }

  // Filter by teacher
  void filterByTeacher(int? teacherId) {
    _selectedTeacherId = teacherId;
    _applyFilters();
  }

  // Apply all filters
  void _applyFilters() {
    _isSearching = true;

    _searchResults = _courses.where((course) {
      bool matchesBatch = _selectedBatchId == null ||
          course.batchId == _selectedBatchId;
      bool matchesTeacher = _selectedTeacherId == null ||
          course.teacherId == _selectedTeacherId;

      return matchesBatch && matchesTeacher;
    }).toList();

    notifyListeners();
  }

  // Clear filters
  void clearFilters() {
    _isSearching = false;
    _selectedBatchId = null;
    _selectedTeacherId = null;
    _searchResults = [];
    notifyListeners();
  }

  // Search courses
  void searchCourses(String query) {
    if (query.isEmpty) {
      _isSearching = false;
      _searchResults = [];
    } else {
      _isSearching = true;
      _searchResults = _courses.where((course) =>
      course.code.toLowerCase().contains(query.toLowerCase()) ||
          course.title.toLowerCase().contains(query.toLowerCase())
      ).toList();
    }
    notifyListeners();
  }

  // Get courses by batch
  List<Course> getCoursesByBatch(int batchId) {
    return _courses.where((course) => course.batchId == batchId).toList();
  }

  // Get courses by teacher
  List<Course> getCoursesByTeacher(int teacherId) {
    return _courses.where((course) => course.teacherId == teacherId).toList();
  }

  // Get course by id
  Course? getCourseById(int id) {
    try {
      return _courses.firstWhere((course) => course.id == id);
    } catch (e) {
      return null;
    }
  }

  // Get total credits for a batch
  double getTotalCreditsForBatch(int batchId) {
    final batchCourses = getCoursesByBatch(batchId);
    return batchCourses.fold(0.0, (sum, course) => sum + course.credit);
  }

  // Get course count by type
  int getCourseCountByType(String type) {
    return _courses.where((course) => course.type == type).toList().length;
  }

  // Refresh data
  Future<void> refresh() async {
    await loadCourses();
  }
}