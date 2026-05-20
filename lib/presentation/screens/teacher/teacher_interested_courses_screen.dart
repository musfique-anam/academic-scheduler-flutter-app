import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/teacher_provider.dart';
import '../../../providers/course_provider.dart';
import '../../../providers/department_provider.dart';
import '../../../providers/dashboard_provider.dart';
import '../../../data/models/teacher_model.dart';
import '../../../data/models/course_model.dart';

class TeacherInterestedCoursesScreen extends StatefulWidget {
  final Teacher teacher;

  const TeacherInterestedCoursesScreen({super.key, required this.teacher});

  @override
  State<TeacherInterestedCoursesScreen> createState() => _TeacherInterestedCoursesScreenState();
}

class _TeacherInterestedCoursesScreenState extends State<TeacherInterestedCoursesScreen> {
  late Teacher _teacher;
  late List<int> _selectedCourseIds;
  bool _isLoading = false;
  List<Course> _availableCourses = [];

  @override
  void initState() {
    super.initState();
    _teacher = widget.teacher;
    _selectedCourseIds = List.from(_teacher.interestedCourses);
    _loadCourses();
  }

  Future<void> _loadCourses() async {
    final courseProvider = Provider.of<CourseProvider>(context, listen: false);
    await courseProvider.loadCourses();
    setState(() {
      _availableCourses = courseProvider.courses
          .where((c) => c.batchId != null) // Only courses assigned to batches
          .toList();
    });
  }

  Future<void> _saveInterestedCourses() async {
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
        interestedCourses: _selectedCourseIds,
        availableDays: _teacher.availableDays,
        availableSlots: _teacher.availableSlots,
        maxLoad: _teacher.maxLoad,
        isProfileCompleted: _teacher.isProfileCompleted ||
            (_selectedCourseIds.isNotEmpty),
      );

      bool success = await teacherProvider.updateTeacher(updatedTeacher);

      if (success) {
        await dashboardProvider.refreshDashboard();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Interested courses updated successfully'),
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
        title: const Text('Interested Courses'),
        backgroundColor: const Color(0xFF1976D2),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _isLoading ? null : _saveInterestedCourses,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          // Info Card
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Row(
              children: [
                const Icon(Icons.info, color: Colors.orange),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Interested Courses',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Select courses you are interested in teaching',
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

          // Selected Count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${_selectedCourseIds.length} courses selected',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (_selectedCourseIds.isNotEmpty)
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _selectedCourseIds.clear();
                      });
                    },
                    child: const Text('Clear All'),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Course List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _availableCourses.length,
              itemBuilder: (context, index) {
                final course = _availableCourses[index];
                final isSelected = _selectedCourseIds.contains(course.id);

                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: isSelected ? Colors.green.shade200 : Colors.grey.shade300,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: CheckboxListTile(
                    title: Text(
                      course.code,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(course.title),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: course.type == 'Theory'
                                    ? Colors.blue[100]
                                    : Colors.orange[100],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                course.type,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: course.type == 'Theory'
                                      ? Colors.blue[700]
                                      : Colors.orange[700],
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Credit: ${course.credit}',
                              style: const TextStyle(fontSize: 10),
                            ),
                          ],
                        ),
                      ],
                    ),
                    value: isSelected,
                    activeColor: Colors.green,
                    onChanged: (selected) {
                      setState(() {
                        if (selected!) {
                          _selectedCourseIds.add(course.id!);
                        } else {
                          _selectedCourseIds.remove(course.id);
                        }
                      });
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}