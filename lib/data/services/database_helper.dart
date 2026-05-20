// lib/data/services/database_helper.dart

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../initial_data.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'academic_scheduler.db');

    return await openDatabase(
      path,
      version: 6,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Create departments table
    await db.execute('''
      CREATE TABLE departments(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        code TEXT NOT NULL UNIQUE
      )
    ''');

    // Create teachers table
    await db.execute('''
      CREATE TABLE teachers(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        shortName TEXT NOT NULL,
        username TEXT UNIQUE NOT NULL,
        password TEXT NOT NULL,
        phone TEXT NOT NULL,
        departmentId INTEGER NOT NULL,
        role TEXT NOT NULL DEFAULT 'teacher',
        interestedCourses TEXT,
        availableDays TEXT,
        availableSlots TEXT,
        maxLoad INTEGER DEFAULT 0,
        isProfileCompleted INTEGER DEFAULT 0,
        FOREIGN KEY (departmentId) REFERENCES departments (id) ON DELETE CASCADE
      )
    ''');

    // Create batches table
    await db.execute('''
      CREATE TABLE batches(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        departmentId INTEGER NOT NULL,
        batchNo INTEGER NOT NULL,
        programType TEXT NOT NULL,
        totalStudents INTEGER NOT NULL,
        FOREIGN KEY (departmentId) REFERENCES departments (id) ON DELETE CASCADE,
        UNIQUE(departmentId, batchNo)
      )
    ''');

    // Create courses table
    await db.execute('''
      CREATE TABLE courses(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        code TEXT NOT NULL,
        title TEXT NOT NULL,
        credit REAL NOT NULL,
        type TEXT NOT NULL,
        batchId INTEGER NOT NULL,
        teacherId INTEGER,
        FOREIGN KEY (batchId) REFERENCES batches (id) ON DELETE CASCADE,
        FOREIGN KEY (teacherId) REFERENCES teachers (id) ON DELETE SET NULL
      )
    ''');

    // Create rooms table
    await db.execute('''
      CREATE TABLE rooms(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        roomNo TEXT UNIQUE NOT NULL,
        type TEXT NOT NULL,
        capacity INTEGER NOT NULL,
        floor INTEGER NOT NULL,
        equipment TEXT,
        pcTotal INTEGER,
        pcActive INTEGER,
        departmentId INTEGER,
        FOREIGN KEY (departmentId) REFERENCES departments (id) ON DELETE SET NULL
      )
    ''');

    // Create department_rooms table
    await db.execute('''
      CREATE TABLE department_rooms(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        departmentId INTEGER NOT NULL,
        roomId INTEGER NOT NULL,
        FOREIGN KEY (departmentId) REFERENCES departments (id) ON DELETE CASCADE,
        FOREIGN KEY (roomId) REFERENCES rooms (id) ON DELETE CASCADE,
        UNIQUE(departmentId, roomId)
      )
    ''');

    // Create routines table with all required fields
    await db.execute('''
      CREATE TABLE routines(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        type TEXT NOT NULL,
        departmentId TEXT NOT NULL,
        batchId TEXT,
        courseId INTEGER,
        courseCode TEXT NOT NULL,
        courseTitle TEXT NOT NULL,
        teacherId TEXT,
        teacherName TEXT,
        roomId TEXT,
        roomNo TEXT,
        day TEXT NOT NULL,
        slot INTEGER NOT NULL,
        endSlot INTEGER,
        startTime TEXT,
        endTime TEXT,
        date TEXT,
        status TEXT,
        conflictReason TEXT,
        isExtended INTEGER DEFAULT 0,
        mergedBatchInfo TEXT
      )
    ''');

    // Create merged_classes table
    await db.execute('''
      CREATE TABLE merged_classes(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        mergedCourseCode TEXT NOT NULL,
        mergedCourseTitle TEXT NOT NULL,
        credit REAL NOT NULL,
        batchIds TEXT NOT NULL,
        batchNames TEXT NOT NULL,
        teacherId INTEGER,
        teacherName TEXT,
        roomId INTEGER,
        roomNo TEXT,
        day TEXT NOT NULL,
        timeSlot INTEGER NOT NULL,
        startTime TEXT NOT NULL,
        endTime TEXT NOT NULL,
        createdAt TEXT NOT NULL,
        FOREIGN KEY (teacherId) REFERENCES teachers (id) ON DELETE SET NULL,
        FOREIGN KEY (roomId) REFERENCES rooms (id) ON DELETE SET NULL
      )
    ''');

    // Insert default admin
    await db.insert('teachers', {
      'name': 'Admin User',
      'shortName': 'Admin',
      'username': 'admin',
      'password': 'admin123',
      'phone': '0000000000',
      'departmentId': 0,
      'role': 'admin',
      'isProfileCompleted': 1,
    });

    // Insert initial curriculum data
    await InitialData.insertAllData(db);

    // Insert default rooms
    await _insertDefaultRooms(db);
  }

  Future<void> _insertDefaultRooms(Database db) async {
    try {
      // Check if rooms already exist
      final existingRooms = await db.query('rooms');
      if (existingRooms.isNotEmpty) {
        print('✅ Rooms already exist: ${existingRooms.length} rooms');
        return;
      }

      // Insert Theory Rooms
      await db.insert('rooms', {
        'roomNo': 'NB101', 'type': 'Theory', 'capacity': 40, 'floor': 1
      });
      await db.insert('rooms', {
        'roomNo': 'NB102', 'type': 'Theory', 'capacity': 40, 'floor': 1
      });
      await db.insert('rooms', {
        'roomNo': 'NB104', 'type': 'Theory', 'capacity': 45, 'floor': 1
      });
      await db.insert('rooms', {
        'roomNo': 'NB202', 'type': 'Theory', 'capacity': 40, 'floor': 2
      });

      // Insert Lab Rooms
      await db.insert('rooms', {
        'roomNo': 'NB103', 'type': 'Lab', 'capacity': 30, 'floor': 1, 'pcTotal': 30, 'pcActive': 28
      });
      await db.insert('rooms', {
        'roomNo': 'NB201', 'type': 'Lab', 'capacity': 30, 'floor': 2, 'pcTotal': 30, 'pcActive': 30
      });
      await db.insert('rooms', {
        'roomNo': 'NB203', 'type': 'Lab', 'capacity': 30, 'floor': 2, 'pcTotal': 30, 'pcActive': 25
      });
      await db.insert('rooms', {
        'roomNo': 'NB204', 'type': 'Lab', 'capacity': 35, 'floor': 2, 'pcTotal': 35, 'pcActive': 32
      });

      print('✅ Added 4 Theory rooms and 4 Lab rooms (Total: 8 rooms)');
    } catch (e) {
      print('❌ Error inserting default rooms: $e');
    }
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    print('🔄 Upgrading database from version $oldVersion to $newVersion');

    if (oldVersion < 3) {
      try {
        List<Map<String, dynamic>> tables = await db.rawQuery(
            "SELECT name FROM sqlite_master WHERE type='table' AND name='rooms'"
        );
        if (tables.isNotEmpty) {
          List<Map<String, dynamic>> columns = await db.rawQuery('PRAGMA table_info(rooms)');
          bool hasFloor = columns.any((col) => col['name'] == 'floor');
          if (!hasFloor) {
            await db.execute('''
              CREATE TABLE rooms_new(
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                roomNo TEXT UNIQUE NOT NULL,
                type TEXT NOT NULL,
                capacity INTEGER NOT NULL,
                floor INTEGER NOT NULL DEFAULT 1,
                equipment TEXT,
                pcTotal INTEGER,
                pcActive INTEGER,
                departmentId INTEGER,
                FOREIGN KEY (departmentId) REFERENCES departments (id) ON DELETE SET NULL
              )
            ''');
            await db.execute('''
              INSERT INTO rooms_new (id, roomNo, type, capacity, equipment, pcTotal, pcActive, departmentId)
              SELECT id, roomNo, type, capacity, equipment, pcTotal, pcActive, departmentId FROM rooms
            ''');
            await db.execute('DROP TABLE rooms');
            await db.execute('ALTER TABLE rooms_new RENAME TO rooms');
          }
        }
      } catch (e) {
        print('Error upgrading database to version 3: $e');
      }
    }

    if (oldVersion < 4) {
      try {
        await _insertDefaultRooms(db);
        print('✅ Database upgraded to version 4 successfully');
      } catch (e) {
        print('Error upgrading database to version 4: $e');
      }
    }

    if (oldVersion < 5) {
      try {
        List<Map<String, dynamic>> columns = await db.rawQuery('PRAGMA table_info(routines)');
        bool hasIsExtended = columns.any((col) => col['name'] == 'isExtended');
        bool hasMergedBatchInfo = columns.any((col) => col['name'] == 'mergedBatchInfo');

        if (!hasIsExtended) {
          await db.execute('ALTER TABLE routines ADD COLUMN isExtended INTEGER DEFAULT 0');
          print('✅ Added isExtended column to routines table');
        }

        if (!hasMergedBatchInfo) {
          await db.execute('ALTER TABLE routines ADD COLUMN mergedBatchInfo TEXT');
          print('✅ Added mergedBatchInfo column to routines table');
        }

        print('✅ Database upgraded to version 5 successfully');
      } catch (e) {
        print('Error upgrading database to version 5: $e');
      }
    }

    if (oldVersion < 6) {
      try {
        // Check and add missing columns for routines table
        List<Map<String, dynamic>> columns = await db.rawQuery('PRAGMA table_info(routines)');

        Map<String, bool> requiredColumns = {
          'courseId': false,
          'endSlot': false,
          'startTime': false,
          'endTime': false,
          'status': false,
          'conflictReason': false,
        };

        for (var col in columns) {
          String colName = col['name'] as String;
          if (requiredColumns.containsKey(colName)) {
            requiredColumns[colName] = true;
          }
        }

        for (var entry in requiredColumns.entries) {
          if (!entry.value) {
            String columnType = 'TEXT';
            if (entry.key == 'courseId' || entry.key == 'endSlot') {
              columnType = 'INTEGER';
            }
            await db.execute('ALTER TABLE routines ADD COLUMN ${entry.key} $columnType');
            print('✅ Added ${entry.key} column to routines table');
          }
        }

        print('✅ Database upgraded to version 6 successfully');
      } catch (e) {
        print('Error upgrading database to version 6: $e');
      }
    }
  }

  // Routine CRUD operations
  Future<int> insertRoutine(Map<String, dynamic> routine) async {
    Database db = await database;
    try {
      return await db.insert('routines', routine);
    } catch (e) {
      print('❌ Error inserting routine: $e');
      throw Exception('Failed to insert routine: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getRoutines() async {
    Database db = await database;
    try {
      return await db.query('routines', orderBy: 'day, slot');
    } catch (e) {
      print('❌ Error getting routines: $e');
      return [];
    }
  }

  Future<int> updateRoutine(Map<String, dynamic> routine) async {
    Database db = await database;
    try {
      return await db.update(
        'routines',
        routine,
        where: 'id = ?',
        whereArgs: [routine['id']],
      );
    } catch (e) {
      print('❌ Error updating routine: $e');
      throw Exception('Failed to update routine: $e');
    }
  }

  Future<int> deleteRoutine(int id) async {
    Database db = await database;
    try {
      return await db.delete(
        'routines',
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      print('❌ Error deleting routine: $e');
      throw Exception('Failed to delete routine: $e');
    }
  }

  Future<int> deleteRoutinesByBatch(String batchId, String type) async {
    Database db = await database;
    try {
      return await db.delete(
        'routines',
        where: 'batchId = ? AND type = ?',
        whereArgs: [batchId, type],
      );
    } catch (e) {
      print('❌ Error deleting routines by batch: $e');
      throw Exception('Failed to delete routines by batch: $e');
    }
  }

  Future<int> deleteRoutinesByDepartment(String departmentId, String type) async {
    Database db = await database;
    try {
      return await db.delete(
        'routines',
        where: 'departmentId = ? AND type = ?',
        whereArgs: [departmentId, type],
      );
    } catch (e) {
      print('❌ Error deleting routines by department: $e');
      throw Exception('Failed to delete routines by department: $e');
    }
  }

  Future<int> deleteAllRoutines(String type) async {
    Database db = await database;
    try {
      return await db.delete(
        'routines',
        where: 'type = ?',
        whereArgs: [type],
      );
    } catch (e) {
      print('❌ Error deleting all routines: $e');
      throw Exception('Failed to delete all routines: $e');
    }
  }

  Future<void> clearRoutines() async {
    Database db = await database;
    try {
      await db.delete('routines');
      print('✅ All routines cleared');
    } catch (e) {
      print('❌ Error clearing routines: $e');
      throw Exception('Failed to clear routines: $e');
    }
  }

  // Generic CRUD operations
  Future<int> insert(String table, Map<String, dynamic> data) async {
    Database db = await database;
    try {
      Map<String, dynamic> insertData = Map.from(data);
      if (insertData['id'] == null) {
        insertData.remove('id');
      }
      int result = await db.insert(table, insertData);
      print('✅ Inserted into $table, ID: $result');
      return result;
    } catch (e) {
      print('❌ Insert error in $table: $e');
      throw Exception('Failed to insert into $table: $e');
    }
  }

  Future<List<Map<String, dynamic>>> queryAll(String table) async {
    Database db = await database;
    try {
      List<Map<String, dynamic>> result = await db.query(table);
      print('✅ Queried $table, found ${result.length} records');
      return result;
    } catch (e) {
      print('❌ Query error in $table: $e');
      throw Exception('Failed to query $table: $e');
    }
  }

  Future<List<Map<String, dynamic>>> query(
      String table, {
        dynamic where,
        List<dynamic>? whereArgs,
        String? orderBy,
      }) async {
    Database db = await database;
    try {
      List<Map<String, dynamic>> result = await db.query(
        table,
        where: where,
        whereArgs: whereArgs,
        orderBy: orderBy,
      );
      return result;
    } catch (e) {
      print('❌ Query error in $table: $e');
      throw Exception('Failed to query $table: $e');
    }
  }

  Future<int> update(
      String table,
      Map<String, dynamic> data, {
        dynamic where,
        List<dynamic>? whereArgs,
      }) async {
    Database db = await database;
    try {
      Map<String, dynamic> updateData = Map.from(data);
      updateData.remove('id');

      int result = await db.update(
        table,
        updateData,
        where: where,
        whereArgs: whereArgs,
      );

      print('✅ Update result in $table: $result rows affected');
      return result;
    } catch (e) {
      print('❌ Update error in $table: $e');
      throw Exception('Failed to update $table: $e');
    }
  }

  Future<int> delete(
      String table, {
        dynamic where,
        List<dynamic>? whereArgs,
      }) async {
    Database db = await database;
    try {
      int result = await db.delete(
        table,
        where: where,
        whereArgs: whereArgs,
      );
      print('✅ Deleted from $table: $result rows');
      return result;
    } catch (e) {
      print('❌ Delete error in $table: $e');
      throw Exception('Failed to delete from $table: $e');
    }
  }

  Future<int> getCount(String table) async {
    Database db = await database;
    try {
      final result = await db.rawQuery('SELECT COUNT(*) as count FROM $table');
      int count = Sqflite.firstIntValue(result) ?? 0;
      return count;
    } catch (e) {
      print('❌ Count error in $table: $e');
      return 0;
    }
  }

  // Helper method to check if a table exists
  Future<bool> tableExists(String tableName) async {
    Database db = await database;
    try {
      final result = await db.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='table' AND name=?",
          [tableName]
      );
      return result.isNotEmpty;
    } catch (e) {
      print('❌ Error checking table existence: $e');
      return false;
    }
  }

  // Helper method to get table columns
  Future<List<String>> getTableColumns(String tableName) async {
    Database db = await database;
    try {
      final result = await db.rawQuery('PRAGMA table_info($tableName)');
      return result.map((col) => col['name'] as String).toList();
    } catch (e) {
      print('❌ Error getting table columns: $e');
      return [];
    }
  }
}