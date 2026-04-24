import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
import 'package:printing/printing.dart';
import 'package:pdf/widgets.dart' as pw;

class ViewRoutineScreen extends StatefulWidget {
  const ViewRoutineScreen({super.key});

  @override
  State<ViewRoutineScreen> createState() => _ViewRoutineScreenState();
}

class _ViewRoutineScreenState extends State<ViewRoutineScreen> {
  String _selectedView = 'Department';
  Department? _selectedDepartment;
  Batch? _selectedBatch;
  Teacher? _selectedTeacher;
  String _selectedDay = 'All';
  bool _isEditMode = false;
  bool _isLoading = false;

  final List<String> _days = [
    'All', 'Friday', 'Saturday', 'Sunday', 'Monday', 'Tuesday'
  ];

  final List<Map<String, dynamic>> _timeSlots = [
    {'slot': 1, 'time': '9:30 - 11:00', 'start': '9:30', 'end': '11:00'},
    {'slot': 2, 'time': '11:10 - 12:40', 'start': '11:10', 'end': '12:40'},
    {'slot': 3, 'time': '14:00 - 15:30', 'start': '14:00', 'end': '15:30'},
    {'slot': 4, 'time': '15:40 - 17:10', 'start': '15:40', 'end': '17:10'},
  ];

