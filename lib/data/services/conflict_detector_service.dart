import '../models/routine_model.dart';
import '../models/conflict_model.dart';

class ConflictDetectorService {

  // Detect all types of conflicts
  List<Conflict> detectConflicts(List<Routine> routines) {
    List<Conflict> conflicts = [];

    conflicts.addAll(_detectTeacherConflicts(routines));
    conflicts.addAll(_detectRoomConflicts(routines));
    conflicts.addAll(_detectBatchConflicts(routines));

    return conflicts;
  }

  // Teacher conflicts (same teacher at same time)
  List<Conflict> _detectTeacherConflicts(List<Routine> routines) {
    List<Conflict> conflicts = [];
    Map<String, List<Routine>> teacherSlotMap = {};

    for (var routine in routines) {
      if (routine.teacherId == null) continue;

      String key = '${routine.teacherId}_${routine.day}_${routine.slot}';
      if (!teacherSlotMap.containsKey(key)) {
        teacherSlotMap[key] = [];
      }
      teacherSlotMap[key]!.add(routine);
    }

    teacherSlotMap.forEach((key, routines) {
      if (routines.length > 1) {
        conflicts.add(Conflict(
          type: 'teacher',
          description: 'Teacher ${routines.first.teacherName} has multiple classes at same time',
          teacherId: routines.first.teacherId,
          day: routines.first.day,
          slot: routines.first.slot,
          conflictingRoutines: routines,
          suggestions: _generateSuggestions(routines),
        ));
      }
    });

    return conflicts;
  }

  // Room conflicts (same room at same time)
  List<Conflict> _detectRoomConflicts(List<Routine> routines) {
    List<Conflict> conflicts = [];
    Map<String, List<Routine>> roomSlotMap = {};

    for (var routine in routines) {
      if (routine.roomId == null) continue;

      String key = '${routine.roomId}_${routine.day}_${routine.slot}';
      if (!roomSlotMap.containsKey(key)) {
        roomSlotMap[key] = [];
      }
      roomSlotMap[key]!.add(routine);
    }

    roomSlotMap.forEach((key, routines) {
      if (routines.length > 1) {
        conflicts.add(Conflict(
          type: 'room',
          description: 'Room ${routines.first.roomNo} has multiple classes at same time',
          roomId: routines.first.roomId,
          day: routines.first.day,
          slot: routines.first.slot,
          conflictingRoutines: routines,
          suggestions: _generateSuggestions(routines),
        ));
      }
    });

    return conflicts;
  }

  // Batch conflicts (same batch at same time)
  List<Conflict> _detectBatchConflicts(List<Routine> routines) {
    List<Conflict> conflicts = [];
    Map<String, List<Routine>> batchSlotMap = {};

    for (var routine in routines) {
      if (routine.batchId == null) continue;

      String key = '${routine.batchId}_${routine.day}_${routine.slot}';
      if (!batchSlotMap.containsKey(key)) {
        batchSlotMap[key] = [];
      }
      batchSlotMap[key]!.add(routine);
    }

    batchSlotMap.forEach((key, routines) {
      if (routines.length > 1) {
        conflicts.add(Conflict(
          type: 'batch',
          description: 'Batch ${routines.first.batchId} has multiple classes at same time',
          batchId: routines.first.batchId,
          day: routines.first.day,
          slot: routines.first.slot,
          conflictingRoutines: routines,
          suggestions: _generateSuggestions(routines),
        ));
      }
    });

    return conflicts;
  }

  // Generate alternative suggestions
  List<Map<String, dynamic>> _generateSuggestions(List<Routine> routines) {
    List<Map<String, dynamic>> suggestions = [];

    // Suggest different slots for each routine
    for (var routine in routines) {
      for (int newSlot = 1; newSlot <= 4; newSlot++) {
        if (newSlot != routine.slot) {
          suggestions.add({
            'routineId': routine.id,
            'currentSlot': routine.slot,
            'suggestedSlot': newSlot,
            'currentTime': '${routine.startTime}-${routine.endTime}',
            'suggestedTime': _getTimeForSlot(newSlot),
          });
        }
      }
    }

    return suggestions;
  }

  String _getTimeForSlot(int slot) {
    switch(slot) {
      case 1: return '9:30-11:00';
      case 2: return '11:10-12:40';
      case 3: return '14:00-15:30';
      case 4: return '15:40-17:10';
      default: return '';
    }
  }
}