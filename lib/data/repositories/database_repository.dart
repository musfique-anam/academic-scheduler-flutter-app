import 'package:sqflite/sqflite.dart';
import '../services/database_service.dart';

class DatabaseRepository {
  final DatabaseService _databaseService = DatabaseService();

  Future<Database> get database => _databaseService.database;

  Future<int> insert(String table, Map<String, dynamic> data) async {
    final db = await database;
    return await db.insert(table, data);
  }

  Future<List<Map<String, dynamic>>> queryAll(String table) async {
    final db = await database;
    return await db.query(table);
  }

  Future<List<Map<String, dynamic>>> query(
      String table, {
        dynamic where,
        List<dynamic>? whereArgs,
        String? orderBy,
      }) async {
    final db = await database;
    return await db.query(
      table,
      where: where,
      whereArgs: whereArgs,
      orderBy: orderBy,
    );
  }

  Future<int> update(
      String table,
      Map<String, dynamic> data, {
        dynamic where,
        List<dynamic>? whereArgs,
      }) async {
    final db = await database;
    return await db.update(
      table,
      data,
      where: where,
      whereArgs: whereArgs,
    );
  }

  Future<int> delete(
      String table, {
        dynamic where,
        List<dynamic>? whereArgs,
      }) async {
    final db = await database;
    return await db.delete(
      table,
      where: where,
      whereArgs: whereArgs,
    );
  }
}