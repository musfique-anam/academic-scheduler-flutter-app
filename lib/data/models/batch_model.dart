class Batch {
  int? id;
  int departmentId;
  int batchNo;
  String programType; // HSC or Diploma
  int totalStudents;
  String? departmentName; // For display purposes (not stored in DB)
  List<Map<String, dynamic>> courses; // Temporary courses for batch creation

  // For multiple selection in merge section (not stored in DB)
  bool isSelected = false;

  Batch({
    this.id,
    required this.departmentId,
    required this.batchNo,
    required this.programType,
    required this.totalStudents,
    this.departmentName,
    this.courses = const [],
    this.isSelected = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'departmentId': departmentId,
      'batchNo': batchNo,
      'programType': programType,
      'totalStudents': totalStudents,
    };
  }

  factory Batch.fromMap(Map<String, dynamic> map) {
    return Batch(
      id: map['id'],
      departmentId: map['departmentId'],
      batchNo: map['batchNo'],
      programType: map['programType'],
      totalStudents: map['totalStudents'],
    );
  }

  // For displaying in dropdowns
  String get displayName => 'Batch $batchNo ($programType)';

  // For filtering
  static const List<String> programTypes = ['HSC', 'Diploma'];

  // Batch range
  static const int minBatch = 1;
  static const int maxBatch = 100;
}