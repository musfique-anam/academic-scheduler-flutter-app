import '../models/routine_model.dart';
import '../models/batch_model.dart';
import '../models/course_model.dart';
import '../models/teacher_model.dart';
import '../models/room_model.dart';
import 'conflict_detector_service.dart';
import 'workload_validator_service.dart';

class RoutineGeneratorService {
  final ConflictDetectorService _conflictDetector = ConflictDetectorService();
  final WorkloadValidatorService _workloadValidator = WorkloadValidatorService();

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

    // Filter batches to only the relevant department
    final deptBatches = batches.where((b) => b.departmentId == departmentId).toList();

    // Determine allowed days based on programType
    final allowedDays = programType == 'HSC'
        ? ['Saturday', 'Sunday', 'Monday', 'Tuesday']
        : ['Saturday', 'Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday'];

    int totalSteps = deptBatches.fold(0, (sum, b) {
      return sum + courses.where((c) => c.batchId == b.id).length;
    });
    int currentStep = 0;

    for (var batch in deptBatches) {
      // Strict batchId match — no broken fallback
      final batchCourses = courses.where((c) => c.batchId == batch.id).toList();
      print("Batch ${batch.id} (${batch.programType}): ${batchCourses.length} courses");

      for (var course in batchCourses) {
        currentStep++;
        if (onProgress != null && totalSteps > 0) {
          onProgress(currentStep / totalSteps);
        }

        final requiredClasses = course.credit.round();
        for (int i = 0; i < requiredClasses; i++) {
          final assigned = await _assignClass(
            batch: batch,
            course: course,
            teachers: teachers,
            rooms: rooms,
            allowedDays: allowedDays,
            existingRoutines: routines,
          );
          if (assigned != null) {
            routines.add(assigned);
            print("  ✅ ${course.code} -> ${assigned.day} Slot:${assigned.slot} ${assigned.teacherName} Room:${assigned.roomNo}");
          } else {
            print("  ⚠️ Could not assign: ${course.code} (class ${i + 1}/$requiredClasses)");
          }
        }
      }
    }

    print("=== Done: ${routines.length} classes scheduled ===");
    return routines;
  }

  Future<Routine?> _assignClass({
    required Batch batch,
    required Course course,
    required List<Teacher> teachers,
    required List<Room> rooms,
    required List<String> allowedDays,
    required List<Routine> existingRoutines,
  }) async {
    final isLab = course.type == 'Lab';
    final requiredSlots = isLab ? 2 : 1;
    final maxStartSlot = isLab ? 3 : 4;

    for (var day in allowedDays) {
      for (int slot = 1; slot <= maxStartSlot; slot++) {

        if (!_isBatchAvailable(
          batchId: batch.id!,
          day: day,
          slot: slot,
          requiredSlots: requiredSlots,
          existingRoutines: existingRoutines,
        )) continue;

        final availableRoom = _findAvailableRoom(
          rooms: rooms,
          day: day,
          slot: slot,
          requiredSlots: requiredSlots,
          courseType: course.type,
          existingRoutines: existingRoutines,
        );
        if (availableRoom == null) continue;

        final availableTeacher = _findAvailableTeacher(
          teachers: teachers,
          day: day,
          slot: slot,
          requiredSlots: requiredSlots,
          existingRoutines: existingRoutines,
          departmentId: batch.departmentId,
          preferredTeacherId: course.teacherId,
        );
        if (availableTeacher == null) continue;

        return Routine(
          type: 'class',
          departmentId: batch.departmentId,
          batchId: batch.id,
          courseId: course.id!,
          courseCode: course.code,
          courseTitle: course.title,
          teacherId: availableTeacher.id,
          teacherName: availableTeacher.name,
          roomId: availableRoom.id,
          roomNo: availableRoom.roomNo,
          day: day,
          slot: slot,
          endSlot: isLab ? slot + 1 : null,
          startTime: _getTimeForSlot(slot, 'start'),
          endTime: _getTimeForSlot(isLab ? slot + 1 : slot, 'end'),
          status: 'scheduled',
        );
      }
    }
    return null;
  }

  Teacher? _findAvailableTeacher({
    required List<Teacher> teachers,
    required String day,
    required int slot,
    required int requiredSlots,
    required List<Routine> existingRoutines,
    required int departmentId,
    int? preferredTeacherId,
  }) {
    final busyTeacherIds = existingRoutines
        .where((r) => r.day == day && _slotsOverlap(r.slot, r.endSlot, slot, slot + requiredSlots - 1))
        .map((r) => r.teacherId)
        .toSet();

    final candidates = teachers
        .where((t) => t.departmentId == departmentId && !busyTeacherIds.contains(t.id))
        .toList();

    if (candidates.isEmpty) return null;

    bool isAvailable(Teacher t) {
      // If teacher hasn't filled availability profile, treat as always available
      if (t.availableDays.isEmpty || t.availableSlots.isEmpty) return true;
      if (!t.availableDays.contains(day)) return false;
      if (!t.availableSlots.contains(slot)) return false;
      if (requiredSlots == 2 && !t.availableSlots.contains(slot + 1)) return false;
      return true;
    }

    // Prefer course's assigned teacher
    if (preferredTeacherId != null) {
      try {
        return candidates.firstWhere((t) => t.id == preferredTeacherId && isAvailable(t));
      } catch (_) {}
    }

    try {
      return candidates.firstWhere(isAvailable);
    } catch (_) {
      return null;
    }
  }

  Room? _findAvailableRoom({
    required List<Room> rooms,
    required String day,
    required int slot,
    required int requiredSlots,
    required String courseType,
    required List<Routine> existingRoutines,
  }) {
    // Case-insensitive type match
    final typeRooms = rooms
        .where((r) => r.type.toLowerCase() == courseType.toLowerCase())
        .toList();

    final busyRoomIds = existingRoutines
        .where((r) => r.day == day && _slotsOverlap(r.slot, r.endSlot, slot, slot + requiredSlots - 1))
        .map((r) => r.roomId)
        .toSet();

    try {
      return typeRooms.firstWhere((r) => !busyRoomIds.contains(r.id));
    } catch (_) {
      return null;
    }
  }

  bool _isBatchAvailable({
    required int batchId,
    required String day,
    required int slot,
    required int requiredSlots,
    required List<Routine> existingRoutines,
  }) {
    return !existingRoutines.any((r) =>
        r.batchId == batchId &&
        r.day == day &&
        _slotsOverlap(r.slot, r.endSlot, slot, slot + requiredSlots - 1));
  }

  // Centralized slot overlap check
  bool _slotsOverlap(int? existStart, int? existEnd, int newStart, int newEnd) {
    final eStart = existStart ?? 0;
    final eEnd = existEnd ?? eStart;
    return eStart <= newEnd && eEnd >= newStart;
  }

  String _getTimeForSlot(int slot, String type) {
    switch (slot) {
      case 1: return type == 'start' ? '9:30' : '11:00';
      case 2: return type == 'start' ? '11:10' : '12:40';
      case 3: return type == 'start' ? '14:00' : '15:30';
      case 4: return type == 'start' ? '15:40' : '17:10';
      default: return '';
    }
  }
}