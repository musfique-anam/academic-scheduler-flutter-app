// lib/providers/routine_provider.dart

import 'package:flutter/material.dart';
import '../data/models/routine_model.dart';
import '../data/models/conflict_model.dart';
import '../data/models/exam_routine_model.dart';
import '../data/models/room_model.dart';
import '../data/services/routine_generator_service.dart';
import '../data/services/exam_routine_generator.dart';
import '../data/services/conflict_detector_service.dart';
import '../data/services/workload_validator_service.dart';
import '../data/repositories/batch_repository.dart';
import '../data/repositories/course_repository.dart';
import '../data/repositories/teacher_repository.dart';
import '../data/repositories/room_repository.dart';
import '../data/services/database_helper.dart';

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

  void updateProgress(double progress) {
    _generationProgress = progress;
    notifyListeners();
  }

  void setExamRoutines(List<Routine> routines) {
    _generatedRoutines = routines;
    _conflicts = _conflictDetector.detectConflicts(routines);
    notifyListeners();
  }

  // Load all routines from database
  Future<void> loadRoutinesFromDatabase() async {
    try {
      final db = await DatabaseHelper().database;
      final List<Map<String, dynamic>> maps = await db.query('routines');

      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('📊 Database query returned ${maps.length} routines');
      for (var map in maps) {
        print('  📌 Type: ${map['type']} | Course: ${map['courseCode']} | Day: ${map['day']} | Slot: ${map['slot']}');
      }
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

      _generatedRoutines = maps.map((map) => Routine.fromMap(map)).toList();

      final teachers = await _teacherRepo.getAllTeachers();
      _workloads = _workloadValidator.validateTeacherWorkloads(teachers, _generatedRoutines);

      notifyListeners();
      print('📚 Loaded ${_generatedRoutines.length} routines from database');
    } catch (e) {
      print('❌ Error loading routines: $e');
    }
  }

  // Load only class routines
  Future<void> loadClassRoutinesFromDatabase() async {
    try {
      final db = await DatabaseHelper().database;
      final List<Map<String, dynamic>> maps = await db.query(
        'routines',
        where: 'type = ?',
        whereArgs: ['class'],
      );
      _generatedRoutines = maps.map((map) => Routine.fromMap(map)).toList();
      notifyListeners();
      print('📚 Loaded ${_generatedRoutines.length} class routines');
    } catch (e) {
      print('❌ Error loading class routines: $e');
    }
  }

  // Load only exam routines
  Future<void> loadExamRoutinesFromDatabase() async {
    try {
      final db = await DatabaseHelper().database;
      final List<Map<String, dynamic>> maps = await db.query(
        'routines',
        where: 'type = ?',
        whereArgs: ['exam'],
      );
      _generatedRoutines = maps.map((map) => Routine.fromMap(map)).toList();
      notifyListeners();
      print('📚 Loaded ${_generatedRoutines.length} exam routines');
    } catch (e) {
      print('❌ Error loading exam routines: $e');
    }
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

      var batches = await _batchRepo.getBatchesByDepartment(departmentId);
      var allCourses = await _courseRepo.getAllCourses();
      var teachers = await _teacherRepo.getAllTeachers();
      var rooms = await _roomRepo.getAllRooms();

      if (batches.isEmpty) {
        throw Exception('No batches found for this department');
      }

      var courses = allCourses.where((c) =>
          batches.any((b) => b.id == c.batchId)
      ).toList();

      _updateStatus('Generating routine...', onStatusUpdate);

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

      _conflicts = _conflictDetector.detectConflicts(_generatedRoutines);
      _workloads = _workloadValidator.validateTeacherWorkloads(teachers, _generatedRoutines);
      _batchValidation = _workloadValidator.validateBatchCredits(batches, _generatedRoutines);

      _updateStatus('Routine generated successfully!', onStatusUpdate);
      _isGenerating = false;
      notifyListeners();

      await loadClassRoutinesFromDatabase();

      return true;

    } catch (e) {
      _error = e.toString();
      _isGenerating = false;
      notifyListeners();
      return false;
    }
  }

  // Generate exam routine
  // In routine_provider.dart, update the generateExamRoutine method (around line 220)

