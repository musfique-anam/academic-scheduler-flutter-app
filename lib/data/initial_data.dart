import 'package:sqflite/sqflite.dart';
import 'models/department_model.dart';
import 'models/batch_model.dart' as model; // Add prefix 'as model'
import 'models/course_model.dart';
import 'models/teacher_model.dart';

class InitialData {

  // Departments Data
  static List<Department> departments = [
    Department(name: 'Computer Science & Engineering', code: 'CSE'),
    Department(name: 'Electrical & Electronic Engineering', code: 'EEE'),
    Department(name: 'Civil Engineering', code: 'CE'),
  ];

  // Batches Data (8 batches per department) - FIXED: Added 'model.' prefix
  static List<model.Batch> batches = [
    // CSE Batches (1-8)
    model.Batch(departmentId: 1, batchNo: 1, programType: 'HSC', totalStudents: 60),
    model.Batch(departmentId: 1, batchNo: 2, programType: 'HSC', totalStudents: 55),
    model.Batch(departmentId: 1, batchNo: 3, programType: 'HSC', totalStudents: 58),
    model.Batch(departmentId: 1, batchNo: 4, programType: 'HSC', totalStudents: 62),
    model.Batch(departmentId: 1, batchNo: 5, programType: 'HSC', totalStudents: 57),
    model.Batch(departmentId: 1, batchNo: 6, programType: 'HSC', totalStudents: 59),
    model.Batch(departmentId: 1, batchNo: 7, programType: 'HSC', totalStudents: 61),
    model.Batch(departmentId: 1, batchNo: 8, programType: 'HSC', totalStudents: 60),

    // EEE Batches (1-8)
    model.Batch(departmentId: 2, batchNo: 1, programType: 'HSC', totalStudents: 50),
    model.Batch(departmentId: 2, batchNo: 2, programType: 'HSC', totalStudents: 48),
    model.Batch(departmentId: 2, batchNo: 3, programType: 'HSC', totalStudents: 52),
    model.Batch(departmentId: 2, batchNo: 4, programType: 'HSC', totalStudents: 49),
    model.Batch(departmentId: 2, batchNo: 5, programType: 'HSC', totalStudents: 51),
    model.Batch(departmentId: 2, batchNo: 6, programType: 'HSC', totalStudents: 47),
    model.Batch(departmentId: 2, batchNo: 7, programType: 'HSC', totalStudents: 53),
    model.Batch(departmentId: 2, batchNo: 8, programType: 'HSC', totalStudents: 50),

    // Civil Batches (1-8)
    model.Batch(departmentId: 3, batchNo: 1, programType: 'HSC', totalStudents: 45),
    model.Batch(departmentId: 3, batchNo: 2, programType: 'HSC', totalStudents: 42),
    model.Batch(departmentId: 3, batchNo: 3, programType: 'HSC', totalStudents: 44),
    model.Batch(departmentId: 3, batchNo: 4, programType: 'HSC', totalStudents: 46),
    model.Batch(departmentId: 3, batchNo: 5, programType: 'HSC', totalStudents: 43),
    model.Batch(departmentId: 3, batchNo: 6, programType: 'HSC', totalStudents: 41),
    model.Batch(departmentId: 3, batchNo: 7, programType: 'HSC', totalStudents: 47),
    model.Batch(departmentId: 3, batchNo: 8, programType: 'HSC', totalStudents: 45),
  ];

