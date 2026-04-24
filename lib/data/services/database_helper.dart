import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../initial_data.dart';
import 'package:path_provider/path_provider.dart';

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
      version: 3,
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

    // Create routines table
    await db.execute('''
    CREATE TABLE routines(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      type TEXT NOT NULL,
      departmentId INTEGER NOT NULL,
      batchId INTEGER,
      courseId INTEGER NOT NULL,
      courseCode TEXT NOT NULL,
      courseTitle TEXT NOT NULL,
      teacherId INTEGER,
      teacherName TEXT,
      roomId INTEGER,
      roomNo TEXT,
      day TEXT NOT NULL,
      slot INTEGER NOT NULL,
      endSlot INTEGER,
      startTime TEXT NOT NULL,
      endTime TEXT NOT NULL,
      date TEXT,
      status TEXT NOT NULL,
      conflictReason TEXT,
      FOREIGN KEY (departmentId) REFERENCES departments (id) ON DELETE CASCADE,
      FOREIGN KEY (batchId) REFERENCES batches (id) ON DELETE CASCADE,
      FOREIGN KEY (courseId) REFERENCES courses (id) ON DELETE CASCADE,
      FOREIGN KEY (teacherId) REFERENCES teachers (id) ON DELETE SET NULL,
      FOREIGN KEY (roomId) REFERENCES rooms (id) ON DELETE SET NULL
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

    // 🔴 IMPORTANT: Insert initial curriculum data
    await InitialData.insertAllData(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 3) {
      try {
        // Check if rooms table exists
        List<Map<String, dynamic>> tables = await db.rawQuery(
            "SELECT name FROM sqlite_master WHERE type='table' AND name='rooms'"
        );

        if (tables.isNotEmpty) {
          // Get current columns
          List<Map<String, dynamic>> columns = await db.rawQuery('PRAGMA table_info(rooms)');
          bool hasFloor = columns.any((col) => col['name'] == 'floor');

          if (!hasFloor) {
            // Create new table with all columns
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

            // Copy data from old table
            await db.execute('''
              INSERT INTO rooms_new (id, roomNo, type, capacity, equipment, pcTotal, pcActive, departmentId)
              SELECT id, roomNo, type, capacity, equipment, pcTotal, pcActive, departmentId FROM rooms
            ''');

            // Drop old table
            await db.execute('DROP TABLE rooms');

            // Rename new table
            await db.execute('ALTER TABLE rooms_new RENAME TO rooms');
          }
        }

        print('Database upgraded to version 3 successfully');
      } catch (e) {
        print('Error upgrading database: $e');
      }
    }
  }

  Future<int> insert(String table, Map<String, dynamic> data) async {
    Database db = await database;
    try {
      if (data['id'] == null) {
        data.remove('id');
      }
      int result = await db.insert(table, data);
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
      print('📝 Updating $table with data: $data');
      print('📝 Where: $where, Args: $whereArgs');

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
      print('📊 Count in $table: $count');
      return count;
    } catch (e) {
      print('❌ Count error in $table: $e');
      return 0;
    }
  }
}