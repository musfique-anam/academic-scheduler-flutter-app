import '../services/database_helper.dart';
import '../models/batch_model.dart';
import '../models/course_model.dart';

class BatchRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final String tableName = 'batches';

  // Create - Add new batch
  Future<int> addBatch(Batch batch) async {
    try {
      return await _dbHelper.insert(tableName, batch.toMap());
    } catch (e) {
      throw Exception('Failed to add batch: $e');
    }
  }

  // Read - Get all batches
  Future<List<Batch>> getAllBatches() async {
    try {
      final List<Map<String, dynamic>> maps = await _dbHelper.queryAll(tableName);
      return List.generate(maps.length, (i) {
        return Batch.fromMap(maps[i]);
      });
    } catch (e) {
      throw Exception('Failed to get batches: $e');
    }
  }

  // Read - Get batches by department
  Future<List<Batch>> getBatchesByDepartment(int departmentId) async {
    try {
      final List<Map<String, dynamic>> maps = await _dbHelper.query(
        tableName,
        where: 'departmentId = ?',
        whereArgs: [departmentId],
        orderBy: 'batchNo ASC',
      );

      return List.generate(maps.length, (i) {
        return Batch.fromMap(maps[i]);
      });
    } catch (e) {
      throw Exception('Failed to get batches by department: $e');
    }
  }

  // Read - Get single batch by id
  Future<Batch?> getBatchById(int id) async {
    try {
      final List<Map<String, dynamic>> maps = await _dbHelper.query(
        tableName,
        where: 'id = ?',
        whereArgs: [id],
      );

      if (maps.isNotEmpty) {
        return Batch.fromMap(maps.first);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get batch: $e');
    }
  }

  // Update - Update batch with debugging
  Future<int> updateBatch(Batch batch) async {
    try {
      print('🔍 REPOSITORY: Updating batch with id: ${batch.id}');
      print('🔍 REPOSITORY: Batch data: ${batch.toMap()}');

      // First check if batch exists
      final existing = await getBatchById(batch.id!);
      if (existing == null) {
        print('❌ REPOSITORY: Batch with id ${batch.id} not found!');
        return 0;
      }

      print('✅ REPOSITORY: Found existing batch: ${existing.batchNo}');

      int result = await _dbHelper.update(
        tableName,
        batch.toMap(),
        where: 'id = ?',
        whereArgs: [batch.id],
      );

      print('✅ REPOSITORY: Update result: $result rows affected');
      return result;
    } catch (e) {
      print('❌ REPOSITORY error: $e');
      throw Exception('Failed to update batch: $e');
    }
  }
  // Delete - Delete batch
  Future<int> deleteBatch(int id) async {
    try {
      return await _dbHelper.delete(
        tableName,
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      throw Exception('Failed to delete batch: $e');
    }
  }

  // Check if batch number already exists in department
  Future<bool> isBatchExists(int departmentId, int batchNo, {int? excludeId}) async {
    try {
      String where = 'departmentId = ? AND batchNo = ?';
      List<dynamic> args = [departmentId, batchNo];

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
      throw Exception('Failed to check batch: $e');
    }
  }

  // Get total students count across all batches
  Future<int> getTotalStudents() async {
    try {
      final List<Map<String, dynamic>> maps = await _dbHelper.queryAll(tableName);
      int total = 0;
      for (var batch in maps) {
        total += batch['totalStudents'] as int;
      }
      return total;
    } catch (e) {
      throw Exception('Failed to get total students: $e');
    }
  }

  // Get batch count
  Future<int> getBatchCount() async {
    try {
      final List<Map<String, dynamic>> maps = await _dbHelper.queryAll(tableName);
      return maps.length;
    } catch (e) {
      throw Exception('Failed to get batch count: $e');
    }
  }

  // Get batches by program type
  Future<List<Batch>> getBatchesByProgramType(String programType) async {
    try {
      final List<Map<String, dynamic>> maps = await _dbHelper.query(
        tableName,
        where: 'programType = ?',
        whereArgs: [programType],
        orderBy: 'batchNo ASC',
      );

      return List.generate(maps.length, (i) {
        return Batch.fromMap(maps[i]);
      });
    } catch (e) {
      throw Exception('Failed to get batches by program type: $e');
    }
  }

  // Search batches
  Future<List<Batch>> searchBatches(String query) async {
    try {
      // Since batchNo is integer, we need to handle search differently
      // First try to parse query as integer
      int? batchNo = int.tryParse(query);

      if (batchNo != null) {
        final List<Map<String, dynamic>> maps = await _dbHelper.query(
          tableName,
          where: 'batchNo = ?',
          whereArgs: [batchNo],
          orderBy: 'batchNo ASC',
        );
        return List.generate(maps.length, (i) => Batch.fromMap(maps[i]));
      }

      return [];
    } catch (e) {
      throw Exception('Failed to search batches: $e');
    }
  }
}