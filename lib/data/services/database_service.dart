import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import '../models/department_model.dart';
import '../models/teacher_model.dart';
import '../models/batch_model.dart';
import '../models/course_model.dart';
import '../models/room_model.dart';
import '../models/department_room_model.dart';
import '../models/routine_model.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

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
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Create departments table
    await db.execute('''
      CREATE TABLE departments(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        code TEXT NOT NULL
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
        role TEXT NOT NULL,
        interestedCourses TEXT,
        availableDays TEXT,
        availableSlots TEXT,
        maxLoad INTEGER,
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
        equipment TEXT,
        pcTotal INTEGER,
        pcActive INTEGER
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
        teacherId INTEGER NOT NULL,
        roomId INTEGER NOT NULL,
        day TEXT NOT NULL,
        slot INTEGER NOT NULL,
        endSlot INTEGER,
        date TEXT,
        FOREIGN KEY (departmentId) REFERENCES departments (id) ON DELETE CASCADE,
        FOREIGN KEY (batchId) REFERENCES batches (id) ON DELETE CASCADE,
        FOREIGN KEY (courseId) REFERENCES courses (id) ON DELETE CASCADE,
        FOREIGN KEY (teacherId) REFERENCES teachers (id) ON DELETE CASCADE,
        FOREIGN KEY (roomId) REFERENCES rooms (id) ON DELETE CASCADE
      )
    ''');

    // Insert default admin (for testing)
    await db.insert('teachers', {
      'name': 'Admin',
      'shortName': 'Admin',
      'username': 'admin',
      'password': 'admin123',
      'phone': '0000000000',
      'departmentId': 1,
      'role': 'admin',
    });
  }
}