class Course {
  int? id;
  String code;
  String title;
  double credit;
  String type; // Theory or Lab
  int batchId;
  int? teacherId;
  String? batchName;
  String? teacherName;

  Course({
    this.id,
    required this.code,
    required this.title,
    required this.credit,
    required this.type,
    required this.batchId,
    this.teacherId,
    this.batchName,
    this.teacherName,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'code': code,
      'title': title,
      'credit': credit,
      'type': type,
      'batchId': batchId,
      'teacherId': teacherId,
    };
  }

  factory Course.fromMap(Map<String, dynamic> map) {
    return Course(
      id: map['id'],
      code: map['code'],
      title: map['title'],
      credit: (map['credit'] is int)
          ? (map['credit'] as int).toDouble()
          : map['credit'],
      type: map['type'],
      batchId: map['batchId'],
      teacherId: map['teacherId'],
    );
  }

  // Course types
  static const List<String> courseTypes = ['Theory', 'Lab'];

  // Lab requires 2 slots
  bool get isLab => type == 'Lab';
  int get requiredSlots => isLab ? 2 : 1;

  @override
  String toString() {
    return 'Course{id: $id, code: $code, title: $title}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Course &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}