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
  final WorkloadValidatorService _workloadValidator =
      WorkloadValidatorService();

  final BatchRepository _batchRepo = BatchRepository();
  final CourseRepository _courseRepo = CourseRepository();
  final TeacherRepository _teacherRepo = TeacherRepository();
  final RoomRepository _roomRepo = RoomRepository();

  List<Routine> _generatedRoutines = [];
  List<Conflict> _conflicts = [];
  List<dynamic> _workloads = [];
  Map<int, Map<String, dynamic>> _batchValidation = {};

  bool _isGenerating = false;
  double _generationProgress = 0.0;
  String? _error;

  List<Routine> get routines => _generatedRoutines;
  List<Conflict> get conflicts => _conflicts;
  List<dynamic> get workloads => _workloads;
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

  Future<void> loadRoutinesFromDatabase() async {
    try {
      final db = await DatabaseHelper().database;
      final List<Map<String, dynamic>> maps = await db.query('routines');
      _generatedRoutines = maps.map((m) => Routine.fromMap(m)).toList();
      final teachers = await _teacherRepo.getAllTeachers();
      _workloads = _workloadValidator.validateTeacherWorkloads(
          teachers, _generatedRoutines);
      _conflicts = _conflictDetector.detectConflicts(_generatedRoutines);
      notifyListeners();
      debugPrint(
          '📚 Loaded ${_generatedRoutines.length} routines, ${_conflicts.length} conflicts');
    } catch (e) {
      debugPrint('❌ Error loading routines: $e');
    }
  }

  Future<void> loadClassRoutinesFromDatabase() async {
    try {
      final db = await DatabaseHelper().database;
      final List<Map<String, dynamic>> maps = await db
          .query('routines', where: 'type = ?', whereArgs: ['class']);
      _generatedRoutines = maps.map((m) => Routine.fromMap(m)).toList();
      _conflicts = _conflictDetector.detectConflicts(_generatedRoutines);
      notifyListeners();
      debugPrint('📘 Loaded ${_generatedRoutines.length} class routines');
    } catch (e) {
      debugPrint('❌ Error loading class routines: $e');
    }
  }

  Future<void> loadExamRoutinesFromDatabase() async {
    try {
      final db = await DatabaseHelper().database;
      final List<Map<String, dynamic>> maps = await db
          .query('routines', where: 'type = ?', whereArgs: ['exam']);
      _generatedRoutines = maps.map((m) => Routine.fromMap(m)).toList();
      _conflicts = _conflictDetector.detectConflicts(_generatedRoutines);
      notifyListeners();
      debugPrint('📕 Loaded ${_generatedRoutines.length} exam routines');
    } catch (e) {
      debugPrint('❌ Error loading exam routines: $e');
    }
  }

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
      if (batches.isEmpty) throw Exception('No batches found');
      var courses = allCourses
          .where((c) => batches.any((b) => b.id == c.batchId))
          .toList();
      _updateStatus('Generating routine...', onStatusUpdate);
      _generatedRoutines = await _generator.generateClassRoutine(
        departmentId: departmentId,
        programType: programType,
        batches: batches,
        courses: courses,
        teachers: teachers,
        rooms: rooms,
        onProgress: (p) {
          _generationProgress = p;
          notifyListeners();
        },
      );
      _conflicts = _conflictDetector.detectConflicts(_generatedRoutines);
      _workloads = _workloadValidator.validateTeacherWorkloads(
          teachers, _generatedRoutines);
      _batchValidation = _workloadValidator.validateBatchCredits(
          batches, _generatedRoutines);
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

  // 🔥 FULLY REWRITTEN — defensive exam generation with logging + manual fallback
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
      final allCourses = await _courseRepo.getAllCourses();
      final courses =
          allCourses.where((c) => batchIds.contains(c.batchId)).toList();

      final totalDays = endDate.difference(startDate).inDays + 1;
      debugPrint('🎯 Exam input: ${courses.length} courses, '
          '$totalDays days, ${roomIds.length} rooms, '
          '${batchIds.length} batches');

      if (courses.isEmpty) {
        throw Exception(
            'No courses found for selected batches. Add courses first.');
      }
      if (roomIds.isEmpty) throw Exception('No rooms selected');
      if (totalDays < 1) throw Exception('Invalid date range');

      _updateStatus('Generating exam routine...', onStatusUpdate);

      // Try original generator first
      List<dynamic> examRoutines = [];
      try {
        examRoutines = await _examGenerator.generateExamRoutine(
          examName: examName,
          departmentIds: departmentIds,
          batchIds: batchIds,
          courses: courses,
          roomIds: roomIds,
          rooms: rooms,
          startDate: startDate,
          endDate: endDate,
          onProgress: (p) {
            _generationProgress = p;
            notifyListeners();
          },
        );
        debugPrint('🎯 Generator returned ${examRoutines.length} exams');
      } catch (e) {
        debugPrint('⚠️ Generator threw: $e — falling back to manual scheduler');
      }

      // 🔥 FALLBACK MANUAL SCHEDULER — if generator returned 0
      List<Routine> builtRoutines = [];
      if (examRoutines.isEmpty) {
        debugPrint('🔧 Using manual fallback scheduler');
        builtRoutines = _manualExamSchedule(
          courses: courses,
          rooms: rooms.where((r) => roomIds.contains(r.id)).toList(),
          startDate: startDate,
          endDate: endDate,
          departmentIds: departmentIds,
          batchIds: batchIds,
        );
        debugPrint('🔧 Manual scheduler built ${builtRoutines.length} exams');
      } else {
        builtRoutines = examRoutines.map((e) {
          return Routine(
            type: 'exam',
            departmentId: (e.departmentIds as List).isNotEmpty
                ? e.departmentIds.first.toString()
                : '',
            batchId: (e.batchIds as List).isNotEmpty
                ? e.batchIds.first.toString()
                : '',
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
            status: e.status ?? 'generated',
            date: e.date,
          );
        }).toList();
      }

      if (builtRoutines.isEmpty) {
        throw Exception(
            'Could not schedule any exams. Need ${courses.length} slots, have $totalDays days × ${roomIds.length} rooms.');
      }

      // Clear old exam rows
      final db = await DatabaseHelper().database;
      final deleted =
          await db.delete('routines', where: 'type = ?', whereArgs: ['exam']);
      debugPrint('🗑️ Cleared $deleted old exam rows');

      // Save new
      int savedCount = 0;
      for (final r in builtRoutines) {
        final map = r.toMap();
        map['type'] = 'exam'; // ensure
        map.remove('id'); // let DB auto-assign
        try {
          await db.insert('routines', map);
          savedCount++;
        } catch (e) {
          debugPrint('❌ Save failed: $e | $map');
        }
      }
      debugPrint('💾 Saved $savedCount/${builtRoutines.length} exam rows');

      // Verify and load
      final verified = await db
          .query('routines', where: 'type = ?', whereArgs: ['exam']);
      debugPrint('✅ Verified ${verified.length} exam rows in DB');

      _generatedRoutines = verified.map((m) => Routine.fromMap(m)).toList();
      _conflicts = _conflictDetector.detectConflicts(_generatedRoutines);

      _updateStatus('Exam routine generated! ($savedCount exams)',
          onStatusUpdate);
      _isGenerating = false;
      notifyListeners();
      return savedCount > 0;
    } catch (e, stack) {
      debugPrint('❌ Exam gen error: $e\n$stack');
      _error = e.toString();
      _isGenerating = false;
      notifyListeners();
      return false;
    }
  }

  // 🔥 Manual scheduler — guaranteed to produce results if capacity allows
  List<Routine> _manualExamSchedule({
    required List<dynamic> courses,
    required List<Room> rooms,
    required DateTime startDate,
    required DateTime endDate,
    required List<int> departmentIds,
    required List<int> batchIds,
  }) {
    final List<Routine> result = [];
    final List<Map<String, String>> slotTimes = [
      {'start': '9:30', 'end': '11:30', 'slot': '1'},
      {'start': '12:00', 'end': '14:00', 'slot': '2'},
      {'start': '14:30', 'end': '16:30', 'slot': '3'},
    ];

    int courseIdx = 0;
    DateTime current = startDate;

    while (courseIdx < courses.length &&
        !current.isAfter(endDate)) {
      // Skip Fridays (weekday=5) by default for exams
      if (current.weekday == 5) {
        current = current.add(const Duration(days: 1));
        continue;
      }

      for (final slotInfo in slotTimes) {
        if (courseIdx >= courses.length) break;
        for (final room in rooms) {
          if (courseIdx >= courses.length) break;
          final c = courses[courseIdx];
          result.add(Routine(
            type: 'exam',
            departmentId: departmentIds.isNotEmpty
                ? departmentIds.first.toString()
                : '',
            batchId: c.batchId.toString(),
            courseCode: c.code,
            courseTitle: c.title,
            teacherId: null,
            teacherName: null,
            roomId: room.id?.toString(),
            roomNo: room.roomNo,
            day: _getDayFromDate(current),
            slot: int.parse(slotInfo['slot']!),
            startTime: slotInfo['start']!,
            endTime: slotInfo['end']!,
            status: 'generated',
            date: current,
          ));
          courseIdx++;
        }
      }
      current = current.add(const Duration(days: 1));
    }

    return result;
  }

  Future<bool> deleteRoutine(int routineId) async {
    try {
      final db = await DatabaseHelper().database;
      int result = await db
          .delete('routines', where: 'id = ?', whereArgs: [routineId]);
      if (result > 0) {
        _generatedRoutines.removeWhere((r) => r.id == routineId);
        _conflicts = _conflictDetector.detectConflicts(_generatedRoutines);
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteRoutinesByBatch(int batchId) async {
    try {
      final db = await DatabaseHelper().database;
      int result = await db
          .delete('routines', where: 'batchId = ?', whereArgs: [batchId]);
      if (result > 0) {
        _generatedRoutines.removeWhere((r) => r.batchId == batchId.toString());
        _conflicts = _conflictDetector.detectConflicts(_generatedRoutines);
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteAllRoutines() async {
    try {
      final db = await DatabaseHelper().database;
      int result = await db.delete('routines');
      if (result > 0) {
        _generatedRoutines.clear();
        _conflicts.clear();
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  String _getDayFromDate(DateTime date) {
    switch (date.weekday) {
      case 1:
        return 'Monday';
      case 2:
        return 'Tuesday';
      case 3:
        return 'Wednesday';
      case 4:
        return 'Thursday';
      case 5:
        return 'Friday';
      case 6:
        return 'Saturday';
      case 7:
        return 'Sunday';
      default:
        return '';
    }
  }

  Future<bool> resolveConflict(
      Conflict conflict, Map<String, dynamic> resolution) async {
    try {
      final routineId = resolution['routineId'];
      if (routineId == null) return false;
      Routine? target;
      for (var r in conflict.conflictingRoutines) {
        if (r.id == routineId) {
          target = r as Routine;
          break;
        }
      }
      if (target == null) {
        final matches = _generatedRoutines.where((r) => r.id == routineId);
        if (matches.isEmpty) return false;
        target = matches.first;
      }

      if (resolution.containsKey('newSlot')) {
        final newSlot = resolution['newSlot'] is int
            ? resolution['newSlot'] as int
            : int.tryParse(resolution['newSlot'].toString()) ?? target.slot;
        target.slot = newSlot;
        target.startTime = _getTimeForSlot(newSlot, 'start');
        target.endTime = _getTimeForSlot(newSlot, 'end');
      }
      if (resolution.containsKey('newDay')) {
        target.day = resolution['newDay']?.toString() ?? target.day;
      }
      if (resolution.containsKey('teacherId')) {
        target.teacherId = resolution['teacherId']?.toString();
        target.teacherName = resolution['teacherName']?.toString();
      }
      if (resolution.containsKey('roomId')) {
        target.roomId = resolution['roomId']?.toString();
        target.roomNo = resolution['roomNo']?.toString();
      }
      target.status = 'manual_fixed';

      final db = await DatabaseHelper().database;
      await db.update(
        'routines',
        {
          'slot': target.slot,
          'day': target.day,
          'teacherId': target.teacherId,
          'teacherName': target.teacherName,
          'roomId': target.roomId,
          'roomNo': target.roomNo,
          'startTime': target.startTime,
          'endTime': target.endTime,
          'status': target.status,
        },
        where: 'id = ?',
        whereArgs: [routineId],
      );

      _generatedRoutines = List<Routine>.from(_generatedRoutines);
      _conflicts = List<Conflict>.from(
          _conflictDetector.detectConflicts(_generatedRoutines));
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('❌ Error resolving conflict: $e');
      return false;
    }
  }

  void editRoutine(Routine routine, Map<String, dynamic> changes) {
    if (changes.containsKey('slot')) {
      routine.slot = changes['slot'];
      routine.startTime = _getTimeForSlot(changes['slot'], 'start');
      routine.endTime = _getTimeForSlot(changes['slot'], 'end');
    }
    if (changes.containsKey('teacherId')) {
      routine.teacherId = changes['teacherId']?.toString();
      routine.teacherName = changes['teacherName']?.toString();
    }
    if (changes.containsKey('roomId')) {
      routine.roomId = changes['roomId']?.toString();
      routine.roomNo = changes['roomNo']?.toString();
    }
    if (changes.containsKey('day')) routine.day = changes['day'];
    routine.status = 'manual_fixed';
    _conflicts = List<Conflict>.from(
        _conflictDetector.detectConflicts(_generatedRoutines));
    notifyListeners();
  }

  List<Routine> getRoutinesByDay(String day) =>
      _generatedRoutines.where((r) => r.day == day).toList()
        ..sort((a, b) => a.slot.compareTo(b.slot));

  List<Routine> getRoutinesByBatch(int batchId) => _generatedRoutines
      .where((r) => r.batchId == batchId.toString())
      .toList();

  List<Routine> getRoutinesByTeacher(int teacherId) => _generatedRoutines
      .where((r) => r.teacherId == teacherId.toString())
      .toList();

  Map<String, int> getConflictStats() => {
        'total': _conflicts.length,
        'teacher': _conflicts.where((c) => c.type == 'teacher').length,
        'room': _conflicts.where((c) => c.type == 'room').length,
        'batch': _conflicts.where((c) => c.type == 'batch').length,
      };

  Map<String, dynamic> getWorkloadStats() {
    int totalTeachers = _workloads.length;
    int overloaded = _workloads.where((w) => w.isOverloaded).length;
    double avgUtilization = _workloads.isEmpty
        ? 0
        : _workloads.map((w) => w.utilization).reduce((a, b) => a + b) /
            _workloads.length;
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
    if (callback != null) callback(message);
  }

  String _getTimeForSlot(int slot, String type) {
    switch (slot) {
      case 1:
        return type == 'start' ? '9:30' : '11:00';
      case 2:
        return type == 'start' ? '11:10' : '12:40';
      case 3:
        return type == 'start' ? '14:00' : '15:30';
      case 4:
        return type == 'start' ? '15:40' : '17:10';
      default:
        return '';
    }
  }
}