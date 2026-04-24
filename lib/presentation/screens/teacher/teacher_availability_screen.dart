import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/teacher_provider.dart';
import '../../../providers/dashboard_provider.dart';
import '../../../data/models/teacher_model.dart';

class TeacherAvailabilityScreen extends StatefulWidget {
  final Teacher teacher;

  const TeacherAvailabilityScreen({super.key, required this.teacher});

  @override
  State<TeacherAvailabilityScreen> createState() => _TeacherAvailabilityScreenState();
}

class _TeacherAvailabilityScreenState extends State<TeacherAvailabilityScreen> {
  late Teacher _teacher;
  late List<String> _selectedDays;
  late List<int> _selectedSlots;
  bool _isLoading = false;

  final List<String> _availableDays = [
    'Friday', 'Saturday', 'Sunday', 'Monday', 'Tuesday'
  ];

  final List<Map<String, dynamic>> _availableSlots = const [
    {'slot': 1, 'time': '9:30 - 11:00'},
    {'slot': 2, 'time': '11:10 - 12:40'},
    {'slot': 3, 'time': '14:00 - 15:30'},
    {'slot': 4, 'time': '15:40 - 17:10'},
  ];

  @override
  void initState() {
    super.initState();
    _teacher = widget.teacher;
    _selectedDays = List.from(_teacher.availableDays);
    _selectedSlots = List.from(_teacher.availableSlots);
  }

  Future<void> _saveAvailability() async {
    setState(() => _isLoading = true);

    try {
      final teacherProvider = Provider.of<TeacherProvider>(context, listen: false);
      final dashboardProvider = Provider.of<DashboardProvider>(context, listen: false);

      Teacher updatedTeacher = Teacher(
        id: _teacher.id,
        name: _teacher.name,
        shortName: _teacher.shortName,
        username: _teacher.username,
        password: _teacher.password,
        phone: _teacher.phone,
        departmentId: _teacher.departmentId,
        role: _teacher.role,
        interestedCourses: _teacher.interestedCourses,
        availableDays: _selectedDays,
        availableSlots: _selectedSlots,
        maxLoad: _teacher.maxLoad,
        isProfileCompleted: _teacher.isProfileCompleted ||
            (_selectedDays.isNotEmpty && _selectedSlots.isNotEmpty),
      );

      bool success = await teacherProvider.updateTeacher(updatedTeacher);

      if (success) {
        await dashboardProvider.refreshDashboard();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Availability updated successfully'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Set Availability'),
        backgroundColor: const Color(0xFF1976D2),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _isLoading ? null : _saveAvailability,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info Card
            Card(
              color: Colors.blue[50],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.info, color: Color(0xFF1976D2)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Working Days & Slots',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1976D2),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Select the days and time slots when you are available for classes',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Available Days Section
            const Text(
              'Available Days',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: _availableDays.map((day) {
                    final isSelected = _selectedDays.contains(day);
                    return CheckboxListTile(
                      title: Text(day),
                      value: isSelected,
                      activeColor: const Color(0xFF1976D2),
                      onChanged: (selected) {
                        setState(() {
                          if (selected!) {
                            _selectedDays.add(day);
                          } else {
                            _selectedDays.remove(day);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Available Slots Section
            const Text(
              'Available Time Slots',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: _availableSlots.map((slot) {
                    final slotNum = slot['slot'] as int;
                    final isSelected = _selectedSlots.contains(slotNum);
                    return CheckboxListTile(
                      title: Text('Slot ${slot['slot']}: ${slot['time']}'),
                      value: isSelected,
                      activeColor: const Color(0xFF1976D2),
                      onChanged: (selected) {
                        setState(() {
                          if (selected!) {
                            _selectedSlots.add(slotNum);
                          } else {
                            _selectedSlots.remove(slotNum);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Summary Card
            Card(
              color: Colors.green[50],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Your Availability Summary',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Days: ${_selectedDays.isEmpty ? "None" : _selectedDays.join(", ")}',
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Slots: ${_selectedSlots.isEmpty ? "None" : _selectedSlots.map((s) => "Slot $s").join(", ")}',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}