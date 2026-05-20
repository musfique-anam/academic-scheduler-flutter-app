// lib/presentation/screens/admin/view_routine_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../../providers/routine_provider.dart';
import '../../../providers/department_provider.dart';
import '../../../providers/batch_provider.dart';
import '../../../providers/teacher_provider.dart';
import '../../../providers/room_provider.dart';
import '../../../data/models/routine_model.dart';
import '../../../data/models/teacher_model.dart';
import '../../../data/models/batch_model.dart';
import '../../../data/models/department_model.dart';
import '../../../data/models/room_model.dart';

class ViewRoutineScreen extends StatefulWidget {
  const ViewRoutineScreen({super.key});

  @override
  State<ViewRoutineScreen> createState() => _ViewRoutineScreenState();
}

class _ViewRoutineScreenState extends State<ViewRoutineScreen> with AutomaticKeepAliveClientMixin {
  String _routineType = 'Class';
  String _selectedView = 'Batch';
  Department? _selectedDepartment;
  Batch? _selectedBatch;
  Teacher? _selectedTeacher;
  String _selectedDay = 'All';
  bool _isLoading = true;
  bool _isDeleting = false;
  bool _isRefreshing = false;
  String? _errorMessage;

  final List<String> _days = [
    'All', 'Friday', 'Saturday', 'Sunday', 'Monday', 'Tuesday'
  ];

  final List<Map<String, dynamic>> _timeSlots = [
    {'slot': 1, 'time': '9:30 - 11:00', 'start': '9:30', 'end': '11:00'},
    {'slot': 2, 'time': '11:10 - 12:40', 'start': '11:10', 'end': '12:40'},
    {'slot': 3, 'time': '14:00 - 15:30', 'start': '14:00', 'end': '15:30'},
    {'slot': 4, 'time': '15:40 - 17:10', 'start': '15:40', 'end': '17:10'},
  ];

