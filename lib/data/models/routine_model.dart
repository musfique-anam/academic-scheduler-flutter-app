// lib/data/models/routine_model.dart

class Routine {
  int? id;
  String type;
  String departmentId;
  String batchId;
  int? courseId;
  String courseCode;
  String courseTitle;
  String? teacherId;
  String? teacherName;
  String? roomId;
  String? roomNo;
  String day;
  int slot;
  int? endSlot;
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
      courseId: map['courseId'] is int
          ? map['courseId']
          : (map['courseId'] == null
              ? null
              : int.tryParse(map['courseId'].toString())),
      courseCode: map['courseCode'] ?? '',
      courseTitle: map['courseTitle'] ?? '',
      teacherId: map['teacherId']?.toString(),
      teacherName: map['teacherName'],
      roomId: map['roomId']?.toString(),
      roomNo: map['roomNo']?.toString(),
      day: map['day'] ?? '',
      slot: map['slot'] is int
          ? map['slot']
          : int.tryParse(map['slot']?.toString() ?? '1') ?? 1,
      endSlot: map['endSlot'] is int
          ? map['endSlot']
          : (map['endSlot'] == null
              ? null
              : int.tryParse(map['endSlot'].toString())),
      startTime: map['startTime']?.toString(),
      endTime: map['endTime']?.toString(),
      status: map['status']?.toString(),
      conflictReason: map['conflictReason']?.toString(),
      date: map['date'] != null
          ? DateTime.tryParse(map['date'].toString())
          : null,
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

  @override
  String toString() =>
      'Routine{id: $id, type: $type, course: $courseCode, day: $day, slot: $slot}';
}