import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/teacher_provider.dart';
import '../../../providers/department_provider.dart';
import '../../../providers/dashboard_provider.dart';
import '../../../data/models/teacher_model.dart';
import '../../../data/models/department_model.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/error_widget.dart';
import 'teacher_add_edit_screen.dart';
import 'teacher_profile_screen.dart';
import 'teacher_routine_screen.dart';

class TeacherScreen extends StatefulWidget {
  const TeacherScreen({super.key});

  @override
  State<TeacherScreen> createState() => _TeacherScreenState();
}

class _TeacherScreenState extends State<TeacherScreen> {
  final TextEditingController _searchController = TextEditingController();
  int? _selectedDepartmentId;
  String _selectedFilter = 'All';

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });

    _searchController.addListener(() {
      final provider = Provider.of<TeacherProvider>(context, listen: false);
      provider.searchTeachers(_searchController.text);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final teacherProvider = Provider.of<TeacherProvider>(context, listen: false);
    final deptProvider = Provider.of<DepartmentProvider>(context, listen: false);

    await Future.wait([
      teacherProvider.loadTeachers(),
      deptProvider.loadDepartments(),
      teacherProvider.loadDepartments(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Teacher Management'),
        backgroundColor: const Color(0xFF1976D2),
        foregroundColor: Colors.white,
        elevation: 4,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(110),
          child: Column(
            children: [
              // Search Bar
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search teachers...',
                    hintStyle: const TextStyle(color: Colors.white70),
                    prefixIcon: const Icon(Icons.search, color: Colors.white),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                      icon: const Icon(Icons.clear, color: Colors.white),
                      onPressed: () {
                        _searchController.clear();
                        final provider = Provider.of<TeacherProvider>(context, listen: false);
                        provider.clearFilter();
                      },
                    )
                        : null,
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.2),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  style: const TextStyle(color: Colors.white),
                ),
              ),

              // Filter Row
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                child: Consumer<DepartmentProvider>(
                  builder: (context, deptProvider, child) {
                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          FilterChip(
                            label: const Text('All'),
                            selected: _selectedFilter == 'All',
                            onSelected: (selected) {
                              setState(() {
                                _selectedFilter = 'All';
                                _selectedDepartmentId = null;
                              });
                              final provider = Provider.of<TeacherProvider>(context, listen: false);
                              provider.clearFilter();
                            },
                            backgroundColor: Colors.white,
                            selectedColor: const Color(0xFF1976D2),
                            labelStyle: TextStyle(
                              color: _selectedFilter == 'All' ? Colors.white : Colors.black,
                            ),
                          ),
                          const SizedBox(width: 8),
                          ...deptProvider.departments.map((dept) {
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: FilterChip(
                                label: Text(dept.code),
                                selected: _selectedDepartmentId == dept.id,
                                onSelected: (selected) {
                                  setState(() {
                                    _selectedFilter = dept.code;
                                    _selectedDepartmentId = dept.id;
                                  });
                                  final provider = Provider.of<TeacherProvider>(context, listen: false);
                                  provider.filterByDepartment(dept.id);
                                },
                                backgroundColor: Colors.white,
                                selectedColor: const Color(0xFF1976D2),
                                labelStyle: TextStyle(
                                  color: _selectedDepartmentId == dept.id ? Colors.white : Colors.black,
                                ),
                              ),
                            );
                          }).toList(),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const TeacherAddEditScreen()),
          ).then((_) => _loadData());
        },
        backgroundColor: const Color(0xFF1976D2),
        foregroundColor: Colors.white,
        child: const Icon(Icons.person_add),
      ),
      body: Consumer<TeacherProvider>(
        builder: (context, teacherProvider, child) {
          if (teacherProvider.isLoading && teacherProvider.teachers.isEmpty) {
            return const LoadingWidget(message: 'Loading teachers...');
          }

          if (teacherProvider.error != null && teacherProvider.teachers.isEmpty) {
            return ErrorWidgetWithRetry(
              error: teacherProvider.error!,
              onRetry: _loadData,
            );
          }

          if (teacherProvider.teachers.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.person_outline,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No teachers found',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Click + button to add new teacher',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              // Summary Card
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.people,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Total Teachers',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                          Text(
                            '${teacherProvider.totalTeachers}',
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (teacherProvider.isSearching)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange[100],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${teacherProvider.teachers.length} results',
                          style: TextStyle(
                            color: Colors.orange[800],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // Teacher List
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: teacherProvider.teachers.length,
                  itemBuilder: (context, index) {
                    final teacher = teacherProvider.teachers[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ExpansionTile(
                        leading: CircleAvatar(
                          radius: 25,
                          backgroundColor: teacher.isProfileCompleted
                              ? Colors.green
                              : Colors.orange,
                          child: Text(
                            teacher.shortName.substring(0, 1).toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                teacher.name,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: teacher.isProfileCompleted
                                    ? Colors.green.withOpacity(0.1)
                                    : Colors.orange.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                teacher.isProfileCompleted
                                    ? 'Profile Complete'
                                    : 'Pending',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: teacher.isProfileCompleted
                                      ? Colors.green[700]
                                      : Colors.orange[700],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Username: ${teacher.username}'),
                            Text('Short Name: ${teacher.shortName}'),
                          ],
                        ),
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                // Academic Info (if profile completed)
                                if (teacher.isProfileCompleted) ...[
                                  _buildInfoRow(
                                    Icons.calendar_today,
                                    'Available Days',
                                    teacher.availableDays.join(', '),
                                  ),
                                  const Divider(),
                                  _buildInfoRow(
                                    Icons.access_time,
                                    'Available Slots',
                                    teacher.availableSlots.map((s) => 'Slot $s').join(', '),
                                  ),
                                  const Divider(),
                                  _buildInfoRow(
                                    Icons.speed,
                                    'Max Load',
                                    '${teacher.maxLoad} credits/week',
                                  ),
                                  const Divider(),
                                ],

                                // Action Buttons - IMPROVED UI
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  alignment: WrapAlignment.center,
                                  children: [
                                    _buildActionChip(
                                      'Edit',
                                      Icons.edit,
                                      Colors.blue,
                                          () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => TeacherAddEditScreen(teacher: teacher),
                                          ),
                                        ).then((_) => _loadData());
                                      },
                                    ),
                                    _buildActionChip(
                                      'Profile',
                                      Icons.person,
                                      Colors.green,
                                          () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => TeacherProfileScreen(teacher: teacher),
                                          ),
                                        );
                                      },
                                    ),
                                    _buildActionChip(
                                      'Routine',
                                      Icons.schedule,
                                      Colors.purple,
                                          () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => TeacherRoutineScreen(teacher: teacher),
                                          ),
                                        );
                                      },
                                    ),
                                    _buildActionChip(
                                      'Reset',
                                      Icons.lock_reset,
                                      Colors.orange,
                                          () => _showResetPasswordDialog(context, teacher),
                                    ),
                                    _buildActionChip(
                                      'Delete',
                                      Icons.delete,
                                      Colors.red,
                                          () => _showDeleteDialog(context, teacher),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // IMPROVED: Action Chip instead of Circle buttons
  Widget _buildActionChip(String label, IconData icon, Color color, VoidCallback onTap) {
    return ActionChip(
      avatar: Icon(icon, color: color, size: 16),
      label: Text(label, style: TextStyle(fontSize: 11, color: color)),
      onPressed: onTap,
      backgroundColor: color.withOpacity(0.1),
      side: BorderSide(color: color.withOpacity(0.3)),
    );
  }

  Widget _buildActionButton(String label, IconData icon, Color color, VoidCallback onTap) {
    return Tooltip(
      message: label,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 20),
        ),
      ),
    );
  }

  void _showResetPasswordDialog(BuildContext context, Teacher teacher) {
    final passwordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Reset password for ${teacher.name}'),
            const SizedBox(height: 16),
            TextField(
              controller: passwordController,
              decoration: const InputDecoration(
                labelText: 'New Password',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock),
              ),
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (passwordController.text.isNotEmpty) {
                final provider = Provider.of<TeacherProvider>(context, listen: false);
                bool success = await provider.resetPassword(
                  teacher.id!,
                  passwordController.text,
                );

                if (success && mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Password reset successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, Teacher teacher) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Teacher'),
        content: Text(
          'Are you sure you want to delete ${teacher.name} (${teacher.shortName})?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);

              final teacherProvider = Provider.of<TeacherProvider>(context, listen: false);
              final dashboardProvider = Provider.of<DashboardProvider>(context, listen: false);

              bool success = await teacherProvider.deleteTeacher(teacher.id!);

              if (success && mounted) {
                await dashboardProvider.refreshDashboard();

                dashboardProvider.addRecentActivity(
                  'Teacher ${teacher.shortName} deleted',
                  Icons.person_remove,
                  Colors.red,
                );

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Teacher deleted successfully'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}