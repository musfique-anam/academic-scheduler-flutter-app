import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/dashboard_provider.dart';
import '../../../providers/department_provider.dart';
import '../../../providers/teacher_provider.dart';
import '../../../providers/batch_provider.dart';
import '../../../providers/course_provider.dart';
import '../../../providers/room_provider.dart';
import '../../../providers/merge_provider.dart';
import '../../../providers/routine_provider.dart';
import 'department_screen.dart';
import 'room_screen.dart';
import 'teacher_screen.dart';
import 'batch_screen.dart';
import 'course_screen.dart';
import 'routine_generation_screen.dart';
import 'view_routine_screen.dart';
import 'merge_section_screen.dart';
import 'room_assignment_screen.dart';
import 'profile_screen.dart';
import 'settings_screen.dart';
import 'data_insertion_screen.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final dashboardProvider = Provider.of<DashboardProvider>(context);
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: const Text(
          'Admin Dashboard',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        backgroundColor: const Color(0xFF1976D2),
        foregroundColor: Colors.white,
        elevation: 4,
        leading: IconButton(
          icon: const Icon(Icons.menu, size: 24),
          onPressed: () {
            _scaffoldKey.currentState?.openDrawer();
          },
        ),
        actions: [
          // Notification Icon with Badge
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined, size: 24),
                onPressed: () {
                  _showNotificationPanel(context);
                },
              ),
              if (dashboardProvider.hasUnreadNotifications)
                Positioned(
                  right: 8,
                  top: 6,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    child: Center(
                      child: Text(
                        '${dashboardProvider.unreadCount}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 4),
        ],
      ),

      // Sidebar Drawer
      drawer: Drawer(
        width: screenSize.width * 0.7,
        child: Container(
          color: const Color(0xFF1976D2),
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              // Drawer Header
              DrawerHeader(
                decoration: const BoxDecoration(
                  color: Color(0xFF1565C0),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircleAvatar(
                      radius: 35,
                      backgroundColor: Colors.white,
                      child: Icon(
                        Icons.admin_panel_settings,
                        size: 40,
                        color: Color(0xFF1976D2),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      authProvider.currentUser?['name'] ?? 'Admin User',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      authProvider.currentUser?['email'] ?? 'admin@university.edu',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              // Drawer Menu Items
              _buildDrawerItem(Icons.dashboard, 'Dashboard', 0),
              _buildDrawerItem(Icons.business, 'Departments', 1),
              _buildDrawerItem(Icons.person, 'Teachers', 2),
              _buildDrawerItem(Icons.group, 'Batches', 3),
              _buildDrawerItem(Icons.book, 'Courses', 4),
              _buildDrawerItem(Icons.meeting_room, 'Rooms', 5),
              _buildDrawerItem(Icons.merge_type, 'Merge Sections', 6),
              _buildDrawerItem(Icons.assignment, 'Room Assignment', 7),
              _buildDrawerItem(Icons.schedule, 'Generate Routine', 8),
              _buildDrawerItem(Icons.remove_red_eye, 'View Routine', 9),
              _buildDrawerItem(Icons.storage, 'Insert Data', 10),
              const Divider(color: Colors.white30, thickness: 1, height: 20),
              _buildDrawerItem(Icons.person_outline, 'Profile', 11),
              _buildDrawerItem(Icons.settings, 'Settings', 12),
              _buildDrawerItem(Icons.logout, 'Logout', 13, isLogout: true),
            ],
          ),
        ),
      ),

      body: _selectedIndex == 0
          ? _buildDashboardContent(context, dashboardProvider)
          : _buildSelectedScreen(),
    );
  }

  Widget _buildDrawerItem(IconData icon, String title, int index, {bool isLogout = false}) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final isSelected = _selectedIndex == index;

    return Container(
      decoration: BoxDecoration(
        color: isSelected ? Colors.white24 : null,
        borderRadius: BorderRadius.circular(8),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: ListTile(
        leading: Icon(icon, color: Colors.white, size: 22),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        dense: true,
        onTap: () {
          if (isLogout) {
            _showLogoutDialog(context, authProvider);
          } else {
            setState(() {
              _selectedIndex = index;
            });
            Navigator.pop(context);
          }
        },
      ),
    );
  }

  Widget _buildDashboardContent(BuildContext context, DashboardProvider provider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome Banner
          _buildWelcomeBanner(context, provider),
          const SizedBox(height: 16),

          // Statistics Cards
          _buildStatisticsCards(provider),
          const SizedBox(height: 20),

          // Quick Actions Section
          _buildQuickActions(),
          const SizedBox(height: 20),

          // Recent Activities
          _buildRecentActivities(provider),
          const SizedBox(height: 20),

          // Charts Section
          _buildChartsSection(),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildWelcomeBanner(BuildContext context, DashboardProvider provider) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1976D2), Color(0xFF64B5F6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Welcome back, Admin!',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Here\'s what\'s happening today',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildInfoChip(Icons.today, '${provider.todayClasses} classes'),
              _buildInfoChip(Icons.pending, '${provider.pendingTasks} pending'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 14),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsCards(DashboardProvider provider) {
    final screenWidth = MediaQuery.of(context).size.width;
    int crossAxisCount = screenWidth > 900 ? 4 : (screenWidth > 600 ? 3 : 2);

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: crossAxisCount,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.0,
      children: [
        _buildStatCard(
          'Departments',
          '${provider.totalDepartments}',
          Icons.business,
          Colors.blue,
          onClick: () => setState(() => _selectedIndex = 1),
        ),
        _buildStatCard(
          'Teachers',
          '${provider.totalTeachers}',
          Icons.person,
          Colors.green,
          onClick: () => setState(() => _selectedIndex = 2),
        ),
        _buildStatCard(
          'Batches',
          '${provider.totalBatches}',
          Icons.group,
          Colors.orange,
          onClick: () => setState(() => _selectedIndex = 3),
        ),
        _buildStatCard(
          'Students',
          '${provider.totalStudents}',
          Icons.people,
          Colors.purple,
          onClick: () => _showComingSoon(context),
        ),
        _buildStatCard(
          'Courses',
          '${provider.totalCourses}',
          Icons.book,
          Colors.red,
          onClick: () => setState(() => _selectedIndex = 4),
        ),
        _buildStatCard(
          'Rooms',
          '${provider.totalRooms}',
          Icons.meeting_room,
          Colors.teal,
          onClick: () => setState(() => _selectedIndex = 5),
        ),
        _buildStatCard(
          'Active Classes',
          '${provider.activeClasses}',
          Icons.class_,
          Colors.indigo,
          onClick: () => _showComingSoon(context),
        ),
        _buildStatCard(
          'Today\'s Routines',
          '${provider.todayRoutines}',
          Icons.schedule,
          Colors.pink,
          onClick: () => setState(() => _selectedIndex = 9),
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color, {required VoidCallback onClick}) {
    return GestureDetector(
      onTap: onClick,
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4),
          child: Text(
            'Quick Actions',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 100,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _buildQuickActionButton(
                'Generate\nRoutine',
                Icons.schedule,
                Colors.blue,
                    () => _navigateToScreen(const RoutineGenerationScreen()),
              ),
              _buildQuickActionButton(
                'Merge\nSections',
                Icons.merge_type,
                Colors.green,
                    () => _navigateToScreen(const MergeSectionScreen()),
              ),
              _buildQuickActionButton(
                'Assign\nRooms',
                Icons.assignment,
                Colors.orange,
                    () => _navigateToScreen(const RoomAssignmentScreen()),
              ),
              _buildQuickActionButton(
                'View\nRoutine',
                Icons.remove_red_eye,
                Colors.purple,
                    () => _navigateToScreen(const ViewRoutineScreen()),
              ),
              _buildQuickActionButton(
                'Add Teacher',
                Icons.person_add,
                Colors.red,
                    () => _navigateToScreen(const TeacherScreen()),
              ),
              _buildQuickActionButton(
                'Add Batch',
                Icons.group_add,
                Colors.teal,
                    () => _navigateToScreen(const BatchScreen()),
              ),
              _buildQuickActionButton(
                'Insert Data',
                Icons.storage,
                Colors.amber,
                    () => _navigateToScreen(const DataInsertionScreen()),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActionButton(String label, IconData icon, Color color, VoidCallback onTap) {
    return Container(
      width: 90,
      margin: const EdgeInsets.only(right: 8),
      child: Card(
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
                const SizedBox(height: 6),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: color,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRecentActivities(DashboardProvider provider) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Recent Activities',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: provider.recentActivities.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final activity = provider.recentActivities[index];
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  leading: CircleAvatar(
                    radius: 18,
                    backgroundColor: activity['color'].withOpacity(0.1),
                    child: Icon(
                      activity['icon'],
                      color: activity['color'],
                      size: 16,
                    ),
                  ),
                  title: Text(
                    activity['title'],
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                  subtitle: Text(
                    activity['time'],
                    style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: activity['status'] == 'Completed'
                          ? Colors.green.withOpacity(0.1)
                          : Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      activity['status'],
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w500,
                        color: activity['status'] == 'Completed'
                            ? Colors.green[700]
                            : Colors.orange[700],
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartsSection() {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Weekly Overview',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 100,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildBarChart('Mon', 80, Colors.blue),
                  _buildBarChart('Tue', 65, Colors.blue),
                  _buildBarChart('Wed', 90, Colors.blue),
                  _buildBarChart('Thu', 70, Colors.blue),
                  _buildBarChart('Fri', 50, Colors.blue),
                  _buildBarChart('Sat', 30, Colors.blue),
                  _buildBarChart('Sun', 20, Colors.blue),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBarChart(String day, double percentage, Color color) {
    return Column(
      children: [
        Container(
          width: 18,
          height: 60,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(6),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                width: 18,
                height: percentage * 0.5,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color, color.withOpacity(0.7)],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  ),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          day,
          style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildSelectedScreen() {
    switch (_selectedIndex) {
      case 1:
        return const DepartmentScreen();
      case 2:
        return const TeacherScreen();
      case 3:
        return const BatchScreen();
      case 4:
        return const CourseScreen();
      case 5:
        return const RoomScreen();
      case 6:
        return const MergeSectionScreen();
      case 7:
        return const RoomAssignmentScreen();
      case 8:
        return const RoutineGenerationScreen();
      case 9:
        return const ViewRoutineScreen();
      case 10:
        return const DataInsertionScreen();
      case 11:
        return const ProfileScreen();
      case 12:
        return const SettingsScreen();
      default:
        return _buildDashboardContent(context, Provider.of<DashboardProvider>(context));
    }
  }

  void _navigateToScreen(Widget screen) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => screen),
    );
  }

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Coming Soon!'),
        backgroundColor: Colors.orange,
        duration: Duration(seconds: 1),
      ),
    );
  }

  void _showNotificationPanel(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          height: MediaQuery.of(context).size.height * 0.5,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Notifications',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.separated(
                  itemCount: 5,
                  separatorBuilder: (context, index) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    return ListTile(
                      dense: true,
                      leading: CircleAvatar(
                        radius: 16,
                        backgroundColor: const Color(0xFF1976D2).withOpacity(0.1),
                        child: const Icon(Icons.notifications, color: Color(0xFF1976D2), size: 14),
                      ),
                      title: Text('Notification ${index + 1}', style: const TextStyle(fontSize: 13)),
                      subtitle: const Text('New update in the system', style: TextStyle(fontSize: 11)),
                      trailing: Text('${index + 1}h ago', style: const TextStyle(fontSize: 10)),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showLogoutDialog(BuildContext context, AuthProvider authProvider) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Logout', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          content: const Text('Are you sure you want to logout?', style: TextStyle(fontSize: 14)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              child: const Text('Cancel', style: TextStyle(fontSize: 14)),
            ),
            ElevatedButton(
              onPressed: () {
                authProvider.logout();
                Navigator.pushReplacementNamed(context, '/');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Logout', style: TextStyle(fontSize: 14)),
            ),
          ],
        );
      },
    );
  }
}