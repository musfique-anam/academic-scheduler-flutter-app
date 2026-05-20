// lib/data/services/routine_generator_service.dart

import '../models/routine_model.dart';
import '../models/batch_model.dart';
import '../models/course_model.dart';
import '../models/teacher_model.dart';
import '../models/room_model.dart';
import '../models/conflict_model.dart';
import 'conflict_detector_service.dart';
import 'workload_validator_service.dart';
import 'database_helper.dart';

class RoutineGeneratorService {
  final ConflictDetectorService _conflictDetector = ConflictDetectorService();
  final WorkloadValidatorService _workloadValidator = WorkloadValidatorService();

  // Time slots matching your PDF format
  final List<Map<String, dynamic>> _timeSlots = const [
    {'slot': 1, 'start': '9:30', 'end': '10:45', 'display': '9:30 AM – 10:45 AM'},
    {'slot': 2, 'start': '10:45', 'end': '12:00', 'display': '10:45 AM – 12:00 PM'},
    {'slot': 3, 'start': '12:00', 'end': '13:15', 'display': '12:00 PM – 1:15 PM'},
    {'slot': 4, 'start': '14:30', 'end': '15:45', 'display': '2:30 PM – 3:45 PM'},
  ];

  // Prayer break is between slot 3 and 4
  final String prayerBreak = 'PRAYER BREAK';

  // Save routines to database
  Future<void> _saveRoutinesToDatabase(List<Routine> routines) async {
    try {
      final db = await DatabaseHelper().database;
      await db.delete('routines');
      for (var routine in routines) {
        await db.insert('routines', routine.toMap());
      }
      print('✅ Saved ${routines.length} routines to database');
    } catch (e) {
      print('❌ Error saving routines: $e');
    }
  }

  // Main generate method
  Future<List<Routine>> generateClassRoutine({
    required int departmentId,
    required String programType,
    required List<Batch> batches,
    required List<Course> courses,
    required List<Teacher> teachers,
    required List<Room> rooms,
    Function(double)? onProgress,
  }) async {
    List<Routine> routines = [];

    int totalClasses = 0;
    for (var batch in batches) {
      var batchCourses = courses.where((c) => c.batchId == batch.id).toList();
      for (var course in batchCourses) {
        totalClasses += (course.type == 'Lab' ? 1 : course.credit.round());
      }
    }

    int currentStep = 0;

    List<String> allowedDays = programType == 'HSC'
        ? ['Saturday', 'Sunday', 'Monday', 'Tuesday']
        : ['Friday', 'Saturday'];

    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('📊 Starting Routine Generation');
    print('📊 Department ID: $departmentId');
    print('📊 Program Type: $programType');
    print('📊 Total Classes to Generate: $totalClasses');
    print('📊 Allowed Days: $allowedDays');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

    int routineId = 1;

    for (var batch in batches) {
      print('📚 Processing batch: ${batch.displayName} (ID: ${batch.id})');

      var batchCourses = courses.where((c) => c.batchId == batch.id).toList();
      var departmentTeachers = teachers.where((t) => t.departmentId == departmentId).toList();

      if (departmentTeachers.isEmpty) {
        print('⚠️ No teachers found for department $departmentId');
        continue;
      }

      for (var course in batchCourses) {
        print('  📖 Processing course: ${course.code} - ${course.title} (${course.type})');

        if (course.id == null) {
          print('    ❌ Course ID is null, skipping');
          continue;
        }

        var courseTeacher = departmentTeachers.firstWhere(
              (t) => t.interestedCourses.contains(course.id),
          orElse: () => departmentTeachers.first,
        );

        if (courseTeacher.id == null) {
          print('    ❌ Teacher ID is null, skipping');
          continue;
        }

        int requiredClasses = (course.type == 'Lab') ? 1 : course.credit.round();
        print('    Required classes: $requiredClasses, Credit: ${course.credit}');

        for (int i = 0; i < requiredClasses; i++) {
          currentStep++;
          if (onProgress != null) {
            onProgress(currentStep / totalClasses);
          }

          var routine = await _assignClass(
            routineId: routineId++,
            departmentId: departmentId,
            batch: batch,
            course: course,
            teacher: courseTeacher,
            teachers: departmentTeachers,
            rooms: rooms,
            allowedDays: allowedDays,
            existingRoutines: routines,
          );

          if (routine != null) {
            routines.add(routine);
            print('    ✅ Assigned: ${course.code} at ${routine.day} Slot ${routine.slot} (${routine.startTime}-${routine.endTime})');
          } else {
            print('    ❌ Could not assign: ${course.code}');
          }
        }
      }
    }

    print('✅ Initial routine generation complete! Total classes: ${routines.length}');

    // Auto-resolve conflicts
    print('🔧 Checking and resolving conflicts...');
    routines = await _autoResolveConflicts(routines, rooms, teachers);

    print('✅ Final routine generation complete! Total classes: ${routines.length}');
    await _saveRoutinesToDatabase(routines);
    return routines;
  }

