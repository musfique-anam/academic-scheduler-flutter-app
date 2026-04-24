import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/routine_provider.dart';
import '../../../providers/teacher_provider.dart';
import '../../../providers/course_provider.dart';
import '../../../data/models/teacher_model.dart';
import '../../../data/models/routine_model.dart';
import 'teacher_profile_screen.dart';
import 'teacher_availability_screen.dart';
import 'teacher_interested_courses_screen.dart';

class TeacherDashboard extends StatefulWidget {
  const TeacherDashboard({super.key});

  @override
  State<TeacherDashboard> createState() => _TeacherDashboardState();
}

class _TeacherDashboardState extends State<TeacherDashboard> {
  int _selectedIndex = 0;
  Teacher? _teacher;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeDashboard();
    });
  }

  Future<void> _initializeDashboard() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    if (!authProvider.isTeacher) {
      setState(() {
        _errorMessage = 'Unauthorized Access';
        _isLoading = false;
      });
      return;
    }

    await _loadTeacherData();
  }

  Future<void> _loadTeacherData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final teacherProvider = Provider.of<TeacherProvider>(context, listen: false);

      await teacherProvider.loadTeachers();

      if (authProvider.currentUser != null) {
        int teacherId = authProvider.currentUser!['id'];
        print('🔍 Loading teacher with ID: $teacherId');

        _teacher = teacherProvider.getTeacherById(teacherId);

        if (_teacher == null) {
          setState(() {
            _errorMessage = 'Teacher data not found';
          });
        } else {
          print('✅ Teacher loaded: ${_teacher!.name}');
        }
      }
    } catch (e) {
      print('❌ Error: $e');
      setState(() {
        _errorMessage = 'Error loading teacher data';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Teacher Dashboard'),
          backgroundColor: const Color(0xFF1976D2),
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, color: Colors.red, size: 64),
              const SizedBox(height: 16),
              Text('Error: $_errorMessage'),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  authProvider.logout();
                  Navigator.pushReplacementNamed(context, '/login');
                },
                child: const Text('Back to Login'),
              ),
            ],
          ),
        ),
      );
    }

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Teacher Dashboard'),
          backgroundColor: const Color(0xFF1976D2),
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading teacher data...'),
            ],
          ),
        ),
      );
    }

    if (_teacher == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Teacher Dashboard'),
          backgroundColor: const Color(0xFF1976D2),
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.orange),
              const SizedBox(height: 16),
              const Text(
                'Teacher data not found',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Please contact administrator',
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  authProvider.logout();
                  Navigator.pushReplacementNamed(context, '/login');
                },
                child: const Text('Logout'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Teacher Dashboard'),
        backgroundColor: const Color(0xFF1976D2),
        foregroundColor: Colors.white,
        elevation: 4,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => _showNotifications(context),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.account_circle),
            onSelected: (value) {
              if (value == 'profile') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TeacherProfileScreen(teacher: _teacher!),
                  ),
                ).then((_) => _loadTeacherData());
              } else if (value == 'logout') {
                _showLogoutDialog(context, authProvider);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'profile',
                child: Row(
                  children: [
                    Icon(Icons.person, size: 18),
                    SizedBox(width: 8),
                    Text('My Profile'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, size: 18, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Logout', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _DashboardTab(teacher: _teacher!, onViewRoutine: () {
            setState(() {
              _selectedIndex = 1;
            });
          }),
          _RoutineTab(teacher: _teacher!),
          TeacherAvailabilityScreen(teacher: _teacher!),
          TeacherInterestedCoursesScreen(teacher: _teacher!),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'My Routine',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.access_time),
            label: 'Availability',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.book),
            label: 'Courses',
          ),
        ],
      ),
    );
  }

  void _showNotifications(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Text('No new notifications'),
            ],
          ),
        );
      },
    );
  }

  void _showLogoutDialog(BuildContext context, AuthProvider authProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              authProvider.logout();
              Navigator.pushReplacementNamed(context, '/login');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}

// Dashboard Tab Widget
class _DashboardTab extends StatelessWidget {
  final Teacher teacher;
  final VoidCallback onViewRoutine;

  const _DashboardTab({
    required this.teacher,
    required this.onViewRoutine,
  });

