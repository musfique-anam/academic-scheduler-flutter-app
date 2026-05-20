// lib/data/models/routine_model.dart

class Routine {
  final int? id;
  final String type;
  final String departmentId;
  final String batchId;
  final int? courseId;  // Add this field
  final String courseCode;
  final String courseTitle;
  String? teacherId;
  String? teacherName;
  String? roomId;
  String? roomNo;
  String day;
  int slot;
  int? endSlot;  // Add this field for double-slot courses (Labs)
  String? startTime;
  String? endTime;
  String? status;
  String? conflictReason;
  DateTime? date;

  Routine({
    this.id,
    required this.type,
    required this.departmentId,
    required this.batchId,
    this.courseId,
    required this.courseCode,
    required this.courseTitle,
    this.teacherId,
    this.teacherName,
    this.roomId,
    this.roomNo,
    required this.day,
    required this.slot,
    this.endSlot,
    this.startTime,
    this.endTime,
    this.status,
    this.conflictReason,
    this.date,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'departmentId': departmentId,
      'batchId': batchId,
      'courseId': courseId,
      'courseCode': courseCode,
      'courseTitle': courseTitle,
      'teacherId': teacherId,
      'teacherName': teacherName,
      'roomId': roomId,
      'roomNo': roomNo,
      'day': day,
      'slot': slot,
      'endSlot': endSlot,
      'startTime': startTime,
      'endTime': endTime,
      'status': status,
      'conflictReason': conflictReason,
      'date': date?.toIso8601String(),
    };
  }

  factory Routine.fromMap(Map<String, dynamic> map) {
    return Routine(
      id: map['id'],
      type: map['type'] ?? 'class',
      departmentId: map['departmentId']?.toString() ?? '',
      batchId: map['batchId']?.toString() ?? '',
      courseId: map['courseId'],
      courseCode: map['courseCode'] ?? '',
      courseTitle: map['courseTitle'] ?? '',
      teacherId: map['teacherId']?.toString(),
      teacherName: map['teacherName'],
      roomId: map['roomId']?.toString(),
      roomNo: map['roomNo'],
      day: map['day'] ?? '',
      slot: map['slot'] ?? 1,
      endSlot: map['endSlot'],
      startTime: map['startTime'],
      endTime: map['endTime'],
      status: map['status'],
      conflictReason: map['conflictReason'],
      date: map['date'] != null ? DateTime.parse(map['date']) : null,
    );
  }

  Routine copyWith({
    int? id,
    String? type,
    String? departmentId,
    String? batchId,
    int? courseId,
    String? courseCode,
    String? courseTitle,
    String? teacherId,
    String? teacherName,
    String? roomId,
    String? roomNo,
    String? day,
    int? slot,
    int? endSlot,
    String? startTime,
    String? endTime,
    String? status,
    String? conflictReason,
    DateTime? date,
  }) {
    return Routine(
      id: id ?? this.id,
      type: type ?? this.type,
      departmentId: departmentId ?? this.departmentId,
      batchId: batchId ?? this.batchId,
      courseId: courseId ?? this.courseId,
      courseCode: courseCode ?? this.courseCode,
      courseTitle: courseTitle ?? this.courseTitle,
      teacherId: teacherId ?? this.teacherId,
      teacherName: teacherName ?? this.teacherName,
      roomId: roomId ?? this.roomId,
      roomNo: roomNo ?? this.roomNo,
      day: day ?? this.day,
      slot: slot ?? this.slot,
      endSlot: endSlot ?? this.endSlot,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      status: status ?? this.status,
      conflictReason: conflictReason ?? this.conflictReason,
      date: date ?? this.date,
    );
  }
}