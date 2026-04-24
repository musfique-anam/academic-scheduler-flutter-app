import 'package:flutter/material.dart';
import '../data/models/routine_model.dart';
import '../data/models/conflict_model.dart';
import '../data/models/exam_routine_model.dart';
import '../data/models/room_model.dart'; // ← ADD THIS IMPORT
import '../data/services/routine_generator_service.dart';
import '../data/services/exam_routine_generator.dart';
import '../data/services/conflict_detector_service.dart';
import '../data/services/workload_validator_service.dart';
import '../data/repositories/batch_repository.dart';
import '../data/repositories/course_repository.dart';
import '../data/repositories/teacher_repository.dart';
import '../data/repositories/room_repository.dart';

class RoutineProvider extends ChangeNotifier {
  final RoutineGeneratorService _generator = RoutineGeneratorService();
  final ExamRoutineGenerator _examGenerator = ExamRoutineGenerator();
  final ConflictDetectorService _conflictDetector = ConflictDetectorService();
  final WorkloadValidatorService _workloadValidator = WorkloadValidatorService();

  final BatchRepository _batchRepo = BatchRepository();
  final CourseRepository _courseRepo = CourseRepository();
  final TeacherRepository _teacherRepo = TeacherRepository();
  final RoomRepository _roomRepo = RoomRepository();

  List<Routine> _generatedRoutines = [];
  List<Conflict> _conflicts = [];
  List<WorkloadInfo> _workloads = [];
  Map<int, Map<String, dynamic>> _batchValidation = {};

  bool _isGenerating = false;
  double _generationProgress = 0.0;
  String? _error;

  // Getters
  List<Routine> get routines => _generatedRoutines;
  List<Conflict> get conflicts => _conflicts;
  List<WorkloadInfo> get workloads => _workloads;
  Map<int, Map<String, dynamic>> get batchValidation => _batchValidation;
  bool get isGenerating => _isGenerating;
  double get progress => _generationProgress;
  String? get error => _error;
  bool get hasConflicts => _conflicts.isNotEmpty;
  bool get hasOverload => _workloads.any((w) => w.isOverloaded);
  bool get hasRoutines => _generatedRoutines.isNotEmpty;

  // Update progress
  void updateProgress(double progress) {
    _generationProgress = progress;
    notifyListeners();
  }

  // Set exam routines
  void setExamRoutines(List<Routine> routines) {
    _generatedRoutines = routines;
    _conflicts = _conflictDetector.detectConflicts(routines);
    notifyListeners();
  }

  // Generate class routine
  Future<bool> generateClassRoutine({
    required int departmentId,
    required String programType,
    Function(String)? onStatusUpdate,
  }) async {
    _isGenerating = true;
    _generationProgress = 0.0;
    _error = null;
    notifyListeners();

    try {
      _updateStatus('Loading data...', onStatusUpdate);

      // Load all required data
      var batches = await _batchRepo.getBatchesByDepartment(departmentId);
      var allCourses = await _courseRepo.getAllCourses();
      var teachers = await _teacherRepo.getAllTeachers();
      var rooms = await _roomRepo.getAllRooms();

      if (batches.isEmpty) {
        throw Exception('No batches found for this department');
      }

      // Filter courses by batches
      var courses = allCourses.where((c) =>
          batches.any((b) => b.id == c.batchId)
      ).toList();

      _updateStatus('Generating routine...', onStatusUpdate);

      // Generate routine
      _generatedRoutines = await _generator.generateClassRoutine(
        departmentId: departmentId,
        programType: programType,
        batches: batches,
        courses: courses,
        teachers: teachers,
        rooms: rooms,
        onProgress: (progress) {
          _generationProgress = progress;
          notifyListeners();
        },
      );

      _updateStatus('Checking for conflicts...', onStatusUpdate);

      // Detect conflicts
      _conflicts = _conflictDetector.detectConflicts(_generatedRoutines);

      // Validate workloads
      _workloads = _workloadValidator.validateTeacherWorkloads(teachers, _generatedRoutines);

      // Validate batch credits
      _batchValidation = _workloadValidator.validateBatchCredits(batches, _generatedRoutines);

      _updateStatus('Routine generated successfully!', onStatusUpdate);
      _isGenerating = false;
      notifyListeners();
      return true;

    } catch (e) {
      _error = e.toString();
      _isGenerating = false;
      notifyListeners();
      return false;
    }
  }