  // Assign a single class with improved logging
  Future<Routine?> _assignClass({
    required int routineId,
    required int departmentId,
    required Batch batch,
    required Course course,
    required Teacher teacher,
    required List<Teacher> teachers,
    required List<Room> rooms,
    required List<String> allowedDays,
    required List<Routine> existingRoutines,
  }) async {
    int requiredSlots = course.type == 'Lab' ? 2 : 1;

    int? batchId = batch.id;
    int? courseId = course.id;
    int? teacherId = teacher.id;

    if (batchId == null || courseId == null || teacherId == null) {
      print('      ❌ Null ID - batch: $batchId, course: $courseId, teacher: $teacherId');
      return null;
    }

    for (var day in allowedDays) {
      int maxSlot = requiredSlots == 2 ? 3 : 4;

      for (int slot = 1; slot <= maxSlot; slot++) {
        if (requiredSlots == 2 && slot + 1 > 4) continue;

        // CHECK: Skip if batch already has a class at this time
        bool batchBusy = existingRoutines.any((r) =>
        r.batchId == batchId.toString() &&
            r.day == day &&
            r.slot == slot
        );

        if (batchBusy) continue;

        // CHECK: Teacher availability
        bool teacherAvailable = _isTeacherAvailable(
          teacher: teacher,
          day: day,
          slot: slot,
          requiredSlots: requiredSlots,
          existingRoutines: existingRoutines,
        );

        if (!teacherAvailable) continue;

        // Find available room
        Room? availableRoom = _findAvailableRoomSafe(
          rooms: rooms,
          day: day,
          slot: slot,
          requiredSlots: requiredSlots,
          courseType: course.type,
          existingRoutines: existingRoutines,
        );

        if (availableRoom == null) continue;
        if (availableRoom.id == null) continue;

        String startTime = _getTimeForSlot(slot, 'start');
        String endTime = _getTimeForSlot(requiredSlots == 2 ? slot + 1 : slot, 'end');

        return Routine(
          id: routineId,
          type: 'class',
          departmentId: departmentId.toString(),
          batchId: batchId.toString(),
          courseId: courseId,
          courseCode: course.code,
          courseTitle: course.title,
          teacherId: teacherId.toString(),
          teacherName: teacher.name,
          roomId: availableRoom.id.toString(),
          roomNo: availableRoom.roomNo,
          day: day,
          slot: slot,
          endSlot: requiredSlots == 2 ? slot + 1 : null,
          startTime: startTime,
          endTime: endTime,
          status: 'scheduled',
        );
      }
    }

    return null;
  }

  bool _isTeacherAvailable({
    required Teacher teacher,
    required String day,
    required int slot,
    required int requiredSlots,
    required List<Routine> existingRoutines,
  }) {
    // If teacher has no availability set, assume they are available
    if (teacher.availableDays.isEmpty || teacher.availableSlots.isEmpty) {
      return true;
    }

    if (!teacher.availableDays.contains(day)) return false;
    if (!teacher.availableSlots.contains(slot)) return false;
    if (requiredSlots == 2 && !teacher.availableSlots.contains(slot + 1)) return false;

    int? teacherId = teacher.id;
    if (teacherId == null) return false;

    return !existingRoutines.any((r) =>
    r.teacherId == teacherId.toString() &&
        r.day == day &&
        ((requiredSlots == 1 && r.slot == slot) ||
            (requiredSlots == 2 && r.slot <= slot && (r.endSlot ?? slot) > slot))
    );
  }

