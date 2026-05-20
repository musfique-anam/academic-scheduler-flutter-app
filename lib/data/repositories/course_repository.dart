import '../services/database_helper.dart';
import '../models/course_model.dart';

class CourseRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final String tableName = 'courses';

  // Create - Add new course
  Future<int> addCourse(Course course) async {
    try {
      return await _dbHelper.insert(tableName, course.toMap());
    } catch (e) {
      throw Exception('Failed to add course: $e');
    }
  }

  // Read - Get all courses
  Future<List<Course>> getAllCourses() async {
    try {
      final List<Map<String, dynamic>> maps = await _dbHelper.queryAll(tableName);
      return List.generate(maps.length, (i) {
        return Course.fromMap(maps[i]);
      });
    } catch (e) {
      throw Exception('Failed to get courses: $e');
    }
  }

  // Read - Get courses by batch
  Future<List<Course>> getCoursesByBatch(int batchId) async {
    try {
      final List<Map<String, dynamic>> maps = await _dbHelper.query(
        tableName,
        where: 'batchId = ?',
        whereArgs: [batchId],
        orderBy: 'code ASC',
      );

      return List.generate(maps.length, (i) {
        return Course.fromMap(maps[i]);
      });
    } catch (e) {
      throw Exception('Failed to get courses by batch: $e');
    }
  }

  // Read - Get courses by teacher
  Future<List<Course>> getCoursesByTeacher(int teacherId) async {
    try {
      final List<Map<String, dynamic>> maps = await _dbHelper.query(
        tableName,
        where: 'teacherId = ?',
        whereArgs: [teacherId],
        orderBy: 'code ASC',
      );

      return List.generate(maps.length, (i) {
        return Course.fromMap(maps[i]);
      });
    } catch (e) {
      throw Exception('Failed to get courses by teacher: $e');
    }
  }

  // Read - Get single course by id
  Future<Course?> getCourseById(int id) async {
    try {
      final List<Map<String, dynamic>> maps = await _dbHelper.query(
        tableName,
        where: 'id = ?',
        whereArgs: [id],
      );

      if (maps.isNotEmpty) {
        return Course.fromMap(maps.first);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get course: $e');
    }
  }

  // Update - Update course
  Future<int> updateCourse(Course course) async {
    try {
      return await _dbHelper.update(
        tableName,
        course.toMap(),
        where: 'id = ?',
        whereArgs: [course.id],
      );
    } catch (e) {
      throw Exception('Failed to update course: $e');
    }
  }

  // Delete - Delete course
  Future<int> deleteCourse(int id) async {
    try {
      return await _dbHelper.delete(
        tableName,
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      throw Exception('Failed to delete course: $e');
    }
  }

  // Delete all courses in a batch
  Future<int> deleteCoursesByBatch(int batchId) async {
    try {
      return await _dbHelper.delete(
        tableName,
        where: 'batchId = ?',
        whereArgs: [batchId],
      );
    } catch (e) {
      throw Exception('Failed to delete courses by batch: $e');
    }
  }

  // Check if course code exists in batch
  Future<bool> isCourseCodeExists(String code, int batchId, {int? excludeId}) async {
    try {
      String where = 'code = ? AND batchId = ?';
      List<dynamic> args = [code, batchId];

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
      throw Exception('Failed to check course code: $e');
    }
  }

  // Get course count
  Future<int> getCourseCount() async {
    try {
      final List<Map<String, dynamic>> maps = await _dbHelper.queryAll(tableName);
      return maps.length;
    } catch (e) {
      throw Exception('Failed to get course count: $e');
    }
  }

  // Search courses
  Future<List<Course>> searchCourses(String query) async {
    try {
      final List<Map<String, dynamic>> maps = await _dbHelper.query(
        tableName,
        where: 'code LIKE ? OR title LIKE ?',
        whereArgs: ['%$query%', '%$query%'],
        orderBy: 'code ASC',
      );

      return List.generate(maps.length, (i) {
        return Course.fromMap(maps[i]);
      });
    } catch (e) {
      throw Exception('Failed to search courses: $e');
    }
  }

  // Assign teacher to course
  Future<int> assignTeacher(int courseId, int teacherId) async {
    try {
      return await _dbHelper.update(
        tableName,
        {'teacherId': teacherId},
        where: 'id = ?',
        whereArgs: [courseId],
      );
    } catch (e) {
      throw Exception('Failed to assign teacher: $e');
    }
  }

  // Remove teacher from course
  Future<int> removeTeacher(int courseId) async {
    try {
      return await _dbHelper.update(
        tableName,
        {'teacherId': null},
        where: 'id = ?',
        whereArgs: [courseId],
      );
    } catch (e) {
      throw Exception('Failed to remove teacher: $e');
    }
  }
}