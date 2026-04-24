class Routine {
  int? id;
  String type; // 'class' or 'exam'
  int departmentId;
  int? batchId;
  int courseId;
  String courseCode;
  String courseTitle;
  int? teacherId;
  String? teacherName;
  int? roomId;
  String? roomNo;
  String day;
  int slot; // 1-4
  int? endSlot; // for lab classes (2 slots)
  String startTime;
  String endTime;
  DateTime? date; // for exam routines
  String status; // 'scheduled', 'conflict', 'manual_fixed'
  String? conflictReason;

  Routine({
    this.id,
    required this.type,
    required this.departmentId,
    this.batchId,
    required this.courseId,
    required this.courseCode,
    required this.courseTitle,
    this.teacherId,
    this.teacherName,
    this.roomId,
    this.roomNo,
    required this.day,
    required this.slot,
    this.endSlot,
    required this.startTime,
    required this.endTime,
    this.date,
    required this.status,
    this.conflictReason,
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
      'date': date?.toIso8601String(),
      'status': status,
      'conflictReason': conflictReason,
    };
  }

  factory Routine.fromMap(Map<String, dynamic> map) {
    return Routine(
      id: map['id'],
      type: map['type'],
      departmentId: map['departmentId'],
      batchId: map['batchId'],
      courseId: map['courseId'],
      courseCode: map['courseCode'],
      courseTitle: map['courseTitle'],
      teacherId: map['teacherId'],
      teacherName: map['teacherName'],
      roomId: map['roomId'],
      roomNo: map['roomNo'],
      day: map['day'],
      slot: map['slot'],
      endSlot: map['endSlot'],
      startTime: map['startTime'],
      endTime: map['endTime'],
      date: map['date'] != null ? DateTime.parse(map['date']) : null,
      status: map['status'] ?? 'scheduled',
      conflictReason: map['conflictReason'],
    );
  }
}