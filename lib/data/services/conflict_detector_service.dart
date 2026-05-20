// lib/data/services/conflict_detector_service.dart

import '../models/routine_model.dart';
import '../models/conflict_model.dart';
import '../models/room_model.dart';
import '../models/teacher_model.dart';

class ConflictDetectorService {

  List<Conflict> detectConflicts(List<Routine> routines) {
    List<Conflict> conflicts = [];

    // Teacher conflicts (same teacher at same time)
    Map<String, List<Routine>> teacherMap = {};
    for (var r in routines) {
      if (r.teacherId != null && r.teacherId!.isNotEmpty) {
        String key = '${r.teacherId}_${r.day}_${r.slot}';
        teacherMap.putIfAbsent(key, () => []).add(r);
      }
    }
    for (var entry in teacherMap.entries) {
      if (entry.value.length > 1) {
        conflicts.add(Conflict(
          type: 'teacher',
          description: 'Teacher ${entry.value.first.teacherName} has multiple classes at same time',
          teacherId: int.tryParse(entry.value.first.teacherId ?? ''),
          roomId: null,
          batchId: null,
          day: entry.value.first.day,
          slot: entry.value.first.slot,
          conflictingRoutines: entry.value,
          suggestions: [
            {'action': 'move', 'suggestion': 'Move to different time slot', 'priority': 1},
            {'action': 'change_teacher', 'suggestion': 'Assign different teacher', 'priority': 2},
          ],
        ));
      }
    }

    // Room conflicts
    Map<String, List<Routine>> roomMap = {};
    for (var r in routines) {
      if (r.roomId != null && r.roomId!.isNotEmpty) {
        String key = '${r.roomId}_${r.day}_${r.slot}';
        roomMap.putIfAbsent(key, () => []).add(r);
      }
    }
    for (var entry in roomMap.entries) {
      if (entry.value.length > 1) {
        conflicts.add(Conflict(
          type: 'room',
          description: 'Room ${entry.value.first.roomNo} has multiple classes',
          teacherId: null,
          roomId: int.tryParse(entry.value.first.roomId ?? ''),
          batchId: null,
          day: entry.value.first.day,
          slot: entry.value.first.slot,
          conflictingRoutines: entry.value,
          suggestions: [
            {'action': 'change_room', 'suggestion': 'Use different room', 'priority': 1},
            {'action': 'move', 'suggestion': 'Change time slot', 'priority': 2},
          ],
        ));
      }
    }

    // Batch conflicts
    Map<String, List<Routine>> batchMap = {};
    for (var r in routines) {
      if (r.batchId != null && r.batchId!.isNotEmpty) {
        String key = '${r.batchId}_${r.day}_${r.slot}';
        batchMap.putIfAbsent(key, () => []).add(r);
      }
    }
    for (var entry in batchMap.entries) {
      if (entry.value.length > 1) {
        conflicts.add(Conflict(
          type: 'batch',
          description: 'Batch ${entry.value.first.batchId} has multiple classes',
          teacherId: null,
          roomId: null,
          batchId: int.tryParse(entry.value.first.batchId ?? '0'),
          day: entry.value.first.day,
          slot: entry.value.first.slot,
          conflictingRoutines: entry.value,
          suggestions: [
            {'action': 'move', 'suggestion': 'Change time slot', 'priority': 1},
            {'action': 'swap', 'suggestion': 'Swap with other batch', 'priority': 2},
          ],
        ));
      }
    }

    return conflicts;
  }

  // Mark conflicts and return
  Future<List<Routine>> autoResolveConflicts(
      List<Routine> routines, {
        required List<Room> rooms,
        required List<Teacher> teachers,
      }) async {
    List<Routine> resolved = List.from(routines);
    List<Conflict> conflicts = detectConflicts(resolved);

    if (conflicts.isEmpty) return resolved;

    print('  ⚠️ Found ${conflicts.length} conflicts');

    // Mark conflicts by creating new Routine instances
    for (var conflict in conflicts) {
      for (var routine in conflict.conflictingRoutines) {
        int index = resolved.indexWhere((r) => r.id == routine.id);
        if (index != -1) {
          // Create a new Routine instance with updated status
          Routine updatedRoutine = Routine(
            id: resolved[index].id,
            type: resolved[index].type,
            departmentId: resolved[index].departmentId,
            batchId: resolved[index].batchId,
            courseId: resolved[index].courseId,
            courseCode: resolved[index].courseCode,
            courseTitle: resolved[index].courseTitle,
            teacherId: resolved[index].teacherId,
            teacherName: resolved[index].teacherName,
            roomId: resolved[index].roomId,
            roomNo: resolved[index].roomNo,
            day: resolved[index].day,
            slot: resolved[index].slot,
            endSlot: resolved[index].endSlot,
            startTime: resolved[index].startTime,
            endTime: resolved[index].endTime,
            status: 'conflict',
            conflictReason: conflict.description,
            date: resolved[index].date,
          );
          resolved[index] = updatedRoutine;
        }
      }
    }

    return resolved;
  }

  // Check if a specific routine has conflicts
  List<Conflict> checkRoutineConflicts(Routine routine, List<Routine> allRoutines) {
    List<Routine> routinesToCheck = [routine];
    List<Routine> otherRoutines = allRoutines.where((r) => r.id != routine.id).toList();

    List<Routine> combined = [...routinesToCheck, ...otherRoutines];
    return detectConflicts(combined).where((c) =>
        c.conflictingRoutines.any((r) => r.id == routine.id)
    ).toList();
  }

  // Get conflict summary
  Map<String, int> getConflictSummary(List<Conflict> conflicts) {
    return {
      'total': conflicts.length,
      'teacher': conflicts.where((c) => c.type == 'teacher').length,
      'room': conflicts.where((c) => c.type == 'room').length,
      'batch': conflicts.where((c) => c.type == 'batch').length,
    };
  }

  // Check if a time slot is available for a specific resource
  bool isSlotAvailable({
    required List<Routine> routines,
    required String? resourceId,
    required String resourceType, // 'teacher', 'room', 'batch'
    required String day,
    required int slot,
    int? excludeRoutineId,
  }) {
    if (resourceId == null || resourceId.isEmpty) return true;

    return !routines.any((r) {
      if (excludeRoutineId != null && r.id == excludeRoutineId) return false;

      switch (resourceType) {
        case 'teacher':
          return r.teacherId == resourceId && r.day == day && r.slot == slot;
        case 'room':
          return r.roomId == resourceId && r.day == day && r.slot == slot;
        case 'batch':
          return r.batchId == resourceId && r.day == day && r.slot == slot;
        default:
          return false;
      }
    });
  }
}