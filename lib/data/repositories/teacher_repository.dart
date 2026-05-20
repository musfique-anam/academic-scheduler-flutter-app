import '../services/database_helper.dart';
import '../models/teacher_model.dart';
import '../models/course_model.dart';

class TeacherRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final String tableName = 'teachers';

  // Create - Add new teacher
  Future<int> addTeacher(Teacher teacher) async {
    try {
      print('📝 Adding teacher: ${teacher.name}');
      int result = await _dbHelper.insert(tableName, teacher.toMap());
      print('✅ Teacher added with ID: $result');
      return result;
    } catch (e) {
      print('❌ Error adding teacher: $e');
      throw Exception('Failed to add teacher: $e');
    }
  }

  // Read - Get all teachers
  Future<List<Teacher>> getAllTeachers() async {
    try {
      final List<Map<String, dynamic>> maps = await _dbHelper.queryAll(tableName);
      print('📚 Found ${maps.length} teachers');
      return List.generate(maps.length, (i) {
        return Teacher.fromMap(maps[i]);
      });
    } catch (e) {
      print('❌ Error getting teachers: $e');
      throw Exception('Failed to get teachers: $e');
    }
  }

  // Read - Get teachers by department
  Future<List<Teacher>> getTeachersByDepartment(int departmentId) async {
    try {
      final List<Map<String, dynamic>> maps = await _dbHelper.query(
        tableName,
        where: 'departmentId = ?',
        whereArgs: [departmentId],
      );
      return List.generate(maps.length, (i) {
        return Teacher.fromMap(maps[i]);
      });
    } catch (e) {
      print('❌ Error getting teachers by department: $e');
      throw Exception('Failed to get teachers by department: $e');
    }
  }

  // Read - Get single teacher by id
  Future<Teacher?> getTeacherById(int id) async {
    try {
      print('🔍 Fetching teacher with ID: $id');
      final List<Map<String, dynamic>> maps = await _dbHelper.query(
        tableName,
        where: 'id = ?',
        whereArgs: [id],
      );

      if (maps.isNotEmpty) {
        print('✅ Teacher found: ${maps.first['name']}');
        return Teacher.fromMap(maps.first);
      }
      print('❌ Teacher not found with ID: $id');
      return null;
    } catch (e) {
      print('❌ Error getting teacher by id: $e');
      return null;
    }
  }

  // Read - Get teacher by username (for login)
  Future<Teacher?> getTeacherByUsername(String username) async {
    try {
      print('🔍 Fetching teacher with username: $username');
      final List<Map<String, dynamic>> maps = await _dbHelper.query(
        tableName,
        where: 'username = ?',
        whereArgs: [username],
      );

      if (maps.isNotEmpty) {
        print('✅ Teacher found: ${maps.first['name']}');
        return Teacher.fromMap(maps.first);
      }
      print('❌ Teacher not found with username: $username');
      return null;
    } catch (e) {
      print('❌ Error getting teacher by username: $e');
      return null;
    }
  }

  // Update - Update teacher
  Future<int> updateTeacher(Teacher teacher) async {
    try {
      print('🔄 Updating teacher with ID: ${teacher.id}');
      print('📦 Teacher data: ${teacher.toMap()}');

      // First check if teacher exists
      final existing = await getTeacherById(teacher.id!);
      if (existing == null) {
        print('❌ Teacher with id ${teacher.id} not found!');
        return 0;
      }

      int result = await _dbHelper.update(
        tableName,
        teacher.toMap(),
        where: 'id = ?',
        whereArgs: [teacher.id],
      );

      print('✅ Update result: $result rows affected');
      return result;
    } catch (e) {
      print('❌ Error updating teacher: $e');
      throw Exception('Failed to update teacher: $e');
    }
  }

  // Delete - Delete teacher
  Future<int> deleteTeacher(int id) async {
    try {
      print('🗑️ Deleting teacher with ID: $id');
      int result = await _dbHelper.delete(
        tableName,
        where: 'id = ?',
        whereArgs: [id],
      );
      print('✅ Delete result: $result rows affected');
      return result;
    } catch (e) {
      print('❌ Error deleting teacher: $e');
      throw Exception('Failed to delete teacher: $e');
    }
  }

  // Check if username exists
  Future<bool> isUsernameExists(String username, {int? excludeId}) async {
    try {
      String where = 'username = ?';
      List<dynamic> args = [username];

      if (excludeId != null) {
        where += ' AND id != ?';
        args.add(excludeId);
      }

      final List<Map<String, dynamic>> maps = await _dbHelper.query(
        tableName,
        where: where,
        whereArgs: args,
      );

      return maps.isNotEmpty;
    } catch (e) {
      print('❌ Error checking username: $e');
      return false;
    }
  }

  // Get courses by department (for interested courses selection)
  Future<List<Course>> getCoursesByDepartment(int departmentId) async {
    try {
      // First get all batches in this department
      final List<Map<String, dynamic>> batchMaps = await _dbHelper.query(
        'batches',
        where: 'departmentId = ?',
        whereArgs: [departmentId],
      );

      List<int> batchIds = batchMaps.map((b) => b['id'] as int).toList();

      if (batchIds.isEmpty) return [];

      // Then get all courses for these batches
      final List<Map<String, dynamic>> courseMaps = await _dbHelper.query(
        'courses',
        where: 'batchId IN (${batchIds.join(',')})',
      );

      return List.generate(courseMaps.length, (i) {
        return Course.fromMap(courseMaps[i]);
      });
    } catch (e) {
      print('❌ Error getting courses by department: $e');
      throw Exception('Failed to get courses by department: $e');
    }
  }

  // Get teacher count
  Future<int> getTeacherCount() async {
    try {
      final List<Map<String, dynamic>> maps = await _dbHelper.queryAll(tableName);
      return maps.length;
    } catch (e) {
      print('❌ Error getting teacher count: $e');
      return 0;
    }
  }

  // Search teachers
  Future<List<Teacher>> searchTeachers(String query) async {
    try {
      final List<Map<String, dynamic>> maps = await _dbHelper.query(
        tableName,
        where: 'name LIKE ? OR shortName LIKE ? OR username LIKE ?',
        whereArgs: ['%$query%', '%$query%', '%$query%'],
        orderBy: 'name ASC',
      );

      return List.generate(maps.length, (i) {
        return Teacher.fromMap(maps[i]);
      });
    } catch (e) {
      print('❌ Error searching teachers: $e');
      throw Exception('Failed to search teachers: $e');
    }
  }

  // Reset password
  Future<bool> resetPassword(int teacherId, String newPassword) async {
    try {
      int rowsAffected = await _dbHelper.update(
        tableName,
        {'password': newPassword},
        where: 'id = ?',
        whereArgs: [teacherId],
      );
      return rowsAffected > 0;
    } catch (e) {
      print('❌ Error resetting password: $e');
      throw Exception('Failed to reset password: $e');
    }
  }
}