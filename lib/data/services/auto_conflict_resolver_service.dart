import '../models/conflict_model.dart';
import '../models/routine_model.dart';
import '../repositories/teacher_repository.dart';
import '../repositories/room_repository.dart';
import '../repositories/course_repository.dart';
import '../core/constants/time_slots.dart';
import 'conflict_detector_service.dart';
import 'workload_validator_service.dart';

class ResolverResult {
  final int resolvedCount;
  final List<ConflictModel> unresolved;
  final List<RoutineModel> updatedRoutines;

  ResolverResult({
    required this.resolvedCount,
    required this.unresolved,
    required this.updatedRoutines,
  });
}

class AutoConflictResolverService {
  final ConflictDetectorService detector;
  final TeacherRepository teacherRepo;
  final RoomRepository roomRepo;
  final CourseRepository courseRepo;
  final WorkloadValidatorService workloadValidator;

  AutoConflictResolverService({
    required this.detector,
    required this.teacherRepo,
    required this.roomRepo,
    required this.courseRepo,
    required this.workloadValidator,
  });

  Future<ResolverResult> resolveAll(List<RoutineModel> routines) async {
    final List<RoutineModel> working = List.from(routines);
    final List<ConflictModel> unresolved = [];
    int resolvedCount = 0;
    int iteration = 0;
    const int maxIterations = 5;

    while (iteration < maxIterations) {
      final conflicts = await detector.detectAllConflicts(working);
      if (conflicts.isEmpty) break;

      bool madeProgress = false;
      for (final conflict in conflicts) {
        final fixed = await _tryResolve(conflict, working);
        if (fixed) {
          resolvedCount++;
          madeProgress = true;
        }
      }

      if (!madeProgress) {
        unresolved.addAll(conflicts);
        break;
      }
      iteration++;
    }

    return ResolverResult(
      resolvedCount: resolvedCount,
      unresolved: unresolved,
      updatedRoutines: working,
    );
  }

  Future<bool> _tryResolve(
      ConflictModel conflict, List<RoutineModel> routines) async {
    if (await _tryReschedule(conflict, routines)) return true;
    if (await _tryReassignRoom(conflict, routines)) return true;
    if (await _tryReassignTeacher(conflict, routines)) return true;
    return false;
  }

  Future<bool> _tryReschedule(
      ConflictModel conflict, List<RoutineModel> routines) async {
    final targetIndex = routines.indexWhere((r) => r.id == conflict.routineId2);
    if (targetIndex == -1) return false;
    final target = routines[targetIndex];

    for (final day in TimeSlots.days) {
      for (final slot in TimeSlots.slots) {
        final candidate = target.copyWith(day: day, timeSlot: slot);
        if (_isSlotFree(candidate, routines, excludeId: target.id)) {
          routines[targetIndex] = candidate;
          return true;
        }
      }
    }
    return false;
  }

  Future<bool> _tryReassignRoom(
      ConflictModel conflict, List<RoutineModel> routines) async {
    final targetIndex = routines.indexWhere((r) => r.id == conflict.routineId2);
    if (targetIndex == -1) return false;
    final target = routines[targetIndex];

    final allRooms = await roomRepo.getAllRooms();
    for (final room in allRooms) {
      if (room.id == target.roomId) continue;
      final candidate = target.copyWith(roomId: room.id);
      if (_isSlotFree(candidate, routines, excludeId: target.id)) {
        routines[targetIndex] = candidate;
        return true;
      }
    }
    return false;
  }

  Future<bool> _tryReassignTeacher(
      ConflictModel conflict, List<RoutineModel> routines) async {
    final targetIndex = routines.indexWhere((r) => r.id == conflict.routineId2);
    if (targetIndex == -1) return false;
    final target = routines[targetIndex];

    final allTeachers = await teacherRepo.getAllTeachers();
    for (final teacher in allTeachers) {
      if (teacher.id == target.teacherId) continue;
      final candidate = target.copyWith(teacherId: teacher.id);
      if (_isSlotFree(candidate, routines, excludeId: target.id)) {
        routines[targetIndex] = candidate;
        return true;
      }
    }
    return false;
  }

  bool _isSlotFree(
    RoutineModel candidate,
    List<RoutineModel> routines, {
    required int excludeId,
  }) {
    for (final r in routines) {
      if (r.id == excludeId) continue;
      if (r.day != candidate.day || r.timeSlot != candidate.timeSlot) continue;
      if (r.teacherId == candidate.teacherId) return false;
      if (r.roomId == candidate.roomId) return false;
      if (r.batchId == candidate.batchId) return false;
    }
    return true;
  }
}