class Conflict {
  final String type;
  final String description;
  final int? teacherId;
  final int? roomId;
  final int? batchId;
  final String day;
  final int slot;
  final List<dynamic> conflictingRoutines;
  final List<Map<String, dynamic>> suggestions;

  Conflict({
    required this.type,
    required this.description,
    this.teacherId,
    this.roomId,
    this.batchId,
    required this.day,
    required this.slot,
    required this.conflictingRoutines,
    this.suggestions = const [],
  });
}

class WorkloadInfo {
  final int teacherId;
  final String teacherName;
  final int assignedCredits;
  final int maxLoad;
  final bool isOverloaded;
  final List<dynamic> assignedClasses;

  WorkloadInfo({
    required this.teacherId,
    required this.teacherName,
    required this.assignedCredits,
    required this.maxLoad,
    required this.isOverloaded,
    required this.assignedClasses,
  });

  double get utilization => maxLoad > 0 ? (assignedCredits / maxLoad) * 100 : 0;
}