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

class ConflictResolutionScreen extends StatefulWidget {
  const ConflictResolutionScreen({super.key});

  @override
  State<ConflictResolutionScreen> createState() =>
      _ConflictResolutionScreenState();
}

class _ConflictResolutionScreenState extends State<ConflictResolutionScreen> {
  bool _isResolving = false;

  @override
  Widget build(BuildContext context) {
    final routineProvider = context.watch<RoutineProvider>();
    final teacherProvider = context.watch<TeacherProvider>();
    final roomProvider = context.watch<RoomProvider>();

    final conflictCount = routineProvider.conflicts.length;
    debugPrint('🔄 BUILD ConflictResolutionScreen: $conflictCount');

    if (conflictCount == 0) {
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
      key: ValueKey('conflicts_$conflictCount'),
      length: conflictCount,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Conflicts ($conflictCount)'),
          backgroundColor: const Color(0xFF1976D2),
          foregroundColor: Colors.white,
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: TextButton.icon(
                icon: _isResolving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.auto_fix_high, color: Colors.white),
                label: const Text(
                  'Auto Resolve',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
                onPressed: _isResolving
                    ? null
                    : () => _autoResolveAll(
                        routineProvider, teacherProvider, roomProvider),
              ),
            ),
          ],
          bottom: TabBar(
            isScrollable: true,
            tabs: List.generate(conflictCount, (index) {
              return Tab(text: 'C${index + 1}');
            }),
          ),
        ),
        body: TabBarView(
          children: List.generate(conflictCount, (index) {
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

  Future<void> _autoResolveAll(
    RoutineProvider routineProvider,
    TeacherProvider teacherProvider,
    RoomProvider roomProvider,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Auto Resolve All Conflicts'),
        content: Text(
          'This will try to automatically resolve all '
          '${routineProvider.conflicts.length} conflicts. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Yes, Resolve',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isResolving = true);

    int totalResolved = 0;
    int iter = 0;
    const maxIterations = 8;

    while (iter < maxIterations) {
      final conflicts = List<Conflict>.from(routineProvider.conflicts);
      if (conflicts.isEmpty) break;

      int resolvedThisRound = 0;

      for (final conflict in conflicts) {
        if (conflict.conflictingRoutines.length < 2) continue;

        final target = conflict.conflictingRoutines[1] as Routine;
        final all = routineProvider.routines;

        bool fixed = false;

        for (int slot = 1; slot <= 4; slot++) {
          if (slot == target.slot) continue;
          if (_isSlotFree(all, target, newSlot: slot, newDay: target.day)) {
            fixed = await routineProvider.resolveConflict(conflict, {
              'routineId': target.id,
              'newSlot': slot,
            });
            if (fixed) break;
          }
        }

        if (!fixed) {
          const days = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday'];
          for (final day in days) {
            if (day == target.day) continue;
            for (int slot = 1; slot <= 4; slot++) {
              if (_isSlotFree(all, target, newSlot: slot, newDay: day)) {
                fixed = await routineProvider.resolveConflict(conflict, {
                  'routineId': target.id,
                  'newSlot': slot,
                  'newDay': day,
                });
                if (fixed) break;
              }
            }
            if (fixed) break;
          }
        }

        if (!fixed &&
            conflict.type == 'room' &&
            roomProvider.rooms.isNotEmpty) {
          for (final room in roomProvider.rooms) {
            if (room.roomNo == target.roomNo) continue;
            if (_isRoomFree(all, target, room.roomNo)) {
              fixed = await routineProvider.resolveConflict(conflict, {
                'routineId': target.id,
                'roomId': room.id,
                'roomNo': room.roomNo,
              });
              if (fixed) break;
            }
          }
        }

        if (!fixed &&
            conflict.type == 'teacher' &&
            teacherProvider.teachers.isNotEmpty) {
          for (final teacher in teacherProvider.teachers) {
            if (teacher.name == target.teacherName) continue;
            if (_isTeacherFree(all, target, teacher.name)) {
              fixed = await routineProvider.resolveConflict(conflict, {
                'routineId': target.id,
                'teacherId': teacher.id,
                'teacherName': teacher.name,
              });
              if (fixed) break;
            }
          }
        }

        if (fixed) {
          totalResolved++;
          resolvedThisRound++;
        }
      }

      if (resolvedThisRound == 0) break;
      iter++;
    }

    await routineProvider.loadRoutinesFromDatabase();

    if (!mounted) return;
    setState(() => _isResolving = false);

    final remaining = routineProvider.conflicts.length;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: remaining == 0 ? Colors.green : Colors.orange,
        duration: const Duration(seconds: 5),
        content: Text(
          remaining == 0
              ? '✅ All conflicts resolved! ($totalResolved fixed)'
              : '✓ Resolved $totalResolved. $remaining need manual fix.',
        ),
      ),
    );
  }

  bool _isSlotFree(List<Routine> all, Routine target,
      {required int newSlot, required String newDay}) {
    for (final r in all) {
      if (r.id == target.id) continue;
      if (r.day != newDay || r.slot != newSlot) continue;
      if (r.batchId == target.batchId) return false;
      if (r.teacherName != null &&
          target.teacherName != null &&
          r.teacherName == target.teacherName) return false;
      if (r.roomNo != null &&
          target.roomNo != null &&
          r.roomNo == target.roomNo) return false;
    }
    return true;
  }

  bool _isRoomFree(List<Routine> all, Routine target, String? roomNo) {
    if (roomNo == null) return false;
    for (final r in all) {
      if (r.id == target.id) continue;
      if (r.day == target.day &&
          r.slot == target.slot &&
          r.roomNo == roomNo) return false;
    }
    return true;
  }

  bool _isTeacherFree(List<Routine> all, Routine target, String teacherName) {
    for (final r in all) {
      if (r.id == target.id) continue;
      if (r.day == target.day &&
          r.slot == target.slot &&
          r.teacherName == teacherName) return false;
    }
    return true;
  }

  // ✅ NEW LAYOUT — single scrollable column, full-width sections
  Widget _buildConflictTab({
    required Conflict conflict,
    required TeacherProvider teacherProvider,
    required RoomProvider roomProvider,
    required RoutineProvider routineProvider,
  }) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildConflictHeader(conflict),
          const SizedBox(height: 16),
          _buildConflictingClassesSection(conflict),
          const SizedBox(height: 24),
          _buildSuggestionsSection(conflict, routineProvider),
          const SizedBox(height: 24),
          _buildManualOverrideSection(
              conflict, teacherProvider, roomProvider, routineProvider),
        ],
      ),
    );
  }

  Widget _buildConflictHeader(Conflict conflict) {
    return Container(
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
                Text(conflict.description,
                    style: const TextStyle(fontSize: 15)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConflictingClassesSection(Conflict conflict) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Conflicting Classes',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        ...conflict.conflictingRoutines.map((r) {
          final routine = r as Routine;
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            color: Colors.amber[50],
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${routine.courseCode} - ${routine.courseTitle}',
                          style:
                              const TextStyle(fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.red[100],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text('Slot ${routine.slot}',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text('Day: ${routine.day}',
                      style: const TextStyle(fontSize: 13)),
                  Text('Batch: ${routine.batchId}',
                      style: const TextStyle(fontSize: 13)),
                  Text(
                      'Teacher: ${routine.teacherName ?? 'Not assigned'}',
                      style: const TextStyle(fontSize: 13)),
                  Text('Room: ${routine.roomNo ?? 'Not assigned'}',
                      style: const TextStyle(fontSize: 13)),
                ],
              ),
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildSuggestionsSection(
      Conflict conflict, RoutineProvider routineProvider) {
    final suggestions = _generateDefaultSuggestions(conflict);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Suggestions',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          ...suggestions.map((suggestion) {
            final suggestedSlot = suggestion['suggestedSlot'] ?? 'N/A';
            final suggestedTime = suggestion['suggestedTime'] ??
                suggestion['suggestion'] ??
                '';

            final mainText = suggestion['action'] != null &&
                    suggestion['suggestion'] != null
                ? '${suggestion['action']}: ${suggestion['suggestion']}'
                : 'Move to Slot $suggestedSlot';

            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            mainText,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14),
                            softWrap: true,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            suggestedTime.toString(),
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey[600]),
                            softWrap: true,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 80,
                      child: ElevatedButton(
                        onPressed: () => _applySuggestion(
                            conflict, suggestion, routineProvider),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 8),
                        ),
                        child: const Text('Apply',
                            style: TextStyle(color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildManualOverrideSection(
      Conflict conflict,
      TeacherProvider teacherProvider,
      RoomProvider roomProvider,
      RoutineProvider routineProvider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Manual Override',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          if (teacherProvider.teachers.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: DropdownButtonFormField<Teacher>(
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Change Teacher',
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white,
                ),
                items: teacherProvider.teachers
                    .map<DropdownMenuItem<Teacher>>((Teacher teacher) {
                  return DropdownMenuItem<Teacher>(
                    value: teacher,
                    child: Text(
                      '${teacher.name} (${teacher.shortName})',
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
                onChanged: (Teacher? teacher) {
                  if (teacher != null) {
                    _applyTeacherChange(conflict, teacher, routineProvider);
                  }
                },
              ),
            ),
          if (roomProvider.rooms.isNotEmpty)
            DropdownButtonFormField<Room>(
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Change Room',
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Colors.white,
              ),
              items: roomProvider.rooms
                  .map<DropdownMenuItem<Room>>((Room room) {
                return DropdownMenuItem<Room>(
                  value: room,
                  child: Text(
                    '${room.roomNo} (Floor ${room.floor})',
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: (Room? room) {
                if (room != null) {
                  _applyRoomChange(conflict, room, routineProvider);
                }
              },
            ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _generateDefaultSuggestions(Conflict conflict) {
    List<Map<String, dynamic>> suggestions = [];
    for (int slot in [1, 2, 3, 4]) {
      if (slot != conflict.slot) {
        suggestions.add({
          'suggestedSlot': slot,
          'suggestedTime': _getTimeForSlot(slot),
          'action': 'move',
        });
      }
    }
    if (conflict.type == 'teacher') {
      suggestions.add({
        'action': 'change_teacher',
        'suggestion': 'Assign a different teacher',
      });
    }
    if (conflict.type == 'room') {
      suggestions.add({
        'action': 'change_room',
        'suggestion': 'Use a different room',
      });
    }
    return suggestions;
  }

  String _getTimeForSlot(int slot) {
    switch (slot) {
      case 1:
        return '9:30 - 11:00';
      case 2:
        return '11:10 - 12:40';
      case 3:
        return '14:00 - 15:30';
      case 4:
        return '15:40 - 17:10';
      default:
        return '';
    }
  }

  Future<void> _applySuggestion(Conflict conflict,
      Map<String, dynamic> suggestion, RoutineProvider provider) async {
    if (conflict.conflictingRoutines.isEmpty) return;
    final routine = conflict.conflictingRoutines.first as Routine;
    await provider.resolveConflict(conflict, {
      'routineId': routine.id,
      'newSlot': suggestion['suggestedSlot'] ?? 2,
    });
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Suggestion applied'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _applyTeacherChange(
      Conflict conflict, Teacher teacher, RoutineProvider provider) async {
    if (conflict.conflictingRoutines.isEmpty) return;
    final routine = conflict.conflictingRoutines.first as Routine;
    await provider.resolveConflict(conflict, {
      'routineId': routine.id,
      'teacherId': teacher.id,
      'teacherName': teacher.name,
    });
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Teacher changed to ${teacher.name}'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _applyRoomChange(
      Conflict conflict, Room room, RoutineProvider provider) async {
    if (conflict.conflictingRoutines.isEmpty) return;
    final routine = conflict.conflictingRoutines.first as Routine;
    await provider.resolveConflict(conflict, {
      'routineId': routine.id,
      'roomId': room.id,
      'roomNo': room.roomNo,
    });
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Room changed to ${room.roomNo}'),
        backgroundColor: Colors.green,
      ),
    );
  }
}