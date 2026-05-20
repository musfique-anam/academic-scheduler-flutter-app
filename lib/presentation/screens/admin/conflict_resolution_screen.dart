// lib/presentation/screens/admin/conflict_resolution_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/routine_provider.dart';
import '../../../providers/teacher_provider.dart';
import '../../../providers/room_provider.dart';
import '../../../data/models/conflict_model.dart';
import '../../../data/models/routine_model.dart';
import '../../../data/models/teacher_model.dart';
import '../../../data/models/room_model.dart';
import '../../widgets/loading_widget.dart';

class ConflictResolutionScreen extends StatefulWidget {
  const ConflictResolutionScreen({super.key});

  @override
  State<ConflictResolutionScreen> createState() => _ConflictResolutionScreenState();
}

class _ConflictResolutionScreenState extends State<ConflictResolutionScreen> {
  int _selectedConflictIndex = 0;

  @override
  Widget build(BuildContext context) {
    final routineProvider = Provider.of<RoutineProvider>(context);
    final teacherProvider = Provider.of<TeacherProvider>(context);
    final roomProvider = Provider.of<RoomProvider>(context);

    if (routineProvider.conflicts.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Resolve Conflicts'),
          backgroundColor: const Color(0xFF1976D2),
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check_circle, size: 64, color: Colors.green),
              SizedBox(height: 16),
              Text(
                'No Conflicts Found!',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('Your routine is conflict-free'),
            ],
          ),
        ),
      );
    }

    return DefaultTabController(
      length: routineProvider.conflicts.length,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Resolve Conflicts'),
          backgroundColor: const Color(0xFF1976D2),
          foregroundColor: Colors.white,
          bottom: TabBar(
            isScrollable: true,
            tabs: List.generate(routineProvider.conflicts.length, (index) {
              return Tab(text: 'Conflict ${index + 1}');
            }),
          ),
        ),
        body: TabBarView(
          children: List.generate(routineProvider.conflicts.length, (index) {
            return _buildConflictTab(
              conflict: routineProvider.conflicts[index],
              teacherProvider: teacherProvider,
              roomProvider: roomProvider,
              routineProvider: routineProvider,
            );
          }),
        ),
      ),
    );
  }

  Widget _buildConflictTab({
    required Conflict conflict,
    required TeacherProvider teacherProvider,
    required RoomProvider roomProvider,
    required RoutineProvider routineProvider,
  }) {
    return Row(
      children: [
        // Left panel - Conflict details
        Expanded(
          flex: 2,
          child: _buildConflictDetails(conflict),
        ),
        // Right panel - Suggestions & Manual override
        Expanded(
          flex: 1,
          child: _buildSuggestionsPanel(
            conflict: conflict,
            teacherProvider: teacherProvider,
            roomProvider: roomProvider,
            routineProvider: routineProvider,
          ),
        ),
      ],
    );
  }

  Widget _buildConflictDetails(Conflict conflict) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Conflict header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.warning_amber, color: Colors.red[700], size: 30),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        conflict.type.toUpperCase(),
                        style: TextStyle(
                          color: Colors.red[700],
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        conflict.description,
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          const Text(
            'Conflicting Classes:',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 12),

          // Conflicting routines list - FIXED ListTile overflow
          Expanded(
            child: ListView.builder(
              itemCount: conflict.conflictingRoutines.length,
              itemBuilder: (context, index) {
                final routine = conflict.conflictingRoutines[index] as Routine;
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  color: Colors.amber[50],
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        // Left content
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${routine.courseCode} - ${routine.courseTitle}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text('Batch: ${routine.batchId}'),
                              Text('Teacher: ${routine.teacherName ?? 'Not assigned'}'),
                              Text('Room: ${routine.roomNo ?? 'Not assigned'}'),
                            ],
                          ),
                        ),
                        // Right slot indicator
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.red[100],
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Slot ${routine.slot}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionsPanel({
    required Conflict conflict,
    required TeacherProvider teacherProvider,
    required RoomProvider roomProvider,
    required RoutineProvider routineProvider,
  }) {
    // Generate suggestions dynamically if empty
    List<Map<String, dynamic>> suggestions = List.from(conflict.suggestions);

    // If no suggestions, create some default ones
    if (suggestions.isEmpty) {
      suggestions = _generateDefaultSuggestions(conflict);
    }

    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey[100],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Suggestions',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          // Suggestions list
          Expanded(
            child: suggestions.isEmpty
                ? const Center(
              child: Text('No suggestions available'),
            )
                : ListView.builder(
              itemCount: suggestions.length,
              itemBuilder: (context, index) {
                final suggestion = suggestions[index];
                final suggestedSlot = suggestion['suggestedSlot'] ?? 'N/A';
                final suggestedTime = suggestion['suggestedTime'] ??
                    suggestion['suggestion'] ??
                    'Try changing teacher or room';

                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                suggestion['action'] != null
                                    ? '${suggestion['action']}: ${suggestion['suggestion']}'
                                    : 'Move to Slot $suggestedSlot',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                suggestedTime is String ? suggestedTime : suggestedTime.toString(),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            _applySuggestion(conflict, suggestion, routineProvider);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                          ),
                          child: const Text('Apply'),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          const Divider(height: 32),

          // Manual override section
          const Text(
            'Manual Override',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),

          // Teacher override
          if (teacherProvider.teachers.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              child: DropdownButtonFormField<Teacher>(
                decoration: const InputDecoration(
                  labelText: 'Change Teacher',
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white,
                ),
                items: teacherProvider.teachers.map<DropdownMenuItem<Teacher>>(
                      (Teacher teacher) {
                    return DropdownMenuItem<Teacher>(
                      value: teacher,
                      child: Text('${teacher.name} (${teacher.shortName})'),
                    );
                  },
                ).toList(),
                onChanged: (Teacher? teacher) {
                  if (teacher != null) {
                    _applyTeacherChange(conflict, teacher, routineProvider);
                  }
                },
              ),
            ),

          // Room override
          if (roomProvider.rooms.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              child: DropdownButtonFormField<Room>(
                decoration: const InputDecoration(
                  labelText: 'Change Room',
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white,
                ),
                items: roomProvider.rooms.map<DropdownMenuItem<Room>>(
                      (Room room) {
                    return DropdownMenuItem<Room>(
                      value: room,
                      child: Text('${room.roomNo} (F${room.floor})'),
                    );
                  },
                ).toList(),
                onChanged: (Room? room) {
                  if (room != null) {
                    _applyRoomChange(conflict, room, routineProvider);
                  }
                },
              ),
            ),
        ],
      ),
    );
  }

  // Generate default suggestions for conflict
  List<Map<String, dynamic>> _generateDefaultSuggestions(Conflict conflict) {
    List<Map<String, dynamic>> suggestions = [];

    // Suggest moving to different slots
    List<int> alternativeSlots = [1, 2, 3, 4];
    for (int slot in alternativeSlots) {
      if (slot != conflict.slot) {
        suggestions.add({
          'suggestedSlot': slot,
          'suggestedTime': _getTimeForSlot(slot),
          'action': 'move',
          'priority': 1,
        });
      }
    }

    // If teacher conflict, suggest changing teacher
    if (conflict.type == 'teacher') {
      suggestions.add({
        'action': 'change_teacher',
        'suggestion': 'Assign a different teacher to this class',
        'priority': 2,
      });
    }

    // If room conflict, suggest changing room
    if (conflict.type == 'room') {
      suggestions.add({
        'action': 'change_room',
        'suggestion': 'Use a different room',
        'priority': 2,
      });
    }

    return suggestions;
  }

  String _getTimeForSlot(int slot) {
    switch(slot) {
      case 1: return '9:30 - 11:00';
      case 2: return '11:10 - 12:40';
      case 3: return '14:00 - 15:30';
      case 4: return '15:40 - 17:10';
      default: return '';
    }
  }

  void _applySuggestion(Conflict conflict, Map<String, dynamic> suggestion, RoutineProvider provider) {
    if (conflict.conflictingRoutines.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No routine to modify'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final routine = conflict.conflictingRoutines.first as Routine;

    final resolution = {
      'routineId': routine.id,
      'newSlot': suggestion['suggestedSlot'] ?? 2,
    };

    provider.resolveConflict(conflict, resolution);

    _refreshData(provider);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Suggestion applied'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _applyTeacherChange(Conflict conflict, Teacher teacher, RoutineProvider provider) {
    if (conflict.conflictingRoutines.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No routine to modify'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final routine = conflict.conflictingRoutines.first as Routine;

    final resolution = {
      'routineId': routine.id,
      'teacherId': teacher.id,
      'teacherName': teacher.name,
    };

    provider.resolveConflict(conflict, resolution);
    _refreshData(provider);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Teacher changed to ${teacher.name}'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _applyRoomChange(Conflict conflict, Room room, RoutineProvider provider) {
    if (conflict.conflictingRoutines.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No routine to modify'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final routine = conflict.conflictingRoutines.first as Routine;

    final resolution = {
      'routineId': routine.id,
      'roomId': room.id,
      'roomNo': room.roomNo,
    };

    provider.resolveConflict(conflict, resolution);
    _refreshData(provider);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Room changed to ${room.roomNo}'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _refreshData(RoutineProvider provider) async {
    await provider.loadRoutinesFromDatabase();
    if (mounted) {
      setState(() {});
    }
  }
}