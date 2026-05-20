// lib/core/constants/time_slots.dart

import 'package:flutter/material.dart';

// Remove 'const' from this list - it cannot be const because Map is not constant
final List<Map<String, dynamic>> timeSlots = [
  {'slot': 1, 'time': '9:30 - 11:00', 'start': '9:30', 'end': '11:00'},
  {'slot': 2, 'time': '11:10 - 12:40', 'start': '11:10', 'end': '12:40'},
  {'slot': 3, 'time': '14:00 - 15:30', 'start': '14:00', 'end': '15:30'},
  {'slot': 4, 'time': '15:40 - 17:10', 'start': '15:40', 'end': '17:10'},
];

// Alternative: If you want to keep it as const, use a List of custom objects
class TimeSlot {
  final int slot;
  final String time;
  final String start;
  final String end;

  const TimeSlot({
    required this.slot,
    required this.time,
    required this.start,
    required this.end,
  });
}

// This can be const because it uses const objects
const List<TimeSlot> constTimeSlots = [
  TimeSlot(slot: 1, time: '9:30 - 11:00', start: '9:30', end: '11:00'),
  TimeSlot(slot: 2, time: '11:10 - 12:40', start: '11:10', end: '12:40'),
  TimeSlot(slot: 3, time: '14:00 - 15:30', start: '14:00', end: '15:30'),
  TimeSlot(slot: 4, time: '15:40 - 17:10', start: '15:40', end: '17:10'),
];

// Days list (can be const)
const List<String> days = [
  'Friday', 'Saturday', 'Sunday', 'Monday', 'Tuesday'
];