  // CSE Courses Data
  static List<Map<String, dynamic>> cseCourses = [
    // 1st Semester
    {'code': 'CSE 1101', 'title': 'Structured Programming Language', 'credit': 3.0, 'type': 'Theory', 'batchId': 1},
    {'code': 'CSE 1102', 'title': 'Structured Programming Language Sessional', 'credit': 1.0, 'type': 'Lab', 'batchId': 1},
    {'code': 'CSE 1103', 'title': 'Discrete Mathematics', 'credit': 3.0, 'type': 'Theory', 'batchId': 1},
    {'code': 'EEE 1101', 'title': 'Basic Electrical Engineering', 'credit': 3.0, 'type': 'Theory', 'batchId': 1},
    {'code': 'EEE 1102', 'title': 'Basic Electrical Engineering Sessional', 'credit': 1.0, 'type': 'Lab', 'batchId': 1},
    {'code': 'MTH 1101', 'title': 'Differential and Integral Calculus and Matrices', 'credit': 3.0, 'type': 'Theory', 'batchId': 1},
    {'code': 'PHY 1101', 'title': 'Physics I', 'credit': 3.0, 'type': 'Theory', 'batchId': 1},
    {'code': 'ENG 1101', 'title': 'Technical and Communicative English', 'credit': 3.0, 'type': 'Theory', 'batchId': 1},
    {'code': 'CE 1102', 'title': 'Engineering Drawing and CAD Sessional', 'credit': 1.0, 'type': 'Lab', 'batchId': 1},

    // 2nd Semester
    {'code': 'CSE 1201', 'title': 'Data Structures', 'credit': 3.0, 'type': 'Theory', 'batchId': 2},
    {'code': 'CSE 1202', 'title': 'Data Structures Sessional', 'credit': 1.0, 'type': 'Lab', 'batchId': 2},
    {'code': 'CSE 1203', 'title': 'Object Oriented Programming Language', 'credit': 3.0, 'type': 'Theory', 'batchId': 2},
    {'code': 'CSE 1204', 'title': 'Object Oriented Programming Language Sessional', 'credit': 1.0, 'type': 'Lab', 'batchId': 2},
    {'code': 'EEE 1201', 'title': 'Electronic Devices and Circuits', 'credit': 3.0, 'type': 'Theory', 'batchId': 2},
    {'code': 'EEE 1202', 'title': 'Electronic Devices and Circuits Sessional', 'credit': 1.0, 'type': 'Lab', 'batchId': 2},
    {'code': 'PHY 1201', 'title': 'Physics II', 'credit': 3.0, 'type': 'Theory', 'batchId': 2},
    {'code': 'PHY 1202', 'title': 'Physics Sessional', 'credit': 1.0, 'type': 'Lab', 'batchId': 2},
    {'code': 'MTH 1201', 'title': 'Differential Equations and Transform Mathematics', 'credit': 3.0, 'type': 'Theory', 'batchId': 2},
    {'code': 'BAN 1201', 'title': 'Functional Bengali Language', 'credit': 2.0, 'type': 'Theory', 'batchId': 2},
    {'code': 'ENG 1202', 'title': 'Developing English Skills Sessional', 'credit': 1.0, 'type': 'Lab', 'batchId': 2},

    // 3rd Semester
    {'code': 'CSE 2101', 'title': 'Design and Analysis of Algorithms', 'credit': 3.0, 'type': 'Theory', 'batchId': 3},
    {'code': 'CSE 2102', 'title': 'Design and Analysis of Algorithms Sessional', 'credit': 1.0, 'type': 'Lab', 'batchId': 3},
    {'code': 'CSE 2103', 'title': 'Database Management Systems', 'credit': 3.0, 'type': 'Theory', 'batchId': 3},
    {'code': 'CSE 2104', 'title': 'Database Management Systems Sessional', 'credit': 1.0, 'type': 'Lab', 'batchId': 3},
    {'code': 'CSE 2105', 'title': 'Digital Electronics', 'credit': 3.0, 'type': 'Theory', 'batchId': 3},
    {'code': 'CSE 2106', 'title': 'Digital Electronics Sessional', 'credit': 1.0, 'type': 'Lab', 'batchId': 3},
    {'code': 'MTH 2101', 'title': 'Linear Algebra, Vector Analysis and Co-ordinate Geometry', 'credit': 3.0, 'type': 'Theory', 'batchId': 3},
    {'code': 'CHM 2101', 'title': 'Chemistry', 'credit': 3.0, 'type': 'Theory', 'batchId': 3},
    {'code': 'CHM 2102', 'title': 'Chemistry Sessional', 'credit': 1.0, 'type': 'Lab', 'batchId': 3},
    {'code': 'SS 2101', 'title': 'Engineering Economics', 'credit': 2.0, 'type': 'Theory', 'batchId': 3},

    // 4th Semester
    {'code': 'CSE 2201', 'title': 'Web Engineering', 'credit': 3.0, 'type': 'Theory', 'batchId': 4},
    {'code': 'CSE 2202', 'title': 'Web Engineering Sessional', 'credit': 1.0, 'type': 'Lab', 'batchId': 4},
    {'code': 'CSE 2203', 'title': 'Data Communication', 'credit': 3.0, 'type': 'Theory', 'batchId': 4},
    {'code': 'CSE 2205', 'title': 'Computer Architecture and Organization', 'credit': 3.0, 'type': 'Theory', 'batchId': 4},
    {'code': 'CSE 2206', 'title': 'Computer Architecture and Organization Sessional', 'credit': 1.0, 'type': 'Lab', 'batchId': 4},
    {'code': 'CSE 2207', 'title': 'Numerical Methods', 'credit': 2.0, 'type': 'Theory', 'batchId': 4},
    {'code': 'MTH 2201', 'title': 'Complex Variable, Probability and Statistics', 'credit': 3.0, 'type': 'Theory', 'batchId': 4},
    {'code': 'BUS 2201', 'title': 'Financial, Cost and Managerial Accounting', 'credit': 3.0, 'type': 'Theory', 'batchId': 4},
    {'code': 'HUM 2201', 'title': 'Bangladesh Studies and History of Independence', 'credit': 2.0, 'type': 'Theory', 'batchId': 4},

    // 5th Semester
    {'code': 'CSE 3100', 'title': 'Software Development Project I', 'credit': 1.0, 'type': 'Lab', 'batchId': 5},
    {'code': 'CSE 3102', 'title': 'Mobile Application Development Sessional', 'credit': 1.0, 'type': 'Lab', 'batchId': 5},
    {'code': 'CSE 3103', 'title': 'Operating Systems', 'credit': 3.0, 'type': 'Theory', 'batchId': 5},
    {'code': 'CSE 3104', 'title': 'Operating Systems Sessional', 'credit': 1.0, 'type': 'Lab', 'batchId': 5},
    {'code': 'CSE 3105', 'title': 'Microprocessors, Microcontrollers and Embedded Systems', 'credit': 3.0, 'type': 'Theory', 'batchId': 5},
    {'code': 'CSE 3106', 'title': 'Microprocessors, Microcontrollers and Embedded Systems Sessional', 'credit': 1.0, 'type': 'Lab', 'batchId': 5},
    {'code': 'CSE 3107', 'title': 'Software Design Pattern', 'credit': 2.0, 'type': 'Theory', 'batchId': 5},
    {'code': 'CSE 3110', 'title': 'Technical Writing and Presentation', 'credit': 1.0, 'type': 'Lab', 'batchId': 5},
    {'code': 'BUS 3101', 'title': 'Technology Entrepreneurship for Business', 'credit': 3.0, 'type': 'Theory', 'batchId': 5},
    {'code': 'HUM 3101', 'title': 'Professional Ethics and Environmental Protection', 'credit': 2.0, 'type': 'Theory', 'batchId': 5},
    {'code': 'CSE 3250', 'title': 'Industrial Training', 'credit': 1.0, 'type': 'Lab', 'batchId': 5},

    // 6th Semester
    {'code': 'CSE 3200', 'title': 'Software Development Project II', 'credit': 1.0, 'type': 'Lab', 'batchId': 6},
    {'code': 'CSE 3201', 'title': 'Compiler Design', 'credit': 3.0, 'type': 'Theory', 'batchId': 6},
    {'code': 'CSE 3202', 'title': 'Compiler Design Sessional', 'credit': 1.0, 'type': 'Lab', 'batchId': 6},
    {'code': 'CSE 3203', 'title': 'Digital Signal Processing', 'credit': 3.0, 'type': 'Theory', 'batchId': 6},
    {'code': 'CSE 3204', 'title': 'Digital Signal Sessional', 'credit': 1.0, 'type': 'Lab', 'batchId': 6},
    {'code': 'CSE 3205', 'title': 'Computer Networks', 'credit': 3.0, 'type': 'Theory', 'batchId': 6},
    {'code': 'CSE 3206', 'title': 'Computer Networks Sessional', 'credit': 1.0, 'type': 'Lab', 'batchId': 6},
    {'code': 'LAW 3201', 'title': 'Cyber and Intellectual Property Law', 'credit': 2.0, 'type': 'Theory', 'batchId': 6},

    // 7th Semester
    {'code': 'CSE 4000(A)', 'title': 'Thesis / Project', 'credit': 2.0, 'type': 'Lab', 'batchId': 7},
    {'code': 'CSE 4101', 'title': 'Big Data Analysis', 'credit': 3.0, 'type': 'Theory', 'batchId': 7},
    {'code': 'CSE 4102', 'title': 'Big Data Analysis Sessional', 'credit': 1.0, 'type': 'Lab', 'batchId': 7},
    {'code': 'CSE 4103', 'title': 'Cryptography and Network Security', 'credit': 3.0, 'type': 'Theory', 'batchId': 7},
    {'code': 'CSE 4104', 'title': 'Cryptography and Network Security Sessional', 'credit': 1.0, 'type': 'Lab', 'batchId': 7},
    {'code': 'CSE 4105', 'title': 'Artificial Intelligence', 'credit': 3.0, 'type': 'Theory', 'batchId': 7},
    {'code': 'CSE 4106', 'title': 'Artificial Intelligence Sessional', 'credit': 1.0, 'type': 'Lab', 'batchId': 7},

    // 8th Semester
    {'code': 'CSE 4000(B)', 'title': 'Thesis and Project', 'credit': 4.0, 'type': 'Lab', 'batchId': 8},
    {'code': 'CSE 4201', 'title': 'Computer Graphics', 'credit': 3.0, 'type': 'Theory', 'batchId': 8},
    {'code': 'CSE 4202', 'title': 'Computer Graphics Sessional', 'credit': 1.0, 'type': 'Lab', 'batchId': 8},
    {'code': 'CSE 4203', 'title': 'Machine Learning', 'credit': 3.0, 'type': 'Theory', 'batchId': 8},
    {'code': 'CSE 4204', 'title': 'Machine Learning Sessional', 'credit': 1.0, 'type': 'Lab', 'batchId': 8},
    {'code': 'CSE 4205', 'title': 'Digital Image Processing', 'credit': 3.0, 'type': 'Theory', 'batchId': 8},
    {'code': 'CSE 4206', 'title': 'Digital Image Processing Sessional', 'credit': 1.0, 'type': 'Lab', 'batchId': 8},
  ];