  // Safe room finder
  Room? _findAvailableRoomSafe({
    required List<Room> rooms,
    required String day,
    required int slot,
    required int requiredSlots,
    required String courseType,
    required List<Routine> existingRoutines,
  }) {
    List<Room> availableRooms = [];

    for (var room in rooms) {
      if (room.type == courseType && room.id != null) {
        availableRooms.add(room);
      }
    }

    if (availableRooms.isEmpty) {
      // If no room of specific type, try any room
      for (var room in rooms) {
        if (room.id != null) {
          availableRooms.add(room);
        }
      }
    }

    if (availableRooms.isEmpty) {
      return null;
    }

    Set<String?> busyRoomIds = {};
    for (var routine in existingRoutines) {
      if (routine.roomId != null &&
          routine.day == day &&
          ((requiredSlots == 1 && routine.slot == slot) ||
              (requiredSlots == 2 && routine.slot <= slot && (routine.endSlot ?? slot) > slot))) {
        busyRoomIds.add(routine.roomId);
      }
    }

    for (var room in availableRooms) {
      if (!busyRoomIds.contains(room.id?.toString())) {
        return room;
      }
    }

    return null;
  }

  String _getTimeForSlot(int slot, String type) {
    var slotData = _timeSlots.firstWhere((s) => s['slot'] == slot);
    return type == 'start' ? slotData['start'] as String : slotData['end'] as String;
  }

  // ========== AUTO-CONFLICT RESOLUTION METHODS ==========

  Future<List<Routine>> _autoResolveConflicts(
      List<Routine> routines,
      List<Room> rooms,
      List<Teacher> teachers,
      ) async {
    List<Routine> resolved = List.from(routines);
    List<Conflict> conflicts = _conflictDetector.detectConflicts(resolved);

    if (conflicts.isEmpty) {
      print('  ✅ No conflicts found!');
      return resolved;
    }

    print('  ⚠️ Found ${conflicts.length} conflicts. Auto-resolving...');

    int maxAttempts = 10;
    int attempt = 0;
    int previousConflictCount = conflicts.length;

    while (conflicts.isNotEmpty && attempt < maxAttempts) {
      print('    🔄 Resolution attempt ${attempt + 1}, ${conflicts.length} conflicts remaining');

      for (var conflict in conflicts) {
        if (conflict.type == 'teacher') {
          resolved = await _resolveTeacherConflict(resolved, conflict, teachers, rooms);
        } else if (conflict.type == 'room') {
          resolved = await _resolveRoomConflict(resolved, conflict, rooms);
        } else if (conflict.type == 'batch') {
          resolved = await _resolveBatchConflict(resolved, conflict);
        }
      }

      conflicts = _conflictDetector.detectConflicts(resolved);

      if (conflicts.length >= previousConflictCount) {
        print('    ⚠️ No improvement, stopping attempts');
        break;
      }
      previousConflictCount = conflicts.length;
      attempt++;
    }

    int finalConflicts = conflicts.length;
    if (finalConflicts > 0) {
      print('    ⚠️ $finalConflicts conflicts could not be auto-resolved');
    } else {
      print('    ✅ All conflicts resolved!');
    }

    return resolved;
  }

  Future<List<Routine>> _resolveTeacherConflict(
      List<Routine> routines,
      Conflict conflict,
      List<Teacher> teachers,
      List<Room> rooms,
      ) async {
    List<Routine> resolved = List.from(routines);
    List<String> days = ['Saturday', 'Sunday', 'Monday', 'Tuesday'];

    for (int i = 1; i < conflict.conflictingRoutines.length; i++) {
      var routine = conflict.conflictingRoutines[i];
      bool moved = false;

      for (var day in days) {
        for (int slot = 1; slot <= 4; slot++) {
          bool teacherFree = !resolved.any((r) =>
          r.teacherId == routine.teacherId &&
              r.day == day &&
              r.slot == slot
          );

          if (!teacherFree) continue;

          int requiredSlots = (routine.endSlot != null && routine.endSlot! > routine.slot) ? 2 : 1;

          // Determine course type based on required slots
          String courseType = (requiredSlots == 2) ? 'Lab' : 'Theory';

          Room? room = _findAvailableRoomSafe(
            rooms: rooms,
            day: day,
            slot: slot,
            requiredSlots: requiredSlots,
            courseType: courseType,
            existingRoutines: resolved,
          );

          if (room != null && room.id != null) {
            int index = resolved.indexWhere((r) => r.id == routine.id);
            if (index != -1) {
              Routine updatedRoutine = Routine(
                id: routine.id,
                type: routine.type,
                departmentId: routine.departmentId,
                batchId: routine.batchId,
                courseId: routine.courseId,
                courseCode: routine.courseCode,
                courseTitle: routine.courseTitle,
                teacherId: routine.teacherId,
                teacherName: routine.teacherName,
                roomId: room.id.toString(),
                roomNo: room.roomNo,
                day: day,
                slot: slot,
                endSlot: requiredSlots == 2 ? slot + 1 : null,
                startTime: _getTimeForSlot(slot, 'start'),
                endTime: _getTimeForSlot(requiredSlots == 2 ? slot + 1 : slot, 'end'),
                status: 'auto_resolved',
              );
              resolved[index] = updatedRoutine;
              moved = true;
              print('        🔄 Auto-resolved teacher conflict: moved ${routine.courseCode} to $day Slot $slot');
              break;
            }
          }
        }
        if (moved) break;
      }
    }

    return resolved;
  }

