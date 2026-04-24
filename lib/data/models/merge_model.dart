class MergedClass {
  int? id;
  String mergedCourseCode;
  String mergedCourseTitle;
  double credit;
  List<int> batchIds;
  List<String> batchNames;
  int? teacherId;
  String? teacherName;
  int? roomId;
  String? roomNo;
  String day;
  int timeSlot;
  String startTime;
  String endTime;
  DateTime? createdAt;

  MergedClass({
    this.id,
    required this.mergedCourseCode,
    required this.mergedCourseTitle,
    required this.credit,
    required this.batchIds,
    required this.batchNames,
    this.teacherId,
    this.teacherName,
    this.roomId,
    this.roomNo,
    required this.day,
    required this.timeSlot,
    required this.startTime,
    required this.endTime,
    this.createdAt,
  });

  // রুটিনে দেখানোর জন্য ফরম্যাটেড টেক্সট
  String get routineDisplay {
    String batches = batchNames.join(' + ');
    return '$day ${startTime}-$endTime\n'
        '$mergedCourseCode\n'
        '($batches)\n'
        '${roomNo ?? 'TBA'} ${teacherName ?? 'TBA'}';
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'mergedCourseCode': mergedCourseCode,
      'mergedCourseTitle': mergedCourseTitle,
      'credit': credit,
      'batchIds': batchIds.join(','),
      'batchNames': batchNames.join(','),
      'teacherId': teacherId,
      'teacherName': teacherName,
      'roomId': roomId,
      'roomNo': roomNo,
      'day': day,
      'timeSlot': timeSlot,
      'startTime': startTime,
      'endTime': endTime,
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  factory MergedClass.fromMap(Map<String, dynamic> map) {
    return MergedClass(
      id: map['id'],
      mergedCourseCode: map['mergedCourseCode'],
      mergedCourseTitle: map['mergedCourseTitle'],
      credit: map['credit'],
      batchIds: (map['batchIds'] as String).split(',').map(int.parse).toList(),
      batchNames: (map['batchNames'] as String).split(','),
      teacherId: map['teacherId'],
      teacherName: map['teacherName'],
      roomId: map['roomId'],
      roomNo: map['roomNo'],
      day: map['day'],
      timeSlot: map['timeSlot'],
      startTime: map['startTime'],
      endTime: map['endTime'],
      createdAt: map['createdAt'] != null ? DateTime.parse(map['createdAt']) : null,
    );
  }
}