// // tools/setup_data.dart
//
// import 'package:sqflite_common_ffi/sqflite_ffi.dart';
// import 'package:path/path.dart';
// import 'dart:io';
//
// void main() async {
//   // Initialize FFI for SQLite
//   sqfliteFfiInit();
//
//   // Get database path
//   String path = join(Directory.current.path, 'academic_scheduler.db');
//
//   // Open database
//   Database db = await openDatabase(path);
//
//   print('🔧 Setting up initial data...');
//
//   // Update all teachers availability
//   await db.rawUpdate('''
//     UPDATE teachers
//     SET availableDays = 'Friday,Saturday,Sunday,Monday,Tuesday',
//         availableSlots = '1,2,3,4',
//         isProfileCompleted = 1
//     WHERE role = 'teacher'
//   ''');
//   print('✅ Updated all teachers availability');
//
//   // Get first teacher
//   final result = await db.rawQuery('SELECT id FROM teachers WHERE role = "teacher" LIMIT 1');
//   if (result.isNotEmpty) {
//     int teacherId = result.first['id'] as int;
//
//     // Assign to all courses
//     await db.rawUpdate('''
//       UPDATE courses
//       SET teacherId = $teacherId
//       WHERE teacherId IS NULL
//     ''');
//     print('✅ Assigned teacher ID $teacherId to all courses');
//   }
//
//   print('✅ Setup complete!');
//
//   await db.close();
// }