  Future<List<Routine>> _resolveRoomConflict(
      List<Routine> routines,
      Conflict conflict,
      List<Room> rooms,
      ) async {
    List<Routine> resolved = List.from(routines);
    List<String> days = ['Saturday', 'Sunday', 'Monday', 'Tuesday'];

    for (int i = 1; i < conflict.conflictingRoutines.length; i++) {
      var routine = conflict.conflictingRoutines[i];
      bool moved = false;

      for (var day in days) {
        for (int slot = 1; slot <= 4; slot++) {
          int requiredSlots = (routine.endSlot != null && routine.endSlot! > routine.slot) ? 2 : 1;

          // Determine course type based on required slots
          String courseType = (requiredSlots == 2) ? 'Lab' : 'Theory';

          Room? availableRoom = _findAvailableRoomSafe(
            rooms: rooms,
            day: day,
            slot: slot,
            requiredSlots: requiredSlots,
            courseType: courseType,
            existingRoutines: resolved,
          );

          if (availableRoom != null && availableRoom.id != null) {
            int index = resolved.indexWhere((r) => r.id == routine.id);
            if (index != -1) {
              Routine updatedRoutine = Routine(
                id: routine.id,
                type: routine.type,
                departmentId: routine.departmentId,
                batchId: routine.batchId,
                courseId: routine.courseId,
                courseCode: routine.courseCode,
                courseTitle: routine.courseTitle,
                teacherId: routine.teacherId,
                teacherName: routine.teacherName,
                roomId: availableRoom.id.toString(),
                roomNo: availableRoom.roomNo,
                day: day,
                slot: slot,
                endSlot: routine.endSlot,
                startTime: routine.startTime,
                endTime: routine.endTime,
                status: 'auto_resolved',
              );
              resolved[index] = updatedRoutine;
              moved = true;
              print('        🔄 Auto-resolved room conflict: moved ${routine.courseCode} to room ${availableRoom.roomNo}');
              break;
            }
          }
        }
        if (moved) break;
      }
    }

    return resolved;
  }

  Future<List<Routine>> _resolveBatchConflict(
      List<Routine> routines,
      Conflict conflict,
      ) async {
    List<Routine> resolved = List.from(routines);
    List<String> days = ['Saturday', 'Sunday', 'Monday', 'Tuesday'];

    for (int i = 1; i < conflict.conflictingRoutines.length; i++) {
      var routine = conflict.conflictingRoutines[i];
      bool moved = false;

      for (var day in days) {
        for (int slot = 1; slot <= 4; slot++) {
          bool batchFree = !resolved.any((r) =>
          r.batchId == routine.batchId &&
              r.day == day &&
              r.slot == slot
          );

          if (batchFree) {
            int index = resolved.indexWhere((r) => r.id == routine.id);
            if (index != -1) {
              int requiredSlots = (routine.endSlot != null && routine.endSlot! > routine.slot) ? 2 : 1;

              Routine updatedRoutine = Routine(
                id: routine.id,
                type: routine.type,
                departmentId: routine.departmentId,
                batchId: routine.batchId,
                courseId: routine.courseId,
                courseCode: routine.courseCode,
                courseTitle: routine.courseTitle,
                teacherId: routine.teacherId,
                teacherName: routine.teacherName,
                roomId: routine.roomId,
                roomNo: routine.roomNo,
                day: day,
                slot: slot,
                endSlot: requiredSlots == 2 ? slot + 1 : null,
                startTime: _getTimeForSlot(slot, 'start'),
                endTime: _getTimeForSlot(requiredSlots == 2 ? slot + 1 : slot, 'end'),
                status: 'auto_resolved',
              );
              resolved[index] = updatedRoutine;
              moved = true;
              print('        🔄 Auto-resolved batch conflict: moved ${routine.courseCode} to $day Slot $slot');
              break;
            }
          }
        }
        if (moved) break;
      }
    }

    return resolved;
  }
}