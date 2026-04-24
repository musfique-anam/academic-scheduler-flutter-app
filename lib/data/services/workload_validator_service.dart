import '../models/routine_model.dart';
import '../models/teacher_model.dart';
import '../models/conflict_model.dart';

class WorkloadValidatorService {

  // Validate teacher workloads
  List<WorkloadInfo> validateTeacherWorkloads(
      List<Teacher> teachers,
      List<Routine> routines,
      ) {
    List<WorkloadInfo> workloads = [];

    for (var teacher in teachers) {
      // Get all classes for this teacher
      var teacherClasses = routines.where((r) => r.teacherId == teacher.id).toList();

      // Calculate total credits (1 credit = 1 class per week)
      int assignedCredits = teacherClasses.length; // Each class = 1 credit

      bool isOverloaded = assignedCredits > teacher.maxLoad;

      workloads.add(WorkloadInfo(
        teacherId: teacher.id!,
        teacherName: teacher.name,
        assignedCredits: assignedCredits,
        maxLoad: teacher.maxLoad,
        isOverloaded: isOverloaded,
        assignedClasses: teacherClasses,
      ));
    }

    return workloads;
  }

  // Validate batch course credits
  Map<int, Map<String, dynamic>> validateBatchCredits(
      List<dynamic> batches,
      List<Routine> routines,
      ) {
    Map<int, Map<String, dynamic>> batchValidation = {};

    for (var batch in batches) {
      var batchClasses = routines.where((r) => r.batchId == batch.id).toList();

      // Group by course
      Map<int, int> courseCount = {};
      for (var routine in batchClasses) {
        if (!courseCount.containsKey(routine.courseId)) {
          courseCount[routine.courseId] = 0;
        }
        courseCount[routine.courseId] = courseCount[routine.courseId]! + 1;
      }

      batchValidation[batch.id] = {
        'batchName': 'Batch ${batch.batchNo}',
        'totalClasses': batchClasses.length,
        'courseCounts': courseCount,
        'isValid': true, // Will be checked against course credits
      };
    }

    return batchValidation;
  }

  // Get overloaded teachers
  List<WorkloadInfo> getOverloadedTeachers(List<WorkloadInfo> workloads) {
    return workloads.where((w) => w.isOverloaded).toList();
  }

  // Get available teachers for a slot
  List<Teacher> getAvailableTeachers(
      List<Teacher> teachers,
      List<Routine> routines,
      String day,
      int slot,
      ) {
    // Get busy teacher IDs
    var busyTeacherIds = routines
        .where((r) => r.day == day && r.slot == slot && r.teacherId != null)
        .map((r) => r.teacherId)
        .toSet();

    return teachers.where((t) =>
    !busyTeacherIds.contains(t.id) &&
        t.availableDays.contains(day) &&
        t.availableSlots.contains(slot)
    ).toList();
  }
}