// Generate exam routine
  Future<bool> generateExamRoutine({
    required String examName,
    required List<int> departmentIds,
    required List<int> batchIds,
    required List<int> roomIds,
    required List<Room> rooms,
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

      // Fix: Remove courseId reference
      _generatedRoutines = examRoutines.map((e) => Routine(
        type: 'exam',
        departmentId: e.departmentIds.first.toString(),
        batchId: e.batchIds.first.toString(),
        courseCode: e.courseCode,
        courseTitle: e.courseTitle,
        teacherId: null,
        teacherName: null,
        roomId: e.roomId?.toString(),
        roomNo: e.roomNo,
        day: _getDayFromDate(e.date),
        slot: e.slot,
        startTime: e.startTime,
        endTime: e.endTime,
        status: e.status,
        date: e.date,
      )).toList();

      _conflicts = _conflictDetector.detectConflicts(_generatedRoutines);

      _updateStatus('Exam routine generated!', onStatusUpdate);
      _isGenerating = false;
      notifyListeners();

      await _saveRoutinesToDatabase();
      await loadExamRoutinesFromDatabase();

      return true;

    } catch (e) {
      _error = e.toString();
      _isGenerating = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteRoutine(int routineId) async {
    try {
      final db = await DatabaseHelper().database;
      int result = await db.delete('routines', where: 'id = ?', whereArgs: [routineId]);

      if (result > 0) {
        // Remove from local list
        _generatedRoutines.removeWhere((r) => r.id == routineId);
        // Re-detect conflicts
        _conflicts = _conflictDetector.detectConflicts(_generatedRoutines);
        notifyListeners();
        print('✅ Deleted routine ID: $routineId');
        return true;
      }
      return false;
    } catch (e) {
      print('❌ Error deleting routine: $e');
      return false;
    }
  }

// Delete all routines for a batch
  Future<bool> deleteRoutinesByBatch(int batchId) async {
    try {
      final db = await DatabaseHelper().database;
      int result = await db.delete('routines', where: 'batchId = ?', whereArgs: [batchId]);

      if (result > 0) {
        _generatedRoutines.removeWhere((r) => r.batchId == batchId);
        _conflicts = _conflictDetector.detectConflicts(_generatedRoutines);
        notifyListeners();
        print('✅ Deleted ${result} routines for batch: $batchId');
        return true;
      }
      return false;
    } catch (e) {
      print('❌ Error deleting routines: $e');
      return false;
    }
  }

// Delete all routines (clear everything)
  Future<bool> deleteAllRoutines() async {
    try {
      final db = await DatabaseHelper().database;
      int result = await db.delete('routines');

      if (result > 0) {
        _generatedRoutines.clear();
        _conflicts.clear();
        notifyListeners();
        print('✅ Deleted all $result routines');
        return true;
      }
      return false;
    } catch (e) {
      print('❌ Error deleting all routines: $e');
      return false;
    }
  }
  Future<void> _saveRoutinesToDatabase() async {
    try {
      final db = await DatabaseHelper().database;
      for (var routine in _generatedRoutines) {
        await db.insert('routines', routine.toMap());
      }
      print('✅ Saved ${_generatedRoutines.length} routines to database');
    } catch (e) {
      print('❌ Error saving routines: $e');
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

  void resolveConflict(Conflict conflict, Map<String, dynamic> resolution) {
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
    _conflicts = _conflictDetector.detectConflicts(_generatedRoutines);
    notifyListeners();
  }

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
    if (changes.containsKey('day')) {
      routine.day = changes['day'];
    }
    routine.status = 'manual_fixed';
    _conflicts = _conflictDetector.detectConflicts(_generatedRoutines);
    notifyListeners();
  }

  List<Routine> getRoutinesByDay(String day) {
    return _generatedRoutines.where((r) => r.day == day).toList()
      ..sort((a, b) => a.slot.compareTo(b.slot));
  }

  List<Routine> getRoutinesByBatch(int batchId) {
    return _generatedRoutines.where((r) => r.batchId == batchId).toList();
  }

  List<Routine> getRoutinesByTeacher(int teacherId) {
    return _generatedRoutines.where((r) => r.teacherId == teacherId).toList();
  }

  Map<String, int> getConflictStats() {
    return {
      'total': _conflicts.length,
      'teacher': _conflicts.where((c) => c.type == 'teacher').length,
      'room': _conflicts.where((c) => c.type == 'room').length,
      'batch': _conflicts.where((c) => c.type == 'batch').length,
    };
  }

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

  void clear() {
    _generatedRoutines.clear();
    _conflicts.clear();
    _workloads.clear();
    _batchValidation.clear();
    _generationProgress = 0.0;
    _error = null;
    notifyListeners();
  }

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