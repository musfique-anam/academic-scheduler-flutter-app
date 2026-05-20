class DepartmentRoom {
  int? id;
  int departmentId;
  int roomId;

  DepartmentRoom({
    this.id,
    required this.departmentId,
    required this.roomId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'departmentId': departmentId,
      'roomId': roomId,
    };
  }

  factory DepartmentRoom.fromMap(Map<String, dynamic> map) {
    return DepartmentRoom(
      id: map['id'],
      departmentId: map['departmentId'],
      roomId: map['roomId'],
    );
  }
}