  // EEE Courses Data (First few, you can add more)
  static List<Map<String, dynamic>> eeeCourses = [
    // 1st Semester
    {'code': 'EEE 1101', 'title': 'Electrical Circuits I', 'credit': 3.0, 'type': 'Theory', 'batchId': 9},
    {'code': 'EEE 1102', 'title': 'Electrical Circuits I Lab', 'credit': 1.0, 'type': 'Lab', 'batchId': 9},
    {'code': 'CSE 1101', 'title': 'Computer Programming', 'credit': 3.0, 'type': 'Theory', 'batchId': 9},
    {'code': 'CSE 1102', 'title': 'Computer Programming Lab', 'credit': 1.0, 'type': 'Lab', 'batchId': 9},
    {'code': 'CE 1102', 'title': 'Engineering Drawing and CAD Lab', 'credit': 1.0, 'type': 'Lab', 'batchId': 9},
    {'code': 'MTH 1101', 'title': 'Differential and Integral Calculus & Matrices', 'credit': 3.0, 'type': 'Theory', 'batchId': 9},
    {'code': 'PHY 1101', 'title': 'Physics I', 'credit': 3.0, 'type': 'Theory', 'batchId': 9},
    {'code': 'ENG 1101', 'title': 'Technical and Communicative English', 'credit': 3.0, 'type': 'Theory', 'batchId': 9},
    {'code': 'HUM 1101', 'title': 'Bangladesh Studies and History of Independence', 'credit': 2.0, 'type': 'Theory', 'batchId': 9},
  ];

