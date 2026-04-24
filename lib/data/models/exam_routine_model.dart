class ExamRoutine {
  int? id;
  String examName;
  List<int> departmentIds;
  List<int> batchIds;
  int courseId;
  String courseCode;
  String courseTitle;
  DateTime date;
  int slot;
  String startTime;
  String endTime;
  int? roomId;
  String? roomNo;
  String status;

  ExamRoutine({
    this.id,
    required this.examName,
    required this.departmentIds,
    required this.batchIds,
    required this.courseId,
    required this.courseCode,
    required this.courseTitle,
    required this.date,
    required this.slot,
    required this.startTime,
    required this.endTime,
    this.roomId,
    this.roomNo,
    required this.status,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'examName': examName,
      'departmentIds': departmentIds.join(','),
      'batchIds': batchIds.join(','),
      'courseId': courseId,
      'courseCode': courseCode,
      'courseTitle': courseTitle,
      'date': date.toIso8601String(),
      'slot': slot,
      'startTime': startTime,
      'endTime': endTime,
      'roomId': roomId,
      'roomNo': roomNo,
      'status': status,
    };
  }

  factory ExamRoutine.fromMap(Map<String, dynamic> map) {
    return ExamRoutine(
      id: map['id'],
      examName: map['examName'],
      departmentIds: (map['departmentIds'] as String).split(',').map(int.parse).toList(),
      batchIds: (map['batchIds'] as String).split(',').map(int.parse).toList(),
      courseId: map['courseId'],
      courseCode: map['courseCode'],
      courseTitle: map['courseTitle'],
      date: DateTime.parse(map['date']),
      slot: map['slot'],
      startTime: map['startTime'],
      endTime: map['endTime'],
      roomId: map['roomId'],
      roomNo: map['roomNo'],
      status: map['status'],
    );
  }
}