  @override
  void initState() {
    super.initState();
    // Use addPostFrameCallback to prevent setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    if (!mounted) return;

    setState(() => _isLoading = true);

    try {
      await Future.wait([
        Provider.of<DepartmentProvider>(context, listen: false).loadDepartments(),
        Provider.of<BatchProvider>(context, listen: false).loadBatches(),
        Provider.of<TeacherProvider>(context, listen: false).loadTeachers(),
        Provider.of<RoomProvider>(context, listen: false).loadRooms(),
      ]);
    } catch (e) {
      print('Error loading data: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  List<Routine> _getFilteredRoutines(RoutineProvider provider) {
    if (provider.routines.isEmpty) return [];

    var routines = List<Routine>.from(provider.routines);

    if (_selectedDay != 'All') {
      routines = routines.where((r) => r.day == _selectedDay).toList();
    }

    switch (_selectedView) {
      case 'Department':
        if (_selectedDepartment != null) {
          routines = routines.where((r) => r.departmentId == _selectedDepartment!.id).toList();
        }
        break;
      case 'Batch':
        if (_selectedBatch != null) {
          routines = routines.where((r) => r.batchId == _selectedBatch!.id).toList();
        }
        break;
      case 'Teacher':
        if (_selectedTeacher != null) {
          routines = routines.where((r) => r.teacherId == _selectedTeacher!.id).toList();
        }
        break;
    }

    routines.sort((a, b) {
      int dayCompare = _getDayIndex(a.day).compareTo(_getDayIndex(b.day));
      if (dayCompare != 0) return dayCompare;
      return a.slot.compareTo(b.slot);
    });

    return routines;
  }

  int _getDayIndex(String day) {
    const days = ['Friday', 'Saturday', 'Sunday', 'Monday', 'Tuesday'];
    return days.indexOf(day);
  }

  // Edit Dialog
  void _showEditDialog(Routine routine) {
    final teacherProvider = Provider.of<TeacherProvider>(context, listen: false);
    final roomProvider = Provider.of<RoomProvider>(context, listen: false);
    final routineProvider = Provider.of<RoutineProvider>(context, listen: false);

    int selectedSlot = routine.slot;
    String selectedDay = routine.day;
    Teacher? selectedTeacher = teacherProvider.teachers.firstWhere(
          (t) => t.id == routine.teacherId,
      orElse: () => null as Teacher,
    );
    Room? selectedRoom = roomProvider.rooms.firstWhere(
          (r) => r.id == routine.roomId,
      orElse: () => null as Room,
    );

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Row(
              children: [
                const Icon(Icons.edit, color: Color(0xFF1976D2)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Edit ${routine.courseCode}',
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
              ],
            ),
            content: Container(
              width: MediaQuery.of(context).size.width * 0.9,
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.7,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Course Info Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Column(
                        children: [
                          Text(
                            routine.courseCode,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            routine.courseTitle,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.blue[100],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Batch: ${routine.batchId}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Day Selection
                    DropdownButtonFormField<String>(
                      value: selectedDay,
                      decoration: const InputDecoration(
                        labelText: 'Select Day',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.calendar_today),
                      ),
                      items: _days.where((d) => d != 'All').map<DropdownMenuItem<String>>((String day) {
                        return DropdownMenuItem<String>(
                          value: day,
                          child: Text(day),
                        );
                      }).toList(),
                      onChanged: (String? value) {
                        setState(() {
                          selectedDay = value!;
                        });
                      },
                    ),

                    const SizedBox(height: 16),

                    // Slot Selection
                    DropdownButtonFormField<int>(
                      value: selectedSlot,
                      decoration: const InputDecoration(
                        labelText: 'Select Time Slot',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.access_time),
                      ),
                      items: _timeSlots.map<DropdownMenuItem<int>>((Map<String, dynamic> slot) {
                        return DropdownMenuItem<int>(
                          value: slot['slot'] as int,
                          child: Text('Slot ${slot['slot']}: ${slot['time']}'),
                        );
                      }).toList(),
                      onChanged: (int? value) {
                        setState(() {
                          selectedSlot = value!;
                        });
                      },
                    ),

                    const SizedBox(height: 16),

                    // Teacher Selection
                    DropdownButtonFormField<Teacher>(
                      value: selectedTeacher,
                      decoration: const InputDecoration(
                        labelText: 'Select Teacher',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person),
                      ),
                      items: [
                        const DropdownMenuItem<Teacher>(
                          value: null,
                          child: Text('None'),
                        ),
                        ...teacherProvider.teachers.map<DropdownMenuItem<Teacher>>((Teacher teacher) {
                          return DropdownMenuItem<Teacher>(
                            value: teacher,
                            child: Text('${teacher.name} (${teacher.shortName})'),
                          );
                        }),
                      ],
                      onChanged: (Teacher? value) {
                        setState(() {
                          selectedTeacher = value;
                        });
                      },
                    ),

                    const SizedBox(height: 16),

                    // Room Selection
                    DropdownButtonFormField<Room>(
                      value: selectedRoom,
                      decoration: const InputDecoration(
                        labelText: 'Select Room',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.meeting_room),
                      ),
                      items: [
                        const DropdownMenuItem<Room>(
                          value: null,
                          child: Text('None'),
                        ),
                        ...roomProvider.rooms.map<DropdownMenuItem<Room>>((Room room) {
                          return DropdownMenuItem<Room>(
                            value: room,
                            child: Text('${room.roomNo} (F${room.floor})'),
                          );
                        }),
                      ],
                      onChanged: (Room? value) {
                        setState(() {
                          selectedRoom = value;
                        });
                      },
                    ),

                    const SizedBox(height: 16),

                    // Conflict Check
                    if (selectedDay != routine.day || selectedSlot != routine.slot ||
                        selectedTeacher?.id != routine.teacherId ||
                        selectedRoom?.id != routine.roomId)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.orange.shade200),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.info, color: Colors.orange),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Changes will be checked for conflicts',
                                style: TextStyle(color: Colors.orange[700]),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  // Create changes map
                  Map<String, dynamic> changes = {};

                  if (selectedDay != routine.day) {
                    changes['day'] = selectedDay;
                  }
                  if (selectedSlot != routine.slot) {
                    changes['slot'] = selectedSlot;
                  }
                  if (selectedTeacher?.id != routine.teacherId) {
                    changes['teacherId'] = selectedTeacher?.id;
                    changes['teacherName'] = selectedTeacher?.name;
                  }
                  if (selectedRoom?.id != routine.roomId) {
                    changes['roomId'] = selectedRoom?.id;
                    changes['roomNo'] = selectedRoom?.roomNo;
                  }

                  if (changes.isNotEmpty) {
                    routineProvider.editRoutine(routine, changes);

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Routine updated successfully'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }

                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1976D2),
                ),
                child: const Text('Save Changes'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _generatePDF() async {
    final provider = Provider.of<RoutineProvider>(context, listen: false);
    final routines = _getFilteredRoutines(provider);

    if (routines.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No routines to export'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      final pdf = pw.Document();

      pdf.addPage(
        pw.Page(
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Center(
                  child: pw.Column(
                    children: [
                      pw.Text(
                        'Pundra University of Science & Technology',
                        style: pw.TextStyle(
                          fontSize: 20,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(
                        'Class Routine',
                        style: pw.TextStyle(fontSize: 16),
                      ),
                      pw.SizedBox(height: 20),
                    ],
                  ),
                ),
                pw.TableHelper.fromTextArray(
                  headers: ['Day', 'Time', 'Course', 'Batch', 'Room', 'Teacher'],
                  data: routines.map((r) => [
                    r.day,
                    '${r.startTime}-${r.endTime}',
                    '${r.courseCode}\n${r.courseTitle}',
                    'Batch ${r.batchId ?? 'N/A'}',
                    r.roomNo ?? 'TBA',
                    r.teacherName ?? 'TBA',
                  ]).toList(),
                  border: pw.TableBorder.all(),
                  headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  cellAlignment: pw.Alignment.centerLeft,
                ),
              ],
            );
          },
        ),
      );

      await Printing.sharePdf(
        bytes: await pdf.save(),
        filename: 'routine_${DateTime.now().millisecondsSinceEpoch}.pdf',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('PDF generated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
          // Edit Mode Toggle
          IconButton(
            icon: Icon(_isEditMode ? Icons.edit_off : Icons.edit),
            onPressed: () {
              setState(() {
                _isEditMode = !_isEditMode;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(_isEditMode ? 'Edit mode enabled' : 'Edit mode disabled'),
                  backgroundColor: _isEditMode ? Colors.green : Colors.grey,
                ),
              );
            },
            tooltip: _isEditMode ? 'Disable Edit Mode' : 'Enable Edit Mode',
          ),

          // PDF Export
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: routineProvider.routines.isEmpty ? null : _generatePDF,
            tooltip: 'Download PDF',
          ),

          // Share
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: routineProvider.routines.isEmpty ? null : () {},
            tooltip: 'Share',
          ),

          // Refresh
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : routineProvider.routines.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.calendar_view_day, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No routine generated yet',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Generate a routine first',
              style: TextStyle(color: Colors.grey[500]),
            ),
          ],
        ),
      )
          : Column(
        children: [
          // Filter Bar
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[100],
            child: Column(
              children: [
                // View Type Selection
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
                        ),
                        items: const [
                          DropdownMenuItem<String>(value: 'Department', child: Text('Department')),
                          DropdownMenuItem<String>(value: 'Batch', child: Text('Batch')),
                          DropdownMenuItem<String>(value: 'Teacher', child: Text('Teacher')),
                        ],
                        onChanged: (String? value) {
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

                // Dynamic filter based on view
                if (_selectedView == 'Department')
                  DropdownButtonFormField<Department>(
                    value: _selectedDepartment,
                    decoration: const InputDecoration(
                      labelText: 'Select Department',
                      border: OutlineInputBorder(),
                    ),
                    hint: const Text('All Departments'),
                    items: [
                      const DropdownMenuItem<Department>(
                        value: null,
                        child: Text('All Departments'),
                      ),
                      ...deptProvider.departments.map<DropdownMenuItem<Department>>(
                            (Department dept) => DropdownMenuItem<Department>(
                          value: dept,
                          child: Text('${dept.name} (${dept.code})'),
                        ),
                      ),
                    ],
                    onChanged: (Department? dept) => setState(() => _selectedDepartment = dept),
                  ),

                if (_selectedView == 'Batch')
                  DropdownButtonFormField<Batch>(
                    value: _selectedBatch,
                    decoration: const InputDecoration(
                      labelText: 'Select Batch',
                      border: OutlineInputBorder(),
                    ),
                    hint: const Text('All Batches'),
                    items: [
                      const DropdownMenuItem<Batch>(
                        value: null,
                        child: Text('All Batches'),
                      ),
                      ...batchProvider.batches.map<DropdownMenuItem<Batch>>(
                            (Batch batch) => DropdownMenuItem<Batch>(
                          value: batch,
                          child: Text('Batch ${batch.batchNo}'),
                        ),
                      ),
                    ],
                    onChanged: (Batch? batch) => setState(() => _selectedBatch = batch),
                  ),

                if (_selectedView == 'Teacher')
                  DropdownButtonFormField<Teacher>(
                    value: _selectedTeacher,
                    decoration: const InputDecoration(
                      labelText: 'Select Teacher',
                      border: OutlineInputBorder(),
                    ),
                    hint: const Text('All Teachers'),
                    items: [
                      const DropdownMenuItem<Teacher>(
                        value: null,
                        child: Text('All Teachers'),
                      ),
                      ...teacherProvider.teachers.map<DropdownMenuItem<Teacher>>(
                            (Teacher teacher) => DropdownMenuItem<Teacher>(
                          value: teacher,
                          child: Text(teacher.name),
                        ),
                      ),
                    ],
                    onChanged: (Teacher? teacher) => setState(() => _selectedTeacher = teacher),
                  ),

                const SizedBox(height: 8),

                // Day filter
                DropdownButtonFormField<String>(
                  value: _selectedDay,
                  decoration: const InputDecoration(
                    labelText: 'Filter by Day',
                    border: OutlineInputBorder(),
                  ),
                  items: _days.map<DropdownMenuItem<String>>((String day) {
                    return DropdownMenuItem<String>(
                      value: day,
                      child: Text(day),
                    );
                  }).toList(),
                  onChanged: (String? value) => setState(() => _selectedDay = value!),
                ),

                // Active Filters Display
                if (_selectedDepartment != null || _selectedBatch != null ||
                    _selectedTeacher != null || _selectedDay != 'All')
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Row(
                      children: [
                        const Icon(Icons.filter_list, size: 16),
                        const SizedBox(width: 4),
                        Expanded(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                if (_selectedDepartment != null)
                                  Container(
                                    margin: const EdgeInsets.only(right: 4),
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.blue[100],
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      _selectedDepartment!.code,
                                      style: const TextStyle(fontSize: 11),
                                    ),
                                  ),
                                if (_selectedBatch != null)
                                  Container(
                                    margin: const EdgeInsets.only(right: 4),
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.green[100],
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      'B${_selectedBatch!.batchNo}',
                                      style: const TextStyle(fontSize: 11),
                                    ),
                                  ),
                                if (_selectedTeacher != null)
                                  Container(
                                    margin: const EdgeInsets.only(right: 4),
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.purple[100],
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      _selectedTeacher!.shortName,
                                      style: const TextStyle(fontSize: 11),
                                    ),
                                  ),
                                if (_selectedDay != 'All')
                                  Container(
                                    margin: const EdgeInsets.only(right: 4),
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.orange[100],
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      _selectedDay.substring(0, 3),
                                      style: const TextStyle(fontSize: 11),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.clear, size: 16),
                          onPressed: () {
                            setState(() {
                              _selectedDepartment = null;
                              _selectedBatch = null;
                              _selectedTeacher = null;
                              _selectedDay = 'All';
                            });
                          },
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          // Summary Stats
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatCard(
                  'Total',
                  '${filteredRoutines.length}',
                  Icons.class_,
                  Colors.blue,
                ),
                _buildStatCard(
                  'Conflicts',
                  '${filteredRoutines.where((r) => r.status == 'conflict').length}',
                  Icons.warning,
                  filteredRoutines.any((r) => r.status == 'conflict') ? Colors.red : Colors.green,
                ),
                _buildStatCard(
                  'Teachers',
                  '${filteredRoutines.map((r) => r.teacherId).toSet().length}',
                  Icons.person,
                  Colors.orange,
                ),
              ],
            ),
          ),

          // Routine List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: filteredRoutines.length,
              itemBuilder: (context, index) {
                final routine = filteredRoutines[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: routine.status == 'conflict'
                          ? Colors.red.shade200
                          : (routine.status == 'manual_fixed'
                          ? Colors.orange.shade200
                          : Colors.grey.shade300),
                      width: routine.status == 'conflict' ? 2 : 1,
                    ),
                  ),
                  child: InkWell(
                    onTap: _isEditMode ? () => _showEditDialog(routine) : null,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header with time and edit indicator
                          Row(
                            children: [
                              Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  color: _getDayColor(routine.day),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    routine.day[0],
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 20,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Slot ${routine.slot} (${routine.startTime}-${routine.endTime})',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      routine.courseCode,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (_isEditMode)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.blue[100],
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Text(
                                    'EDIT',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.blue,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ],
                          ),

                          const SizedBox(height: 12),

                          // Course Title
                          Text(
                            routine.courseTitle,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),

                          const SizedBox(height: 8),

                          // Details Grid
                          Row(
                            children: [
                              Expanded(
                                child: _buildDetailChip(
                                  Icons.group,
                                  'Batch ${routine.batchId ?? 'N/A'}',
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _buildDetailChip(
                                  Icons.meeting_room,
                                  routine.roomNo ?? 'TBA',
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _buildDetailChip(
                                  Icons.person,
                                  routine.teacherName ?? 'TBA',
                                ),
                              ),
                            ],
                          ),

                          // Conflict Message
                          if (routine.status == 'conflict' && routine.conflictReason != null) ...[
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.red[50],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.red.shade200),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.warning, color: Colors.red, size: 16),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      routine.conflictReason!,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Colors.red,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],

                          // Manual Fixed Indicator
                          if (routine.status == 'manual_fixed')
                            Align(
                              alignment: Alignment.centerRight,
                              child: Container(
                                margin: const EdgeInsets.only(top: 4),
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.orange[100],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'Manually Adjusted',
                                  style: TextStyle(
                                    fontSize: 9,
                                    color: Colors.orange[700],
                                  ),
                                ),
                              ),
                            ),
                        ],
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

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
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
    );
  }

  Widget _buildDetailChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.grey[700]),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 11),
              overflow: TextOverflow.ellipsis,
            ),
          ),
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