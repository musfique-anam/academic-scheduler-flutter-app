class Room {
  int? id;
  String roomNo;
  String type; // Theory or Lab
  int capacity;
  int floor;
  String? equipment;
  int? pcTotal;
  int? pcActive;
  int? departmentId; // Assigned department
  String? departmentName; // For display

  Room({
    this.id,
    required this.roomNo,
    required this.type,
    required this.capacity,
    required this.floor,
    this.equipment,
    this.pcTotal,
    this.pcActive,
    this.departmentId,
    this.departmentName,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'roomNo': roomNo,
      'type': type,
      'capacity': capacity,
      'floor': floor,
      'equipment': equipment,
      'pcTotal': pcTotal,
      'pcActive': pcActive,
      'departmentId': departmentId,
    };
  }

  factory Room.fromMap(Map<String, dynamic> map) {
    return Room(
      id: map['id'],
      roomNo: map['roomNo'],
      type: map['type'],
      capacity: map['capacity'],
      floor: map['floor'],
      equipment: map['equipment'],
      pcTotal: map['pcTotal'],
      pcActive: map['pcActive'],
      departmentId: map['departmentId'],
    );
  }

  // Room types
  static const List<String> roomTypes = ['Theory', 'Lab'];

  // Floor range
  static const int minFloor = 1;
  static const int maxFloor = 20;
  static const int roomsPerFloor = 8;

  // Generate room number based on floor and index
  static String generateRoomNo(int floor, int index) {
    int roomNumber = floor * 100 + index;
    return 'NB$roomNumber';
  }

  // Parse floor from room number
  static int getFloorFromRoomNo(String roomNo) {
    try {
      // Remove 'NB' and parse number
      String numberStr = roomNo.replaceAll('NB', '');
      int number = int.parse(numberStr);
      return number ~/ 100; // Integer division to get floor
    } catch (e) {
      return 1;
    }
  }
}