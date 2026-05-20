import '../services/database_helper.dart';
import '../models/department_model.dart';

class DepartmentRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final String tableName = 'departments';

  // Create - Add new department
  Future<int> addDepartment(Department department) async {
    try {
      print('📝 Adding department: ${department.name}');
      int result = await _dbHelper.insert(tableName, department.toMap());
      print('✅ Department added with ID: $result');
      return result;
    } catch (e) {
      print('❌ Error adding department: $e');
      throw Exception('Failed to add department: $e');
    }
  }

  // Read - Get all departments
  Future<List<Department>> getAllDepartments() async {
    try {
      final List<Map<String, dynamic>> maps = await _dbHelper.queryAll(tableName);
      print('📚 Found ${maps.length} departments');
      return List.generate(maps.length, (i) {
        return Department.fromMap(maps[i]);
      });
    } catch (e) {
      print('❌ Error getting departments: $e');
      throw Exception('Failed to get departments: $e');
    }
  }

  // Read - Get single department by id
  Future<Department?> getDepartmentById(int id) async {
    try {
      final List<Map<String, dynamic>> maps = await _dbHelper.query(
        tableName,
        where: 'id = ?',
        whereArgs: [id],
      );

      if (maps.isNotEmpty) {
        print('✅ Found department with ID: $id');
        return Department.fromMap(maps.first);
      }
      print('❌ No department found with ID: $id');
      return null;
    } catch (e) {
      print('❌ Error getting department: $e');
      throw Exception('Failed to get department: $e');
    }
  }

  // Update - Update department
  Future<int> updateDepartment(Department department) async {
    try {
      print('🔄 Updating department ID: ${department.id}');
      int result = await _dbHelper.update(
        tableName,
        department.toMap(),
        where: 'id = ?',
        whereArgs: [department.id],
      );
      print('✅ Department updated, rows affected: $result');
      return result;
    } catch (e) {
      print('❌ Error updating department: $e');
      throw Exception('Failed to update department: $e');
    }
  }

  // Delete - Delete department
  Future<int> deleteDepartment(int id) async {
    try {
      print('🗑️ Deleting department ID: $id');
      int result = await _dbHelper.delete(
        tableName,
        where: 'id = ?',
        whereArgs: [id],
      );
      print('✅ Department deleted, rows affected: $result');
      return result;
    } catch (e) {
      print('❌ Error deleting department: $e');
      throw Exception('Failed to delete department: $e');
    }
  }

  // Search departments by name or code
  Future<List<Department>> searchDepartments(String query) async {
    try {
      final List<Map<String, dynamic>> maps = await _dbHelper.query(
        tableName,
        where: 'name LIKE ? OR code LIKE ?',
        whereArgs: ['%$query%', '%$query%'],
        orderBy: 'name ASC',
      );

      print('🔍 Search "$query" found ${maps.length} results');
      return List.generate(maps.length, (i) {
        return Department.fromMap(maps[i]);
      });
    } catch (e) {
      print('❌ Error searching departments: $e');
      throw Exception('Failed to search departments: $e');
    }
  }

  // Check if department code already exists
  Future<bool> isDepartmentCodeExists(String code, {int? excludeId}) async {
    try {
      String where = 'code = ?';
      List<dynamic> args = [code];

      if (excludeId != null) {
        where += ' AND id != ?';
        args.add(excludeId);
      }

      final List<Map<String, dynamic>> maps = await _dbHelper.query(
        tableName,
        where: where,
        whereArgs: args,
      );

      bool exists = maps.isNotEmpty;
      print('🔍 Code "$code" exists: $exists');
      return exists;
    } catch (e) {
      print('❌ Error checking department code: $e');
      throw Exception('Failed to check department code: $e');
    }
  }

  // Get total count of departments
  Future<int> getDepartmentCount() async {
    try {
      final List<Map<String, dynamic>> maps = await _dbHelper.queryAll(tableName);
      int count = maps.length;
      print('📊 Total departments: $count');
      return count;
    } catch (e) {
      print('❌ Error getting department count: $e');
      throw Exception('Failed to get department count: $e');
    }
  }
}