  // Civil Courses Data (First few, you can add more)
  static List<Map<String, dynamic>> civilCourses = [
    // 1st Semester
    {'code': 'CE 1101', 'title': 'Analytic Mechanics', 'credit': 4.0, 'type': 'Theory', 'batchId': 17},
    {'code': 'CHM 1101', 'title': 'Chemistry', 'credit': 3.0, 'type': 'Theory', 'batchId': 17},
    {'code': 'ENG 1101', 'title': 'Technical and Communicative English', 'credit': 3.0, 'type': 'Theory', 'batchId': 17},
    {'code': 'MTH 1101', 'title': 'Mathematics-I', 'credit': 3.0, 'type': 'Theory', 'batchId': 17},
    {'code': 'PHY 1101', 'title': 'Physics-I', 'credit': 3.0, 'type': 'Theory', 'batchId': 17},
    {'code': 'CE 1100', 'title': 'Civil Engineering Drawing-I', 'credit': 1.0, 'type': 'Lab', 'batchId': 17},
    {'code': 'CHM 1102', 'title': 'Chemistry Sessional', 'credit': 1.0, 'type': 'Lab', 'batchId': 17},
    {'code': 'ENG 1102', 'title': 'Developing English Skills Sessional', 'credit': 1.0, 'type': 'Lab', 'batchId': 17},
  ];

