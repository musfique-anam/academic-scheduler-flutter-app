class TimeSlot {
  final int slotNumber;
  final String startTime;
  final String endTime;

  TimeSlot({
    required this.slotNumber,
    required this.startTime,
    required this.endTime,
  });
}

class TimeSlots {
  static const List<TimeSlot> slots = [
    TimeSlot(slotNumber: 1, startTime: '9:30', endTime: '11:00'),
    TimeSlot(slotNumber: 2, startTime: '11:10', endTime: '12:40'),
    TimeSlot(slotNumber: 3, startTime: '14:00', endTime: '15:30'),
    TimeSlot(slotNumber: 4, startTime: '15:40', endTime: '17:10'),
  ];

  // Lab requires 2 consecutive slots
  static const int labSlotsRequired = 2;

  static TimeSlot getSlotByNumber(int number) {
    return slots.firstWhere((slot) => slot.slotNumber == number);
  }

  static List<TimeSlot> getConsecutiveSlots(int startSlot) {
    if (startSlot + labSlotsRequired - 1 <= slots.length) {
      return slots.skip(startSlot - 1).take(labSlotsRequired).toList();
    }
    return [];
  }
}