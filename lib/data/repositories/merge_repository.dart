import '../services/database_helper.dart';
import '../models/merge_model.dart';

class MergeRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final String tableName = 'merged_classes';

  // Create - Add new merge
  Future<int> createMerge(MergedClass merge) async {
    try {
      print('📝 Creating merge: ${merge.mergedCourseCode}');
      Map<String, dynamic> data = merge.toMap();
      data['createdAt'] = DateTime.now().toIso8601String();
      int result = await _dbHelper.insert(tableName, data);
      print('✅ Merge created with ID: $result');
      return result;
    } catch (e) {
      print('❌ Error creating merge: $e');
      throw Exception('Failed to create merge: $e');
    }
  }

  // Read - Get all merges
  Future<List<MergedClass>> getAllMerges() async {
    try {
      final List<Map<String, dynamic>> maps = await _dbHelper.queryAll(tableName);
      print('📚 Found ${maps.length} merges');
      return List.generate(maps.length, (i) {
        return MergedClass.fromMap(maps[i]);
      });
    } catch (e) {
      print('❌ Error getting merges: $e');
      throw Exception('Failed to get merges: $e');
    }
  }

  // Read - Get merge by id
  Future<MergedClass?> getMergeById(int id) async {
    try {
      final List<Map<String, dynamic>> maps = await _dbHelper.query(
        tableName,
        where: 'id = ?',
        whereArgs: [id],
      );
      if (maps.isNotEmpty) {
        return MergedClass.fromMap(maps.first);
      }
      return null;
    } catch (e) {
      print('❌ Error getting merge: $e');
      throw Exception('Failed to get merge: $e');
    }
  }

  // Update - Update merge
  Future<int> updateMerge(MergedClass merge) async {
    try {
      print('🔄 Updating merge ID: ${merge.id}');
      int result = await _dbHelper.update(
        tableName,
        merge.toMap(),
        where: 'id = ?',
        whereArgs: [merge.id],
      );
      print('✅ Merge updated, rows affected: $result');
      return result;
    } catch (e) {
      print('❌ Error updating merge: $e');
      throw Exception('Failed to update merge: $e');
    }
  }

  // Delete - Delete merge
  Future<int> deleteMerge(int id) async {
    try {
      print('🗑️ Deleting merge ID: $id');
      int result = await _dbHelper.delete(
        tableName,
        where: 'id = ?',
        whereArgs: [id],
      );
      print('✅ Merge deleted, rows affected: $result');
      return result;
    } catch (e) {
      print('❌ Error deleting merge: $e');
      throw Exception('Failed to delete merge: $e');
    }
  }

  // Get merges by day
  Future<List<MergedClass>> getMergesByDay(String day) async {
    try {
      final List<Map<String, dynamic>> maps = await _dbHelper.query(
        tableName,
        where: 'day = ?',
        whereArgs: [day],
        orderBy: 'timeSlot ASC',
      );
      return List.generate(maps.length, (i) => MergedClass.fromMap(maps[i]));
    } catch (e) {
      print('❌ Error getting merges by day: $e');
      throw Exception('Failed to get merges by day: $e');
    }
  }

  // Get merges by teacher
  Future<List<MergedClass>> getMergesByTeacher(int teacherId) async {
    try {
      final List<Map<String, dynamic>> maps = await _dbHelper.query(
        tableName,
        where: 'teacherId = ?',
        whereArgs: [teacherId],
      );
      return List.generate(maps.length, (i) => MergedClass.fromMap(maps[i]));
    } catch (e) {
      print('❌ Error getting merges by teacher: $e');
      throw Exception('Failed to get merges by teacher: $e');
    }
  }

  // Get merges by room
  Future<List<MergedClass>> getMergesByRoom(int roomId) async {
    try {
      final List<Map<String, dynamic>> maps = await _dbHelper.query(
        tableName,
        where: 'roomId = ?',
        whereArgs: [roomId],
      );
      return List.generate(maps.length, (i) => MergedClass.fromMap(maps[i]));
    } catch (e) {
      print('❌ Error getting merges by room: $e');
      throw Exception('Failed to get merges by room: $e');
    }
  }

  // Check for conflicts
  Future<bool> hasConflict(String day, int timeSlot, int? roomId, int? teacherId, {int? excludeId}) async {
    try {
      String where = 'day = ? AND timeSlot = ?';
      List<dynamic> args = [day, timeSlot];

      if (roomId != null) {
        where += ' AND roomId = ?';
        args.add(roomId);
      }

      if (teacherId != null) {
        where += ' AND teacherId = ?';
        args.add(teacherId);
      }

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
      print('❌ Error checking conflict: $e');
      return false;
    }
  }

  // Get merge count
  Future<int> getMergeCount() async {
    try {
      final List<Map<String, dynamic>> maps = await _dbHelper.queryAll(tableName);
      return maps.length;
    } catch (e) {
      print('❌ Error getting merge count: $e');
      return 0;
    }
  }
}