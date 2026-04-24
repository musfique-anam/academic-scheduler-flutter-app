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

          // Conflicting routines list
          Expanded(
            child: ListView.builder(
              itemCount: conflict.conflictingRoutines.length,
              itemBuilder: (context, index) {
                final routine = conflict.conflictingRoutines[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  color: Colors.amber[50],
                  child: ListTile(
                    title: Text('${routine.courseCode} - ${routine.courseTitle}'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Batch: ${routine.batchId}'),
                        Text('Teacher: ${routine.teacherName ?? 'Not assigned'}'),
                        Text('Room: ${routine.roomNo ?? 'Not assigned'}'),
                      ],
                    ),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.red[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Slot ${routine.slot}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
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
            child: conflict.suggestions.isEmpty
                ? const Center(
              child: Text('No suggestions available'),
            )
                : ListView.builder(
              itemCount: conflict.suggestions.length,
              itemBuilder: (context, index) {
                final suggestion = conflict.suggestions[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    title: Text('Move to Slot ${suggestion['suggestedSlot']}'),
                    subtitle: Text(suggestion['suggestedTime']),
                    trailing: ElevatedButton(
                      onPressed: () {
                        _applySuggestion(conflict, suggestion, routineProvider);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                      child: const Text('Apply'),
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

          // Teacher override - FIXED
          Consumer<TeacherProvider>(
            builder: (context, provider, child) {
              if (provider.teachers.isEmpty) {
                return const Center(
                  child: Text('No teachers available'),
                );
              }
              return DropdownButtonFormField<Teacher>(
                decoration: const InputDecoration(
                  labelText: 'Change Teacher',
                  border: OutlineInputBorder(),
                ),
                items: provider.teachers.map<DropdownMenuItem<Teacher>>(
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
              );
            },
          ),

          const SizedBox(height: 8),

          // Room override - FIXED
          Consumer<RoomProvider>(
            builder: (context, provider, child) {
              if (provider.rooms.isEmpty) {
                return const Center(
                  child: Text('No rooms available'),
                );
              }
              return DropdownButtonFormField<Room>(
                decoration: const InputDecoration(
                  labelText: 'Change Room',
                  border: OutlineInputBorder(),
                ),
                items: provider.rooms.map<DropdownMenuItem<Room>>(
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
              );
            },
          ),
        ],
      ),
    );
  }

  void _applySuggestion(Conflict conflict, Map<String, dynamic> suggestion, RoutineProvider provider) {
    // Create resolution map
    final resolution = {
      'routineId': conflict.conflictingRoutines.first.id,
      'newSlot': suggestion['suggestedSlot'],
    };

    provider.resolveConflict(conflict, resolution);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Suggestion applied'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _applyTeacherChange(Conflict conflict, Teacher teacher, RoutineProvider provider) {
    // Get the first conflicting routine
    final routine = conflict.conflictingRoutines.first;

    // Create resolution map
    final resolution = {
      'routineId': routine.id,
      'teacherId': teacher.id,
      'teacherName': teacher.name,
    };

    // Apply the change
    provider.resolveConflict(conflict, resolution);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Teacher changed to ${teacher.name}'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _applyRoomChange(Conflict conflict, Room room, RoutineProvider provider) {
    // Get the first conflicting routine
    final routine = conflict.conflictingRoutines.first;

    // Create resolution map
    final resolution = {
      'routineId': routine.id,
      'roomId': room.id,
      'roomNo': room.roomNo,
    };

    // Apply the change
    provider.resolveConflict(conflict, resolution);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Room changed to ${room.roomNo}'),
        backgroundColor: Colors.green,
      ),
    );
  }
}