  // Generate exam routine
  Future<bool> generateExamRoutine({
    required String examName,
    required List<int> departmentIds,
    required List<int> batchIds,
    required List<int> roomIds,
    required List<Room> rooms, // Now Room type is recognized
    required DateTime startDate,
    required DateTime endDate,
    Function(String)? onStatusUpdate,
  }) async {
    _isGenerating = true;
    _generationProgress = 0.0;
    _error = null;
    notifyListeners();

    try {
      _updateStatus('Loading courses...', onStatusUpdate);

      var allCourses = await _courseRepo.getAllCourses();
      var courses = allCourses.where((c) => batchIds.contains(c.batchId)).toList();

      if (courses.isEmpty) {
        throw Exception('No courses found for selected batches');
      }

      _updateStatus('Generating exam routine...', onStatusUpdate);

      var examRoutines = await _examGenerator.generateExamRoutine(
        examName: examName,
        departmentIds: departmentIds,
        batchIds: batchIds,
        courses: courses,
        roomIds: roomIds,
        rooms: rooms,
        startDate: startDate,
        endDate: endDate,
        onProgress: (progress) {
          _generationProgress = progress;
          notifyListeners();
        },
      );

      // Convert to regular routines for display
      _generatedRoutines = examRoutines.map((e) => Routine(
        type: 'exam',
        departmentId: e.departmentIds.first,
        batchId: e.batchIds.first,
        courseId: e.courseId,
        courseCode: e.courseCode,
        courseTitle: e.courseTitle,
        teacherId: null,
        teacherName: null,
        roomId: e.roomId,
        roomNo: e.roomNo,
        day: _getDayFromDate(e.date),
        slot: e.slot,
        startTime: e.startTime,
        endTime: e.endTime,
        date: e.date,
        status: e.status,
      )).toList();

      // Detect conflicts
      _conflicts = _conflictDetector.detectConflicts(_generatedRoutines);

      _updateStatus('Exam routine generated!', onStatusUpdate);
      _isGenerating = false;
      notifyListeners();
      return true;

    } catch (e) {
      _error = e.toString();
      _isGenerating = false;
      notifyListeners();
      return false;
    }
  }

  String _getDayFromDate(DateTime date) {
    switch(date.weekday) {
      case 5: return 'Friday';
      case 6: return 'Saturday';
      case 7: return 'Sunday';
      case 1: return 'Monday';
      case 2: return 'Tuesday';
      default: return '';
    }
  }

  // Manual conflict resolution
  void resolveConflict(Conflict conflict, Map<String, dynamic> resolution) {
    // Update the conflicting routines
    for (var routine in conflict.conflictingRoutines) {
      if (resolution['routineId'] == routine.id) {
        if (resolution.containsKey('newSlot')) {
          routine.slot = resolution['newSlot'];
          routine.startTime = _getTimeForSlot(resolution['newSlot'], 'start');
          routine.endTime = _getTimeForSlot(resolution['newSlot'], 'end');
        }
        if (resolution.containsKey('teacherId')) {
          routine.teacherId = resolution['teacherId'];
          routine.teacherName = resolution['teacherName'];
        }
        if (resolution.containsKey('roomId')) {
          routine.roomId = resolution['roomId'];
          routine.roomNo = resolution['roomNo'];
        }
        routine.status = 'manual_fixed';
      }
    }

    // Re-detect conflicts
    _conflicts = _conflictDetector.detectConflicts(_generatedRoutines);
    notifyListeners();
  }

  // Manual routine edit
  void editRoutine(Routine routine, Map<String, dynamic> changes) {
    if (changes.containsKey('slot')) {
      routine.slot = changes['slot'];
      routine.startTime = _getTimeForSlot(changes['slot'], 'start');
      routine.endTime = _getTimeForSlot(changes['slot'], 'end');
    }
    if (changes.containsKey('teacherId')) {
      routine.teacherId = changes['teacherId'];
      routine.teacherName = changes['teacherName'];
    }
    if (changes.containsKey('roomId')) {
      routine.roomId = changes['roomId'];
      routine.roomNo = changes['roomNo'];
    }

    routine.status = 'manual_fixed';

    // Re-detect conflicts
    _conflicts = _conflictDetector.detectConflicts(_generatedRoutines);
    notifyListeners();
  }

  // Get routines by day
  List<Routine> getRoutinesByDay(String day) {
    return _generatedRoutines.where((r) => r.day == day).toList()
      ..sort((a, b) => a.slot.compareTo(b.slot));
  }

  // Get routines by batch
  List<Routine> getRoutinesByBatch(int batchId) {
    return _generatedRoutines.where((r) => r.batchId == batchId).toList();
  }

  // Get routines by teacher
  List<Routine> getRoutinesByTeacher(int teacherId) {
    return _generatedRoutines.where((r) => r.teacherId == teacherId).toList();
  }

  // Get conflict statistics
  Map<String, int> getConflictStats() {
    return {
      'total': _conflicts.length,
      'teacher': _conflicts.where((c) => c.type == 'teacher').length,
      'room': _conflicts.where((c) => c.type == 'room').length,
      'batch': _conflicts.where((c) => c.type == 'batch').length,
    };
  }

  // Get workload statistics
  Map<String, dynamic> getWorkloadStats() {
    int totalTeachers = _workloads.length;
    int overloaded = _workloads.where((w) => w.isOverloaded).length;
    double avgUtilization = _workloads.isEmpty
        ? 0
        : _workloads.map((w) => w.utilization).reduce((a, b) => a + b) / _workloads.length;

    return {
      'totalTeachers': totalTeachers,
      'overloaded': overloaded,
      'avgUtilization': avgUtilization,
    };
  }

  // Clear all
  void clear() {
    _generatedRoutines.clear();
    _conflicts.clear();
    _workloads.clear();
    _batchValidation.clear();
    _generationProgress = 0.0;
    _error = null;
    notifyListeners();
  }

  // Helper method for status updates
  void _updateStatus(String message, Function(String)? callback) {
    if (callback != null) {
      callback(message);
    }
  }

  String _getTimeForSlot(int slot, String type) {
    switch(slot) {
      case 1: return type == 'start' ? '9:30' : '11:00';
      case 2: return type == 'start' ? '11:10' : '12:40';
      case 3: return type == 'start' ? '14:00' : '15:30';
      case 4: return type == 'start' ? '15:40' : '17:10';
      default: return '';
    }
  }
}