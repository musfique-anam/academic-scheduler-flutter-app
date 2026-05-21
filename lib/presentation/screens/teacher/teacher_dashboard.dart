// lib/presentation/screens/teacher/teacher_dashboard.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../../providers/auth_provider.dart';
import '../../../providers/routine_provider.dart';
import '../../../providers/teacher_provider.dart';
import '../../../data/models/teacher_model.dart';
import '../../../data/models/routine_model.dart';
import 'teacher_profile_screen.dart';

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
    await _loadRoutines();
  }

  Future<void> _loadRoutines() async {
    try {
      final routineProvider =
          Provider.of<RoutineProvider>(context, listen: false);
      await routineProvider.loadRoutinesFromDatabase();
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('❌ Error loading routines: $e');
    }
  }

  Future<void> _loadTeacherData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authProvider =
          Provider.of<AuthProvider>(context, listen: false);
      final teacherProvider =
          Provider.of<TeacherProvider>(context, listen: false);

      await teacherProvider.loadTeachers();

      if (authProvider.currentUser != null) {
        int teacherId = authProvider.currentUser!['id'];
        _teacher = teacherProvider.getTeacherById(teacherId);
        if (_teacher == null) {
          setState(() => _errorMessage = 'Teacher data not found');
        }
      }
    } catch (e) {
      setState(() => _errorMessage = 'Error loading teacher data');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _refreshData() async {
    await _loadTeacherData();
    await _loadRoutines();
    if (mounted) setState(() {});
  }

  Future<bool> _confirmExit() async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Logout?'),
            content:
                const Text('Going back will log you out. Continue?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white),
                child: const Text('Logout'),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _downloadPDF(List<Routine> routines) async {
    if (routines.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('No routines to download'),
            backgroundColor: Colors.orange),
      );
      return;
    }

    try {
      final pdf = pw.Document();

      Map<String, List<Routine>> byDay = {};
      for (var r in routines) {
        byDay.putIfAbsent(r.day, () => []).add(r);
      }
      List<String> dayOrder = [
        'Friday', 'Saturday', 'Sunday', 'Monday', 'Tuesday'
      ];

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(20),
          build: (pw.Context context) {
            return [
              pw.Center(
                child: pw.Column(children: [
                  pw.Text('Pundra University of Science & Technology',
                      style: pw.TextStyle(
                          fontSize: 18, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 5),
                  pw.Text('Teacher Class Routine',
                      style: pw.TextStyle(
                          fontSize: 14, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 8),
                  pw.Text('Teacher: ${_teacher?.name ?? "N/A"}',
                      style: const pw.TextStyle(fontSize: 12)),
                  pw.SizedBox(height: 20),
                ]),
              ),
              for (var day in dayOrder)
                if (byDay.containsKey(day))
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Container(
                        padding: const pw.EdgeInsets.all(8),
                        color: PdfColors.blue100,
                        child: pw.Text(day.toUpperCase(),
                            style: pw.TextStyle(
                                fontSize: 12,
                                fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.SizedBox(height: 5),
                      _buildRoutinePdfTable(byDay[day]!),
                      pw.SizedBox(height: 15),
                    ],
                  ),
              pw.SizedBox(height: 20),
              pw.Center(
                  child: pw.Text(
                      'Generated by Smart Academic Scheduler',
                      style: const pw.TextStyle(
                          fontSize: 8, color: PdfColors.grey500))),
            ];
          },
        ),
      );

      await Printing.sharePdf(
        bytes: await pdf.save(),
        filename:
            'teacher_routine_${DateTime.now().millisecondsSinceEpoch}.pdf',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('PDF downloaded successfully'),
              backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error generating PDF: $e'),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  pw.Widget _buildRoutinePdfTable(List<Routine> routines) {
    routines.sort((a, b) => a.slot.compareTo(b.slot));

    final headers = ['Slot', 'Time', 'Code', 'Title', 'Batch', 'Room'];
    final data = routines
        .map((r) => [
              '${r.slot}',
              '${r.startTime ?? "-"}-${r.endTime ?? "-"}',
              r.courseCode,
              r.courseTitle.length > 25
                  ? '${r.courseTitle.substring(0, 22)}...'
                  : r.courseTitle,
              'Batch ${r.batchId}',
              r.roomNo ?? 'TBA',
            ])
        .toList();

    return pw.TableHelper.fromTextArray(
      headers: headers,
      data: data,
      border: pw.TableBorder.all(),
      headerStyle:
          pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
      cellStyle: const pw.TextStyle(fontSize: 8),
      cellAlignment: pw.Alignment.centerLeft,
      headerAlignment: pw.Alignment.centerLeft,
    );
  }

  void _showLogoutDialog(AuthProvider authProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              authProvider.logout();
              Navigator.of(context)
                  .pushNamedAndRemoveUntil('/login', (route) => false);
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
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
                  Navigator.of(context)
                      .pushNamedAndRemoveUntil('/login', (route) => false);
                },
                child: const Text('Back to Login'),
              ),
            ],
          ),
        ),
      );
    }

    if (_isLoading || _teacher == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Teacher Dashboard'),
          backgroundColor: const Color(0xFF1976D2),
          foregroundColor: Colors.white,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldExit = await _confirmExit();
        if (shouldExit && mounted) {
          authProvider.logout();
          Navigator.of(context)
              .pushNamedAndRemoveUntil('/login', (route) => false);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
              _selectedIndex == 0 ? 'Teacher Dashboard' : 'My Routine'),
          backgroundColor: const Color(0xFF1976D2),
          foregroundColor: Colors.white,
          elevation: 4,
          automaticallyImplyLeading: false, // 🔥 hide default back arrow
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Refresh',
              onPressed: _refreshData,
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.account_circle),
              onSelected: (value) {
                if (value == 'profile') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) =>
                            TeacherProfileScreen(teacher: _teacher!)),
                  ).then((_) => _refreshData());
                } else if (value == 'logout') {
                  _showLogoutDialog(authProvider);
                }
              },
              itemBuilder: (context) => const [
                PopupMenuItem(
                  value: 'profile',
                  child: Row(children: [
                    Icon(Icons.person, size: 18),
                    SizedBox(width: 8),
                    Text('My Profile'),
                  ]),
                ),
                PopupMenuItem(
                  value: 'logout',
                  child: Row(children: [
                    Icon(Icons.logout, size: 18, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Logout', style: TextStyle(color: Colors.red)),
                  ]),
                ),
              ],
            ),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: _refreshData,
          child: IndexedStack(
            index: _selectedIndex,
            children: [
              DashboardTab(
                teacher: _teacher!,
                onViewRoutine: () => setState(() => _selectedIndex = 1),
              ),
              RoutineTab(teacher: _teacher!, onDownloadPDF: _downloadPDF),
            ],
          ),
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) {
            setState(() => _selectedIndex = index);
            if (index == 1) _loadRoutines();
          },
          type: BottomNavigationBarType.fixed,
          selectedItemColor: const Color(0xFF1976D2),
          items: const [
            BottomNavigationBarItem(
                icon: Icon(Icons.dashboard), label: 'Dashboard'),
            BottomNavigationBarItem(
                icon: Icon(Icons.calendar_today), label: 'View Routine'),
          ],
        ),
      ),
    );
  }
}