  final List<Map<String, dynamic>> _examTimeSlots = [
    {'slot': 1, 'time': '9:00 - 12:00', 'start': '9:00', 'end': '12:00'},
    {'slot': 2, 'time': '12:30 - 15:30', 'start': '12:30', 'end': '15:30'},
    {'slot': 3, 'time': '16:00 - 19:00', 'start': '16:00', 'end': '19:00'},
  ];

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAllData();
    });
  }

  Future<void> _loadAllData() async {
    if (_isLoading == false) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final routineProvider = Provider.of<RoutineProvider>(context, listen: false);
      final deptProvider = Provider.of<DepartmentProvider>(context, listen: false);
      final batchProvider = Provider.of<BatchProvider>(context, listen: false);
      final teacherProvider = Provider.of<TeacherProvider>(context, listen: false);
      final roomProvider = Provider.of<RoomProvider>(context, listen: false);

      await routineProvider.loadRoutinesFromDatabase();
      await deptProvider.loadDepartments();
      await batchProvider.loadBatches();
      await teacherProvider.loadTeachers();
      await roomProvider.loadRooms();

      print('✅ Data loaded successfully. Class routines: ${routineProvider.routines.where((r) => r.type.toLowerCase() == 'class').length}, Exam routines: ${routineProvider.routines.where((r) => r.type.toLowerCase() == 'exam').length}');
    } catch (e) {
      print('❌ Error loading data: $e');
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isRefreshing = false;
        });
      }
    }
  }

  Future<void> _refreshData() async {
    if (_isRefreshing) return;
    setState(() {
      _isRefreshing = true;
      _errorMessage = null;
    });
    await _loadAllData();
  }

  List<Routine> _getFilteredRoutines(RoutineProvider provider) {
    final routines = provider.routines.where((r) =>
    r.type.toLowerCase() == _routineType.toLowerCase()
    ).toList();

    if (routines.isEmpty) return [];

    var filtered = List<Routine>.from(routines);

    if (_selectedDay != 'All') {
      filtered = filtered.where((r) => r.day == _selectedDay).toList();
    }

    switch (_selectedView) {
      case 'Department':
        if (_selectedDepartment != null) {
          filtered = filtered.where((r) => r.departmentId == _selectedDepartment!.id.toString()).toList();
        }
        break;
      case 'Batch':
        if (_selectedBatch != null) {
          filtered = filtered.where((r) => r.batchId == _selectedBatch!.id.toString()).toList();
        }
        break;
      case 'Teacher':
        if (_selectedTeacher != null) {
          filtered = filtered.where((r) => r.teacherId == _selectedTeacher!.id.toString()).toList();
        }
        break;
    }

    filtered.sort((a, b) {
      final dayCompare = _getDayIndex(a.day).compareTo(_getDayIndex(b.day));
      if (dayCompare != 0) return dayCompare;
      return a.slot.compareTo(b.slot);
    });

    return filtered;
  }

  int _getDayIndex(String day) {
    const days = ['Friday', 'Saturday', 'Sunday', 'Monday', 'Tuesday'];
    return days.indexOf(day);
  }

  List<Map<String, dynamic>> _getCurrentTimeSlots() {
    return _routineType == 'Exam' ? _examTimeSlots : _timeSlots;
  }

  String _getTeacherShortName(String? teacherName, List<Teacher> teachers) {
    if (teacherName == null || teacherName.isEmpty) return 'TBA';
    try {
      final teacher = teachers.firstWhere(
            (t) => t.name == teacherName,
        orElse: () => Teacher(
          id: 0,
          name: teacherName,
          shortName: teacherName.length > 3 ? teacherName.substring(0, 3).toUpperCase() : teacherName,
          username: '',
          password: '',
          phone: '',
          departmentId: 0,
          role: 'teacher',
        ),
      );
      return teacher.shortName;
    } catch (e) {
      return teacherName.length > 3 ? teacherName.substring(0, 3).toUpperCase() : teacherName;
    }
  }

  void _showDeleteDialog() {
    final routineProvider = Provider.of<RoutineProvider>(context, listen: false);
    final filteredRoutines = _getFilteredRoutines(routineProvider);

    if (filteredRoutines.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No routines to delete'), backgroundColor: Colors.orange),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Routine'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('What would you like to delete?'),
            const SizedBox(height: 16),
            if (_selectedView == 'Batch' && _selectedBatch != null)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: Text('Delete ${_selectedBatch!.batchNo} ${_routineType} Routine'),
                onTap: () => _confirmDelete('batch'),
              ),
            if (_selectedView == 'Department' && _selectedDepartment != null)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: Text('Delete ${_selectedDepartment!.name} ${_routineType} Routine'),
                onTap: () => _confirmDelete('department'),
              ),
            ListTile(
              leading: const Icon(Icons.delete_sweep, color: Colors.red),
              title: Text('Delete All ${_routineType} Routines'),
              onTap: () => _confirmDelete('all'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(String scope) async {
    final routineProvider = Provider.of<RoutineProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text('Are you sure you want to delete this ${_routineType.toLowerCase()} routine? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(context);
              Navigator.pop(context);

              setState(() => _isDeleting = true);

              try {
                if (scope == 'batch' && _selectedBatch != null) {
                  final routinesToDelete = routineProvider.routines.where((r) =>
                  r.batchId == _selectedBatch!.id.toString() &&
                      r.type.toLowerCase() == _routineType.toLowerCase()
                  ).toList();

                  for (var routine in routinesToDelete) {
                    if (routine.id != null) {
                      await routineProvider.deleteRoutine(routine.id!);
                    }
                  }
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('${_selectedBatch!.batchNo} ${_routineType} routine deleted'), backgroundColor: Colors.green),
                    );
                  }
                  setState(() => _selectedBatch = null);
                } else if (scope == 'department' && _selectedDepartment != null) {
                  final routinesToDelete = routineProvider.routines.where((r) =>
                  r.departmentId == _selectedDepartment!.id.toString() &&
                      r.type.toLowerCase() == _routineType.toLowerCase()
                  ).toList();

                  for (var routine in routinesToDelete) {
                    if (routine.id != null) {
                      await routineProvider.deleteRoutine(routine.id!);
                    }
                  }
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('${_selectedDepartment!.name} ${_routineType} routine deleted'), backgroundColor: Colors.green),
                    );
                  }
                  setState(() => _selectedDepartment = null);
                } else if (scope == 'all') {
                  final routinesToDelete = routineProvider.routines.where((r) =>
                  r.type.toLowerCase() == _routineType.toLowerCase()
                  ).toList();

                  for (var routine in routinesToDelete) {
                    if (routine.id != null) {
                      await routineProvider.deleteRoutine(routine.id!);
                    }
                  }
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('All $_routineType routines deleted'), backgroundColor: Colors.green),
                    );
                  }
                }

                await _refreshData();
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error deleting: $e'), backgroundColor: Colors.red),
                  );
                }
              } finally {
                if (mounted) {
                  setState(() => _isDeleting = false);
                }
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _generatePDF() async {
    final provider = Provider.of<RoutineProvider>(context, listen: false);
    final routines = _getFilteredRoutines(provider);
    final teacherProvider = Provider.of<TeacherProvider>(context, listen: false);

    if (routines.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No routines to export'), backgroundColor: Colors.orange),
      );
      return;
    }

    try {
      final pdf = pw.Document();
      final currentTimeSlots = _getCurrentTimeSlots();

      final Map<String, Map<String, List<Routine>>> dayBatchMap = {};
      for (var r in routines) {
        dayBatchMap.putIfAbsent(r.day, () => {});
        dayBatchMap[r.day]!.putIfAbsent(r.batchId, () => []);
        dayBatchMap[r.day]![r.batchId]!.add(r);
      }

      const dayOrder = ['Friday', 'Saturday', 'Sunday', 'Monday', 'Tuesday'];

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4.landscape,
          margin: pw.EdgeInsets.all(20),
          build: (pw.Context context) {
            final children = <pw.Widget>[
              pw.Center(
                child: pw.Column(
                  children: [
                    pw.Text('Pundra University of Science & Technology',
                        style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 5),
                    pw.Text('Department of Computer Science & Engineering',
                        style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 5),
                    pw.Text('${_routineType.toUpperCase()} ROUTINE',
                        style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 15),
                  ],
                ),
              ),
            ];

            // Add filters if selected
            if (_selectedDepartment != null) {
              children.add(pw.Center(
                child: pw.Text('Department: ${_selectedDepartment!.name}',
                    style: pw.TextStyle(fontSize: 11)),
              ));
              children.add(pw.SizedBox(height: 5));
            }
            if (_selectedBatch != null) {
              children.add(pw.Center(
                child: pw.Text('Batch: ${_selectedBatch!.batchNo}',
                    style: pw.TextStyle(fontSize: 11)),
              ));
              children.add(pw.SizedBox(height: 5));
            }
            if (_selectedTeacher != null) {
              children.add(pw.Center(
                child: pw.Text('Teacher: ${_selectedTeacher!.name}',
                    style: pw.TextStyle(fontSize: 11)),
              ));
              children.add(pw.SizedBox(height: 5));
            }

            children.add(pw.SizedBox(height: 20));

            // Add day tables
            for (var day in dayOrder) {
              if (dayBatchMap.containsKey(day)) {
                children.add(pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Container(
                      padding: pw.EdgeInsets.all(8),
                      color: PdfColors.blue100,
                      child: pw.Text(day.toUpperCase(),
                          style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                    ),
                    pw.SizedBox(height: 10),
                    _buildPdfRoutineTable(dayBatchMap[day]!, currentTimeSlots, teacherProvider.teachers),
                    pw.SizedBox(height: 20),
                  ],
                ));
              }
            }

            children.add(pw.SizedBox(height: 20));
            children.add(pw.Center(
              child: pw.Column(
                children: [
                  pw.Text('NB – New Building',
                      style: pw.TextStyle(fontSize: 8, color: PdfColors.grey500)),
                  pw.Text('OD – Other Departments',
                      style: pw.TextStyle(fontSize: 8, color: PdfColors.grey500)),
                  pw.SizedBox(height: 5),
                  pw.Text('Generated by Smart Academic Scheduler',
                      style: pw.TextStyle(fontSize: 8, color: PdfColors.grey500)),
                ],
              ),
            ));

            return children;
          },
        ),
      );

      await Printing.sharePdf(
        bytes: await pdf.save(),
        filename: '${_routineType.toLowerCase()}_routine.pdf',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PDF generated successfully'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      print('❌ PDF Error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error generating PDF: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  pw.Widget _buildPdfRoutineTable(Map<String, List<Routine>> batchRoutines, List<Map<String, dynamic>> timeSlots, List<Teacher> teachers) {
    final batches = batchRoutines.keys.toList()..sort((a, b) {
      final aNum = int.tryParse(a) ?? 0;
      final bNum = int.tryParse(b) ?? 0;
      return bNum.compareTo(aNum);
    });

    final headers = ['Batch', ...timeSlots.map((slot) => slot['time'] as String)];

    final tableData = <List<String>>[];

    for (var batch in batches) {
      final row = <String>[batch];
      final slotMap = <int, Routine>{};

      for (var routine in batchRoutines[batch]!) {
        slotMap[routine.slot] = routine;
      }

      for (var slot in timeSlots) {
        final slotNum = slot['slot'] as int;
        if (slotMap.containsKey(slotNum)) {
          final r = slotMap[slotNum]!;
          final shortName = _getTeacherShortName(r.teacherName, teachers);
          row.add('${r.courseCode}\n($shortName)\n${r.roomNo ?? 'TBA'}');
        } else {
          row.add('-');
        }
      }
      tableData.add(row);
    }

    final widgetTable = <List<pw.Widget>>[];

    widgetTable.add(headers.map((header) =>
        pw.Container(
          padding: pw.EdgeInsets.all(8),
          color: PdfColors.grey300,
          child: pw.Text(header, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
        )
    ).toList());

    for (var row in tableData) {
      widgetTable.add(row.map((cell) =>
          pw.Container(
            padding: pw.EdgeInsets.all(6),
            child: pw.Text(cell, style: pw.TextStyle(fontSize: 9)),
          )
      ).toList());
    }

    return pw.Table(
      border: pw.TableBorder.all(),
      children: widgetTable.map((row) => pw.TableRow(children: row)).toList(),
    );
  }

  void _showEditDialog(Routine routine) {
    final teacherProvider = Provider.of<TeacherProvider>(context, listen: false);
    final roomProvider = Provider.of<RoomProvider>(context, listen: false);
    final routineProvider = Provider.of<RoutineProvider>(context, listen: false);

    int selectedSlot = routine.slot;
    String selectedDay = routine.day;
    Teacher? selectedTeacher;
    try {
      selectedTeacher = teacherProvider.teachers.firstWhere(
            (t) => t.id.toString() == routine.teacherId,
      );
    } catch (e) {
      selectedTeacher = null;
    }

    Room? selectedRoom;
    try {
      selectedRoom = roomProvider.rooms.firstWhere(
            (r) => r.id.toString() == routine.roomId,
      );
    } catch (e) {
      selectedRoom = null;
    }

    final currentTimeSlots = _getCurrentTimeSlots();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Row(
              children: [
                const Icon(Icons.edit, color: Color(0xFF1976D2)),
                const SizedBox(width: 8),
                Expanded(child: Text('Edit ${routine.courseCode}', style: const TextStyle(fontSize: 18))),
              ],
            ),
            content: SizedBox(
              width: MediaQuery.of(context).size.width * 0.9,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(12)),
                      child: Column(
                        children: [
                          Text(routine.courseCode, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text(routine.courseTitle, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    DropdownButtonFormField<String>(
                      value: selectedDay,
                      decoration: const InputDecoration(labelText: 'Select Day', border: OutlineInputBorder()),
                      items: _days.where((d) => d != 'All').map((day) =>
                          DropdownMenuItem(value: day, child: Text(day))
                      ).toList(),
                      onChanged: (value) => setState(() => selectedDay = value!),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<int>(
                      value: selectedSlot,
                      decoration: const InputDecoration(labelText: 'Select Time Slot', border: OutlineInputBorder()),
                      items: currentTimeSlots.map((slot) =>
                          DropdownMenuItem(value: slot['slot'] as int, child: Text('Slot ${slot['slot']}: ${slot['time']}'))
                      ).toList(),
                      onChanged: (value) => setState(() => selectedSlot = value!),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<Teacher>(
                      value: selectedTeacher,
                      decoration: const InputDecoration(labelText: 'Select Teacher', border: OutlineInputBorder()),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('None')),
                        ...teacherProvider.teachers.map((teacher) =>
                            DropdownMenuItem(value: teacher, child: Text('${teacher.name} (${teacher.shortName})'))
                        ),
                      ],
                      onChanged: (value) => setState(() => selectedTeacher = value),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<Room>(
                      value: selectedRoom,
                      decoration: const InputDecoration(labelText: 'Select Room', border: OutlineInputBorder()),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('None')),
                        ...roomProvider.rooms.map((room) =>
                            DropdownMenuItem(value: room, child: Text('${room.roomNo} (F${room.floor})'))
                        ),
                      ],
                      onChanged: (value) => setState(() => selectedRoom = value),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () async {
                  final Map<String, dynamic> changes = {};
                  if (selectedDay != routine.day) changes['day'] = selectedDay;
                  if (selectedSlot != routine.slot) changes['slot'] = selectedSlot;
                  if (selectedTeacher?.id.toString() != routine.teacherId) {
                    changes['teacherId'] = selectedTeacher?.id.toString();
                    changes['teacherName'] = selectedTeacher?.name;
                  }
                  if (selectedRoom?.id.toString() != routine.roomId) {
                    changes['roomId'] = selectedRoom?.id.toString();
                    changes['roomNo'] = selectedRoom?.roomNo;
                  }

                  if (changes.isNotEmpty) {
                    routineProvider.editRoutine(routine, changes);
                    await _refreshData();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Routine updated'), backgroundColor: Colors.green),
                      );
                    }
                  }
                  if (mounted) Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1976D2)),
                child: const Text('Save Changes'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final routineProvider = Provider.of<RoutineProvider>(context);
    final deptProvider = Provider.of<DepartmentProvider>(context);
    final batchProvider = Provider.of<BatchProvider>(context);
    final teacherProvider = Provider.of<TeacherProvider>(context);

    final filteredRoutines = _getFilteredRoutines(routineProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('View Routine'),
        backgroundColor: const Color(0xFF1976D2),
        foregroundColor: Colors.white,
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(20)),
            child: Row(children: [
              _buildTypeChip('Class', _routineType == 'Class'),
              _buildTypeChip('Exam', _routineType == 'Exam'),
            ]),
          ),
          if (filteredRoutines.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _showDeleteDialog,
            ),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: filteredRoutines.isEmpty ? null : _generatePDF,
          ),
          IconButton(
            icon: _isRefreshing
                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.refresh),
            onPressed: _isRefreshing ? null : _refreshData,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: _buildBody(routineProvider, deptProvider, batchProvider, teacherProvider, filteredRoutines),
      ),
    );
  }

  Widget _buildBody(
      RoutineProvider routineProvider,
      DepartmentProvider deptProvider,
      BatchProvider batchProvider,
      TeacherProvider teacherProvider,
      List<Routine> filteredRoutines,
      ) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text('Error loading data', style: TextStyle(fontSize: 18, color: Colors.red[700])),
            const SizedBox(height: 8),
            Text(_errorMessage!, style: TextStyle(color: Colors.grey[600])),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _refreshData,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (routineProvider.routines.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.calendar_view_day, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text('No routine generated yet', style: TextStyle(fontSize: 18)),
            const SizedBox(height: 8),
            Text('Generate a routine first', style: TextStyle(color: Colors.grey[500])),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.pushReplacementNamed(context, '/admin/dashboard'),
              child: const Text('Go to Dashboard'),
            ),
          ],
        ),
      );
    }

    if (_isDeleting) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        _buildFilterSection(deptProvider, batchProvider, teacherProvider),
        _buildStatsSection(filteredRoutines),
        Expanded(
          child: filteredRoutines.isEmpty
              ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.info_outline, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text('No $_routineType routines found', style: TextStyle(fontSize: 16)),
                const SizedBox(height: 8),
                if (_routineType == 'Exam')
                  const Text('Generate exam routine first from Routine Generation screen', style: TextStyle(color: Colors.grey)),
              ],
            ),
          )
              : _buildRoutineTableWidget(filteredRoutines, teacherProvider.teachers),
        ),
      ],
    );
  }

  Widget _buildFilterSection(DepartmentProvider deptProvider, BatchProvider batchProvider, TeacherProvider teacherProvider) {
    return Container(
      padding: const EdgeInsets.all(12),
      color: Colors.grey[100],
      child: Column(
        children: [
          Row(
            children: [
              const Text('View by: '),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedView,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    isDense: true,
                  ),
                  items: const [
                    DropdownMenuItem(value: 'Batch', child: Text('Batch')),
                    DropdownMenuItem(value: 'Department', child: Text('Department')),
                    DropdownMenuItem(value: 'Teacher', child: Text('Teacher')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedView = value!;
                      _selectedDepartment = null;
                      _selectedBatch = null;
                      _selectedTeacher = null;
                    });
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (_selectedView == 'Department')
            DropdownButtonFormField<Department>(
              value: _selectedDepartment,
              hint: const Text('Select Department'),
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                isDense: true,
              ),
              items: [
                ...deptProvider.departments.map((d) =>
                    DropdownMenuItem(value: d, child: Text('${d.name} (${d.code})'))
                ),
              ],
              onChanged: (d) => setState(() => _selectedDepartment = d),
            ),
          if (_selectedView == 'Batch')
            DropdownButtonFormField<Batch>(
              value: _selectedBatch,
              hint: const Text('Select Batch'),
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                isDense: true,
              ),
              items: [
                ...batchProvider.batches.map((b) =>
                    DropdownMenuItem(value: b, child: Text('Batch ${b.batchNo}'))
                ),
              ],
              onChanged: (b) => setState(() => _selectedBatch = b),
            ),
          if (_selectedView == 'Teacher')
            DropdownButtonFormField<Teacher>(
              value: _selectedTeacher,
              hint: const Text('Select Teacher'),
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                isDense: true,
              ),
              items: [
                ...teacherProvider.teachers.map((t) =>
                    DropdownMenuItem(value: t, child: Text(t.name))
                ),
              ],
              onChanged: (t) => setState(() => _selectedTeacher = t),
            ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _selectedDay,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              isDense: true,
            ),
            items: _days.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
            onChanged: (d) => setState(() => _selectedDay = d!),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection(List<Routine> routines) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStatCard('Total', '${routines.length}', Icons.class_, Colors.blue),
          _buildStatCard('Batches', '${routines.map((r) => r.batchId).toSet().length}', Icons.group, Colors.green),
          _buildStatCard('Teachers', '${routines.map((r) => r.teacherId).where((id) => id != null && id.isNotEmpty).toSet().length}', Icons.person, Colors.orange),
        ],
      ),
    );
  }

  Widget _buildRoutineTableWidget(List<Routine> routines, List<Teacher> teachers) {
    final Map<String, List<Routine>> dayMap = {};
    for (var r in routines) {
      dayMap.putIfAbsent(r.day, () => []).add(r);
    }

    List<String> dayOrder = ['Friday', 'Saturday', 'Sunday', 'Monday', 'Tuesday'];
    final currentTimeSlots = _getCurrentTimeSlots();

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: dayOrder.where((d) => dayMap.containsKey(d)).length,
      itemBuilder: (context, index) {
        final day = dayOrder.firstWhere((d) => dayMap.containsKey(d));
        dayOrder.remove(day);
        final dayRoutines = dayMap[day]!;

        final Map<String, List<Routine>> batchMap = {};
        for (var r in dayRoutines) {
          batchMap.putIfAbsent(r.batchId, () => []).add(r);
        }

        final batches = batchMap.keys.toList()..sort((a, b) {
          final aNum = int.tryParse(a) ?? 0;
          final bNum = int.tryParse(b) ?? 0;
          return bNum.compareTo(aNum);
        });

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _getDayColor(day),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                child: Text(
                  day.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: DataTable(
                    columnSpacing: 8,
                    headingRowHeight: 40,
                    dataRowMinHeight: 50,
                    dataRowMaxHeight: 70,
                    headingRowColor: WidgetStateProperty.all(Colors.grey[200]),
                    columns: [
                      const DataColumn(label: Text('Batch', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                      ...currentTimeSlots.map((slot) =>
                          DataColumn(label: Text(slot['time'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10)))
                      ),
                    ],
                    rows: batches.map((batch) {
                      final Map<int, Routine> slotMap = {};
                      for (var r in batchMap[batch]!) {
                        slotMap[r.slot] = r;
                      }

                      return DataRow(cells: [
                        DataCell(Container(
                          width: 55,
                          child: Text('Batch $batch', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        )),
                        ...currentTimeSlots.map((slot) {
                          final slotNum = slot['slot'] as int;
                          if (slotMap.containsKey(slotNum)) {
                            final r = slotMap[slotNum]!;
                            final shortName = _getTeacherShortName(r.teacherName, teachers);
                            return DataCell(
                              Container(
                                width: 120,
                                padding: const EdgeInsets.all(4),
                                child: GestureDetector(
                                  onLongPress: () => _showEditDialog(r),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(r.courseCode, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                                      const SizedBox(height: 2),
                                      Text(shortName, style: const TextStyle(fontSize: 9, color: Colors.grey)),
                                      Text(r.roomNo ?? 'TBA', style: const TextStyle(fontSize: 9, color: Colors.grey)),
                                    ],
                                  ),
                                ),
                              ),
                              onTap: () => _showEditDialog(r),
                            );
                          } else {
                            return DataCell(
                              Container(width: 120, padding: const EdgeInsets.all(4), child: const Text('-', style: TextStyle(fontSize: 12))),
                            );
                          }
                        }),
                      ]);
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTypeChip(String label, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _routineType = label;
          _selectedDepartment = null;
          _selectedBatch = null;
          _selectedTeacher = null;
          _selectedDay = 'All';
        });
        _refreshData();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? const Color(0xFF1976D2) : Colors.white,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 2),
          Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
          Text(label, style: TextStyle(fontSize: 9, color: Colors.grey[600])),
        ],
      ),
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