  // Teachers Data (15 per department)
  static List<Map<String, dynamic>> teachers = [
    // CSE Teachers (15)
    {'name': 'Dr. Mohammad Rahman', 'shortName': 'Dr. Rahman', 'username': 'rahman_cse', 'password': 'pass123', 'phone': '01711111111', 'departmentId': 1},
    {'name': 'Prof. Ahmed Khan', 'shortName': 'Prof. Khan', 'username': 'akhan_cse', 'password': 'pass123', 'phone': '01711111112', 'departmentId': 1},
    {'name': 'Dr. Fatema Begum', 'shortName': 'Dr. Begum', 'username': 'fbegum_cse', 'password': 'pass123', 'phone': '01711111113', 'departmentId': 1},
    {'name': 'Prof. Kamal Hossain', 'shortName': 'Prof. Hossain', 'username': 'khossain_cse', 'password': 'pass123', 'phone': '01711111114', 'departmentId': 1},
    {'name': 'Dr. Nusrat Jahan', 'shortName': 'Dr. Jahan', 'username': 'njahan_cse', 'password': 'pass123', 'phone': '01711111115', 'departmentId': 1},
    {'name': 'Prof. Shahidul Islam', 'shortName': 'Prof. Islam', 'username': 'sislam_cse', 'password': 'pass123', 'phone': '01711111116', 'departmentId': 1},
    {'name': 'Dr. Sumaiya Akter', 'shortName': 'Dr. Akter', 'username': 'sakter_cse', 'password': 'pass123', 'phone': '01711111117', 'departmentId': 1},
    {'name': 'Prof. Rezaul Karim', 'shortName': 'Prof. Karim', 'username': 'rkarim_cse', 'password': 'pass123', 'phone': '01711111118', 'departmentId': 1},
    {'name': 'Dr. Shahana Parvin', 'shortName': 'Dr. Parvin', 'username': 'sparvin_cse', 'password': 'pass123', 'phone': '01711111119', 'departmentId': 1},
    {'name': 'Prof. Moniruzzaman', 'shortName': 'Prof. Monir', 'username': 'mmonir_cse', 'password': 'pass123', 'phone': '01711111120', 'departmentId': 1},
    {'name': 'Dr. Tania Sultana', 'shortName': 'Dr. Sultana', 'username': 'tsultana_cse', 'password': 'pass123', 'phone': '01711111121', 'departmentId': 1},
    {'name': 'Prof. Hasan Mahmud', 'shortName': 'Prof. Mahmud', 'username': 'hmahmud_cse', 'password': 'pass123', 'phone': '01711111122', 'departmentId': 1},
    {'name': 'Dr. Sharmin Akhter', 'shortName': 'Dr. Akhter', 'username': 'sakhter_cse', 'password': 'pass123', 'phone': '01711111123', 'departmentId': 1},
    {'name': 'Prof. Jahirul Islam', 'shortName': 'Prof. Jahir', 'username': 'jjahir_cse', 'password': 'pass123', 'phone': '01711111124', 'departmentId': 1},
    {'name': 'Dr. Masuda Begum', 'shortName': 'Dr. Masuda', 'username': 'mbegum_cse', 'password': 'pass123', 'phone': '01711111125', 'departmentId': 1},

    // EEE Teachers (15)
    {'name': 'Dr. Abdul Latif', 'shortName': 'Dr. Latif', 'username': 'alatif_eee', 'password': 'pass123', 'phone': '01711111126', 'departmentId': 2},
    {'name': 'Prof. Selina Begum', 'shortName': 'Prof. Selina', 'username': 'sbegum_eee', 'password': 'pass123', 'phone': '01711111127', 'departmentId': 2},
    {'name': 'Dr. Rafiqul Islam', 'shortName': 'Dr. Rafiq', 'username': 'rislam_eee', 'password': 'pass123', 'phone': '01711111128', 'departmentId': 2},
    {'name': 'Prof. Shahida Akter', 'shortName': 'Prof. Shahida', 'username': 'sakter_eee', 'password': 'pass123', 'phone': '01711111129', 'departmentId': 2},
    {'name': 'Dr. Mokhlesur Rahman', 'shortName': 'Dr. Mokhles', 'username': 'mrahman_eee', 'password': 'pass123', 'phone': '01711111130', 'departmentId': 2},
    {'name': 'Prof. Shamim Ara', 'shortName': 'Prof. Shamim', 'username': 'sara_eee', 'password': 'pass123', 'phone': '01711111131', 'departmentId': 2},
    {'name': 'Dr. Zahid Hasan', 'shortName': 'Dr. Zahid', 'username': 'zhasan_eee', 'password': 'pass123', 'phone': '01711111132', 'departmentId': 2},
    {'name': 'Prof. Nasrin Sultana', 'shortName': 'Prof. Nasrin', 'username': 'nsultana_eee', 'password': 'pass123', 'phone': '01711111133', 'departmentId': 2},
    {'name': 'Dr. Khaleda Begum', 'shortName': 'Dr. Khaleda', 'username': 'kbegum_eee', 'password': 'pass123', 'phone': '01711111134', 'departmentId': 2},
    {'name': 'Prof. Nurul Islam', 'shortName': 'Prof. Nurul', 'username': 'nislam_eee', 'password': 'pass123', 'phone': '01711111135', 'departmentId': 2},
    {'name': 'Dr. Farida Yeasmin', 'shortName': 'Dr. Farida', 'username': 'fyeasmin_eee', 'password': 'pass123', 'phone': '01711111136', 'departmentId': 2},
    {'name': 'Prof. Rafiqul Alam', 'shortName': 'Prof. Rafiq', 'username': 'ralam_eee', 'password': 'pass123', 'phone': '01711111137', 'departmentId': 2},
    {'name': 'Dr. Shamsul Haque', 'shortName': 'Dr. Shamsul', 'username': 'shaque_eee', 'password': 'pass123', 'phone': '01711111138', 'departmentId': 2},
    {'name': 'Prof. Mahmuda Khatun', 'shortName': 'Prof. Mahmuda', 'username': 'mkhatun_eee', 'password': 'pass123', 'phone': '01711111139', 'departmentId': 2},
    {'name': 'Dr. Tanvir Ahmed', 'shortName': 'Dr. Tanvir', 'username': 'tahmed_eee', 'password': 'pass123', 'phone': '01711111140', 'departmentId': 2},

    // Civil Teachers (15)
    {'name': 'Dr. Abul Hossain', 'shortName': 'Dr. Abul', 'username': 'ahossain_civil', 'password': 'pass123', 'phone': '01711111141', 'departmentId': 3},
    {'name': 'Prof. Selina Akhter', 'shortName': 'Prof. Selina', 'username': 'sakhter_civil', 'password': 'pass123', 'phone': '01711111142', 'departmentId': 3},
    {'name': 'Dr. Mahbubur Rahman', 'shortName': 'Dr. Mahbub', 'username': 'mrahman_civil', 'password': 'pass123', 'phone': '01711111143', 'departmentId': 3},
    {'name': 'Prof. Sharmin Sultana', 'shortName': 'Prof. Sharmin', 'username': 'ssultana_civil', 'password': 'pass123', 'phone': '01711111144', 'departmentId': 3},
    {'name': 'Dr. Kamal Uddin', 'shortName': 'Dr. Kamal', 'username': 'kuddin_civil', 'password': 'pass123', 'phone': '01711111145', 'departmentId': 3},
    {'name': 'Prof. Nasima Begum', 'shortName': 'Prof. Nasima', 'username': 'nbegum_civil', 'password': 'pass123', 'phone': '01711111146', 'departmentId': 3},
    {'name': 'Dr. Saiful Islam', 'shortName': 'Dr. Saiful', 'username': 'sislam_civil', 'password': 'pass123', 'phone': '01711111147', 'departmentId': 3},
    {'name': 'Prof. Tahmina Akter', 'shortName': 'Prof. Tahmina', 'username': 'takter_civil', 'password': 'pass123', 'phone': '01711111148', 'departmentId': 3},
    {'name': 'Dr. Rezaul Karim', 'shortName': 'Dr. Rezaul', 'username': 'rkarim_civil', 'password': 'pass123', 'phone': '01711111149', 'departmentId': 3},
    {'name': 'Prof. Momtaz Begum', 'shortName': 'Prof. Momtaz', 'username': 'mbegum_civil', 'password': 'pass123', 'phone': '01711111150', 'departmentId': 3},
    {'name': 'Dr. Anwar Hossain', 'shortName': 'Dr. Anwar', 'username': 'ahossain2_civil', 'password': 'pass123', 'phone': '01711111151', 'departmentId': 3},
    {'name': 'Prof. Shahana Parvin', 'shortName': 'Prof. Shahana', 'username': 'sparvin_civil', 'password': 'pass123', 'phone': '01711111152', 'departmentId': 3},
    {'name': 'Dr. Rafiqul Islam', 'shortName': 'Dr. Rafiq', 'username': 'rislam_civil', 'password': 'pass123', 'phone': '01711111153', 'departmentId': 3},
    {'name': 'Prof. Nazma Begum', 'shortName': 'Prof. Nazma', 'username': 'nbegum2_civil', 'password': 'pass123', 'phone': '01711111154', 'departmentId': 3},
    {'name': 'Dr. Jahirul Islam', 'shortName': 'Dr. Jahir', 'username': 'jislam_civil', 'password': 'pass123', 'phone': '01711111155', 'departmentId': 3},
  ];

  // Function to insert all data
  static Future<void> insertAllData(Database db) async {
    print('📥 Inserting initial data...');

    // Insert departments
    for (var dept in departments) {
      await db.insert('departments', dept.toMap());
    }
    print('✅ Departments inserted');

    // Insert batches
    for (var batch in batches) {
      await db.insert('batches', batch.toMap());
    }
    print('✅ Batches inserted');

    // Insert CSE courses
    for (var course in cseCourses) {
      await db.insert('courses', course);
    }
    print('✅ CSE courses inserted');

    // Insert EEE courses
    for (var course in eeeCourses) {
      await db.insert('courses', course);
    }
    print('✅ EEE courses inserted');

    // Insert Civil courses
    for (var course in civilCourses) {
      await db.insert('courses', course);
    }
    print('✅ Civil courses inserted');

    // Insert teachers
    for (var teacher in teachers) {
      await db.insert('teachers', teacher);
    }
    print('✅ Teachers inserted');

    print('🎉 All initial data inserted successfully!');
  }
}