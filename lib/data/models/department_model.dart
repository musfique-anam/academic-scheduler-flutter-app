class Department {
  int? id;
  String name;
  String code;

  Department({
    this.id,
    required this.name,
    required this.code,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'code': code,
    };
  }

  factory Department.fromMap(Map<String, dynamic> map) {
    return Department(
      id: map['id'],
      name: map['name'],
      code: map['code'],
    );
  }

  @override
  String toString() {
    return 'Department{id: $id, name: $name, code: $code}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Department &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}