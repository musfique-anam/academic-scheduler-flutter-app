class Teacher {
  int? id;
  String name;
  String shortName;
  String username;
  String password;
  String phone;
  int departmentId;
  String role;
  List<int> interestedCourses;
  List<String> availableDays;
  List<int> availableSlots;
  int maxLoad;
  bool isProfileCompleted;

  Teacher({
    this.id,
    required this.name,
    required this.shortName,
    required this.username,
    required this.password,
    required this.phone,
    required this.departmentId,
    this.role = 'teacher',
    this.interestedCourses = const [],
    this.availableDays = const [],
    this.availableSlots = const [],
    this.maxLoad = 0,
    this.isProfileCompleted = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'shortName': shortName,
      'username': username,
      'password': password,
      'phone': phone,
      'departmentId': departmentId,
      'role': role,
      'interestedCourses': interestedCourses.join(','),
      'availableDays': availableDays.join(','),
      'availableSlots': availableSlots.join(','),
      'maxLoad': maxLoad,
      'isProfileCompleted': isProfileCompleted ? 1 : 0,
    };
  }

  factory Teacher.fromMap(Map<String, dynamic> map) {
    return Teacher(
      id: map['id'],
      name: map['name'],
      shortName: map['shortName'],
      username: map['username'],
      password: map['password'],
      phone: map['phone'],
      departmentId: map['departmentId'],
      role: map['role'] ?? 'teacher',
      interestedCourses: _parseListInt(map['interestedCourses']),
      availableDays: _parseListString(map['availableDays']),
      availableSlots: _parseListInt(map['availableSlots']),
      maxLoad: map['maxLoad'] ?? 0,
      isProfileCompleted: map['isProfileCompleted'] == 1,
    );
  }

  static List<int> _parseListInt(String? value) {
    if (value == null || value.isEmpty) return [];
    return value.split(',').map((e) => int.parse(e)).toList();
  }

  static List<String> _parseListString(String? value) {
    if (value == null || value.isEmpty) return [];
    return value.split(',');
  }

  @override
  String toString() {
    return 'Teacher{id: $id, name: $name, username: $username}';
  }
}