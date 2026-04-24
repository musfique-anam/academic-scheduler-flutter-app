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

// Generate class routine
  Future<List<Routine>> generateClassRoutine({
    required int departmentId,
    required String programType,
    required List<Batch> batches,
    required List<Course> courses,
    required List<Teacher> teachers,
    required List<Room> rooms,
    Function(double)? onProgress,  // ← FIXED: Added ? to make it optional
  }) async {
    List<Routine> routines = [];
    int totalSteps = batches.length * courses.length;
    int currentStep = 0;

    // For each batch
    for (var batch in batches) {
      // Get courses for this batch
      var batchCourses = courses.where((c) => c.batchId == batch.id).toList();

      // For each course
      for (var course in batchCourses) {
        currentStep++;
        if (onProgress != null) {  // ← Check if callback exists
          onProgress(currentStep / totalSteps);
        }

        // Calculate required classes (1 credit = 1 class per week)
        int requiredClasses = course.credit.round();

        // Assign classes
        for (int i = 0; i < requiredClasses; i++) {
          var assigned = await _assignClass(
            batch: batch,
            course: course,
            teachers: teachers,
            rooms: rooms,
            allowedDays: programType == 'HSC'
                ? ['Saturday', 'Sunday', 'Monday', 'Tuesday']
                : ['Friday', 'Saturday'],
            existingRoutines: routines,
          );

          if (assigned != null) {
            routines.add(assigned);
          }
        }
      }
    }

    return routines;
  }

  // Assign a single class
  Future<Routine?> _assignClass({
    required Batch batch,
    required Course course,
    required List<Teacher> teachers,
    required List<Room> rooms,
    required List<String> allowedDays,
    required List<Routine> existingRoutines,
  }) async {
    // Try each day
    for (var day in allowedDays) {
      // Try each slot
      for (int slot = 1; slot <= 4; slot++) {
        // For lab courses, need 2 consecutive slots
        int requiredSlots = course.type == 'Lab' ? 2 : 1;

        if (course.type == 'Lab' && slot > 3) continue; // Lab needs slots 1-3

        // Find available teacher
        var availableTeacher = _findAvailableTeacher(
          teachers: teachers,
          day: day,
          slot: slot,
          requiredSlots: requiredSlots,
          existingRoutines: existingRoutines,
        );

        if (availableTeacher == null) continue;

        // Find available room
        var availableRoom = _findAvailableRoom(
          rooms: rooms,
          day: day,
          slot: slot,
          requiredSlots: requiredSlots,
          courseType: course.type,
          existingRoutines: existingRoutines,
        );

        if (availableRoom == null) continue;

        // Check batch availability
        bool batchAvailable = _isBatchAvailable(
          batchId: batch.id!,
          day: day,
          slot: slot,
          requiredSlots: requiredSlots,
          existingRoutines: existingRoutines,
        );

        if (!batchAvailable) continue;

        // All checks passed - assign
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
          endSlot: course.type == 'Lab' ? slot + 1 : null,
          startTime: _getTimeForSlot(slot, 'start'),
          endTime: _getTimeForSlot(course.type == 'Lab' ? slot + 1 : slot, 'end'),
          status: 'scheduled',
        );
      }
    }

    // Could not assign - return null (will be handled as conflict)
    return null;
  }

  Teacher? _findAvailableTeacher({
    required List<Teacher> teachers,
    required String day,
    required int slot,
    required int requiredSlots,
    required List<Routine> existingRoutines,
  }) {
    // Get busy teachers for this time
    var busyTeacherIds = existingRoutines
        .where((r) =>
    r.day == day &&
        ((requiredSlots == 1 && r.slot == slot) ||
            (requiredSlots == 2 && r.slot <= slot && r.endSlot! > slot))
    )
        .map((r) => r.teacherId)
        .toSet();

    return teachers.firstWhere(
          (t) =>
      !busyTeacherIds.contains(t.id) &&
          t.availableDays.contains(day) &&
          t.availableSlots.contains(slot) &&
          (requiredSlots == 1 || t.availableSlots.contains(slot + 1)),
      orElse: () => null as Teacher,
    );
  }

  Room? _findAvailableRoom({
    required List<Room> rooms,
    required String day,
    required int slot,
    required int requiredSlots,
    required String courseType,
    required List<Routine> existingRoutines,
  }) {
    // Filter rooms by type
    var availableRooms = rooms.where((r) => r.type == courseType).toList();

    // Get busy rooms for this time
    var busyRoomIds = existingRoutines
        .where((r) =>
    r.day == day &&
        ((requiredSlots == 1 && r.slot == slot) ||
            (requiredSlots == 2 && r.slot <= slot && r.endSlot! > slot))
    )
        .map((r) => r.roomId)
        .toSet();

    return availableRooms.firstWhere(
          (r) => !busyRoomIds.contains(r.id),
      orElse: () => null as Room,
    );
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
        ((requiredSlots == 1 && r.slot == slot) ||
            (requiredSlots == 2 && r.slot <= slot && r.endSlot! > slot)));
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