// ========== DASHBOARD TAB ==========
class DashboardTab extends StatelessWidget {
  final Teacher teacher;
  final VoidCallback onViewRoutine;

  const DashboardTab({
    super.key,
    required this.teacher,
    required this.onViewRoutine,
  });

  String _getTodayDay() {
    DateTime now = DateTime.now();
    switch (now.weekday) {
      case 5: return 'Friday';
      case 6: return 'Saturday';
      case 7: return 'Sunday';
      case 1: return 'Monday';
      case 2: return 'Tuesday';
      default: return '';
    }
  }

  Color _getTimeColor(int slot) {
    switch (slot) {
      case 1: return Colors.blue;
      case 2: return Colors.green;
      case 3: return Colors.orange;
      case 4: return Colors.purple;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final routineProvider = Provider.of<RoutineProvider>(context);
    final teacherRoutines =
        routineProvider.getRoutinesByTeacher(teacher.id!);
    final int totalClasses = teacherRoutines.length;
    final int todayClasses =
        teacherRoutines.where((r) => r.day == _getTodayDay()).length;
    final int totalCredits = teacherRoutines.length;
    final double workloadPercentage = teacher.maxLoad > 0
        ? (totalCredits / teacher.maxLoad) * 100
        : 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
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
                  Text('Welcome, ${teacher.name}!',
                      style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
                  const SizedBox(height: 4),
                  Text('Short Name: ${teacher.shortName}',
                      style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withOpacity(0.9))),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _buildInfoChip(
                          Icons.class_, '$todayClasses today'),
                      const SizedBox(width: 8),
                      _buildInfoChip(Icons.speed,
                          '${workloadPercentage.toStringAsFixed(1)}% load'),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.5,
            children: [
              _buildStatCard('Total Classes', '$totalClasses',
                  Icons.class_, Colors.blue),
              _buildStatCard('Today', '$todayClasses',
                  Icons.calendar_today, Colors.green),
              _buildStatCard('Max Load', '${teacher.maxLoad}',
                  Icons.speed, Colors.orange),
              _buildStatCard('Assigned', '$totalCredits',
                  Icons.check_circle, Colors.purple),
            ],
          ),
          const SizedBox(height: 20),
          const Text('Quick Action',
              style:
                  TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: _buildActionCard('View My Routine',
                Icons.calendar_today, Colors.blue, onViewRoutine),
          ),
          const SizedBox(height: 20),
          const Text("Today's Schedule",
              style:
                  TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          teacherRoutines.where((r) => r.day == _getTodayDay()).isEmpty
              ? Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12)),
                  child: const Center(
                      child: Text('No classes scheduled for today')),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: teacherRoutines
                      .where((r) => r.day == _getTodayDay())
                      .length,
                  itemBuilder: (context, index) {
                    final routine = teacherRoutines
                        .where((r) => r.day == _getTodayDay())
                        .toList()[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                            backgroundColor: _getTimeColor(routine.slot),
                            child: Text('${routine.slot}',
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 12))),
                        title: Text(
                            '${routine.courseCode} - ${routine.courseTitle}'),
                        subtitle: Text(
                            '${routine.startTime ?? "-"} - ${routine.endTime ?? "-"} | Batch: ${routine.batchId} | Room: ${routine.roomNo ?? 'TBA'}'),
                      ),
                    );
                  },
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
          borderRadius: BorderRadius.circular(20)),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 16),
          const SizedBox(width: 4),
          Text(label,
              style: const TextStyle(color: Colors.white, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildStatCard(
      String label, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(value,
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: color)),
            Text(label,
                style:
                    TextStyle(fontSize: 10, color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard(
      String label, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.3))),
        child: Row(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(width: 16),
            Text(label,
                style: TextStyle(
                    fontSize: 16,
                    color: color,
                    fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

// ========== ROUTINE TAB ==========
class RoutineTab extends StatelessWidget {
  final Teacher teacher;
  final Function(List<Routine>) onDownloadPDF;

  const RoutineTab({
    super.key,
    required this.teacher,
    required this.onDownloadPDF,
  });

  Color _getDayColor(String day) {
    switch (day) {
      case 'Friday':   return Colors.purple;
      case 'Saturday': return Colors.blue;
      case 'Sunday':   return Colors.green;
      case 'Monday':   return Colors.orange;
      case 'Tuesday':  return Colors.red;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final routineProvider = Provider.of<RoutineProvider>(context);
    final teacherRoutines =
        routineProvider.getRoutinesByTeacher(teacher.id!);

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.grey[100],
          child: Row(
            children: [
              const Text('My Routine',
                  style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () async {
                  final provider =
                      Provider.of<RoutineProvider>(context, listen: false);
                  await provider.loadRoutinesFromDatabase();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Routine refreshed'),
                          backgroundColor: Colors.green,
                          duration: Duration(seconds: 1)),
                    );
                  }
                },
                tooltip: 'Refresh',
              ),
              IconButton(
                icon:
                    const Icon(Icons.picture_as_pdf, color: Colors.red),
                onPressed: () => onDownloadPDF(teacherRoutines),
                tooltip: 'Download PDF',
              ),
            ],
          ),
        ),
        Expanded(
          child: teacherRoutines.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.calendar_today,
                          size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('No classes assigned yet'),
                      SizedBox(height: 8),
                      Text('Please contact administrator',
                          style: TextStyle(color: Colors.grey)),
                    ],
                  ),
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
                            child: Text(routine.day[0],
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12))),
                        title: Text(
                            '${routine.courseCode} - ${routine.courseTitle}'),
                        subtitle: Text(
                          '${routine.day} | Slot ${routine.slot} (${routine.startTime ?? "-"}-${routine.endTime ?? "-"})\n'
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
}