import '../models/exam_routine_model.dart';
import '../models/course_model.dart';
import '../models/room_model.dart';

class ExamRoutineGenerator {

  Future<List<ExamRoutine>> generateExamRoutine({
    required String examName,
    required List<int> departmentIds,
    required List<int> batchIds,
    required List<Course> courses,
    required List<int> roomIds,
    required List<Room> rooms,
    required DateTime startDate,
    required DateTime endDate,
    Function(double)? onProgress,
  }) async {
    List<ExamRoutine> routines = [];

    int totalExams = courses.length;
    int currentExam = 0;

    // Calculate available dates
    var availableDates = _getAvailableDates(startDate, endDate);

    // Track room usage
    Map<String, List<DateTime>> roomSchedule = {};

    for (var course in courses) {
      currentExam++;
      if (onProgress != null) {
        onProgress(currentExam / totalExams);
      }

      // Find available date and slot
      bool scheduled = false;

      for (var date in availableDates) {
        if (scheduled) break;

        for (int slot = 1; slot <= 4; slot++) {
          // Find available room from selected rooms
          for (var roomId in roomIds) {
            var room = rooms.firstWhere((r) => r.id == roomId);
            String roomKey = '${room.id}_$date';

            // Check if room is available on this date
            if (!roomSchedule.containsKey(roomKey)) {
              roomSchedule[roomKey] = [];
            }

            if (!roomSchedule[roomKey]!.contains(DateTime(date.year, date.month, date.day, slot))) {
              // Schedule exam
              routines.add(ExamRoutine(
                examName: examName,
                departmentIds: departmentIds,
                batchIds: [course.batchId],
                courseId: course.id!,
                courseCode: course.code,
                courseTitle: course.title,
                date: date,
                slot: slot,
                startTime: _getTimeForSlot(slot, 'start'),
                endTime: _getTimeForSlot(slot, 'end'),
                roomId: room.id,
                roomNo: room.roomNo,
                status: 'scheduled',
              ));

              roomSchedule[roomKey]!.add(DateTime(date.year, date.month, date.day, slot));
              scheduled = true;
              break;
            }
          }
          if (scheduled) break;
        }
      }

      if (!scheduled) {
        print('Warning: Could not schedule exam for ${course.code}');
      }
    }

    return routines;
  }

  List<DateTime> _getAvailableDates(DateTime start, DateTime end) {
    List<DateTime> dates = [];
    for (int i = 0; i <= end.difference(start).inDays; i++) {
      dates.add(start.add(Duration(days: i)));
    }
    return dates;
  }

  String _getTimeForSlot(int slot, String type) {
    switch(slot) {
      case 1: return type == 'start' ? '9:30' : '11:00';
      case 2: return type == 'start' ? '11:10' : '12:40';
      case 3: return type == 'start' ? '14:00' : '15:30';
      case 4: return type == 'start' ? '15:40' : '17:10';
      default: return '';
    }
  }
}