  @override
  Widget build(BuildContext context) {
    final routineProvider = Provider.of<RoutineProvider>(context);
    var teacherRoutines = routineProvider.getRoutinesByTeacher(teacher.id!);
    int totalClasses = teacherRoutines.length;
    int todayClasses = teacherRoutines.where((r) => r.day == _getTodayDay()).length;
    int totalCredits = teacherRoutines.length;
    double workloadPercentage = teacher.maxLoad > 0
        ? (totalCredits / teacher.maxLoad) * 100
        : 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome Card
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1976D2), Color(0xFF64B5F6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome, ${teacher.name}!',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    teacher.isProfileCompleted
                        ? 'Your profile is complete'
                        : 'Please complete your profile',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _buildInfoChip(
                        Icons.class_,
                        '$todayClasses classes today',
                      ),
                      const SizedBox(width: 8),
                      _buildInfoChip(
                        Icons.speed,
                        '${workloadPercentage.toStringAsFixed(1)}% load',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Statistics Cards
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.5,
            children: [
              _buildStatCard(
                'Total Classes',
                '$totalClasses',
                Icons.class_,
                Colors.blue,
              ),
              _buildStatCard(
                'This Week',
                '$totalClasses',
                Icons.calendar_view_week,
                Colors.green,
              ),
              _buildStatCard(
                'Max Load',
                '${teacher.maxLoad} cr',
                Icons.speed,
                Colors.orange,
              ),
              _buildStatCard(
                'Used',
                '$totalCredits cr',
                Icons.check_circle,
                Colors.purple,
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Quick Actions
          const Text(
            'Quick Actions',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildActionCard(
                  'View Routine',
                  Icons.calendar_today,
                  Colors.blue,
                  onViewRoutine,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildActionCard(
                  'Update Availability',
                  Icons.access_time,
                  Colors.green,
                      () {
                    // Will be handled by parent
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildActionCard(
                  'Interested Courses',
                  Icons.book,
                  Colors.orange,
                      () {
                    // Will be handled by parent
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Today's Schedule
          const Text(
            'Today\'s Schedule',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),

          teacherRoutines.where((r) => r.day == _getTodayDay()).isEmpty
              ? Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Text(
                'No classes scheduled for today',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          )
              : ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: teacherRoutines.where((r) => r.day == _getTodayDay()).length,
            itemBuilder: (context, index) {
              final routine = teacherRoutines.where((r) => r.day == _getTodayDay()).toList()[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: _getTimeColor(routine.slot),
                    child: Text(
                      '${routine.slot}',
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                  title: Text('${routine.courseCode} - ${routine.courseTitle}'),
                  subtitle: Text(
                    '${routine.startTime} - ${routine.endTime} | Room: ${routine.roomNo ?? 'TBA'}',
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 20),

          if (!teacher.isProfileCompleted)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning, color: Colors.orange),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Profile Incomplete',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Please update your availability and interested courses',
                          style: TextStyle(color: Colors.orange[700]),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 16),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard(String label, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                color: color,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  String _getTodayDay() {
    DateTime now = DateTime.now();
    switch(now.weekday) {
      case 5: return 'Friday';
      case 6: return 'Saturday';
      case 7: return 'Sunday';
      case 1: return 'Monday';
      case 2: return 'Tuesday';
      default: return '';
    }
  }

  Color _getTimeColor(int slot) {
    switch(slot) {
      case 1: return Colors.blue;
      case 2: return Colors.green;
      case 3: return Colors.orange;
      case 4: return Colors.purple;
      default: return Colors.grey;
    }
  }
}

// Routine Tab Widget
class _RoutineTab extends StatelessWidget {
  final Teacher teacher;

  const _RoutineTab({required this.teacher});

  @override
  Widget build(BuildContext context) {
    final routineProvider = Provider.of<RoutineProvider>(context);
    var teacherRoutines = routineProvider.getRoutinesByTeacher(teacher.id!);

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.grey[100],
          child: Row(
            children: [
              const Text('My Routine', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.picture_as_pdf),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('PDF download - Coming Soon'),
                      backgroundColor: Colors.blue,
                    ),
                  );
                },
              ),
            ],
          ),
        ),

        Expanded(
          child: teacherRoutines.isEmpty
              ? const Center(
            child: Text('No classes assigned yet'),
          )
              : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: teacherRoutines.length,
            itemBuilder: (context, index) {
              final routine = teacherRoutines[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: _getDayColor(routine.day),
                    child: Text(
                      routine.day[0],
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                  title: Text('${routine.courseCode} - ${routine.courseTitle}'),
                  subtitle: Text(
                    '${routine.day} | Slot ${routine.slot} (${routine.startTime}-${routine.endTime})\n'
                        'Batch: ${routine.batchId} | Room: ${routine.roomNo ?? 'TBA'}',
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Color _getDayColor(String day) {
    switch(day) {
      case 'Friday': return Colors.purple;
      case 'Saturday': return Colors.blue;
      case 'Sunday': return Colors.green;
      case 'Monday': return Colors.orange;
      case 'Tuesday': return Colors.red;
      default: return Colors.grey;
    }
  }
}