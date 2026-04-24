class AppConstants {
  static const String appName = 'Smart Academic Scheduler';
  static const String universityName = 'Pundra University of Science & Technology';

  // Working days
  static const List<String> workingDays = ['Friday', 'Saturday', 'Sunday', 'Monday', 'Tuesday'];

  // Program types
  static const String programHSC = 'HSC';
  static const String programDiploma = 'Diploma';

  // Program allowed days
  static const Map<String, List<String>> programAllowedDays = {
    'Diploma': ['Friday', 'Saturday'],
    'HSC': ['Saturday', 'Sunday', 'Monday', 'Tuesday'],
  };

  // Time slots
  static const Map<int, Map<String, String>> timeSlots = {
    1: {'start': '9:30', 'end': '11:00'},
    2: {'start': '11:10', 'end': '12:40'},
    3: {'start': '14:00', 'end': '15:30'},
    4: {'start': '15:40', 'end': '17:10'},
  };

  // User roles
  static const String roleAdmin = 'admin';
  static const String roleTeacher = 'teacher';

  // Batch range
  static const int minBatch = 1;
  static const int maxBatch = 100;

  // Database name
  static const String databaseName = 'academic_scheduler.db';
  static const int databaseVersion = 1;
}