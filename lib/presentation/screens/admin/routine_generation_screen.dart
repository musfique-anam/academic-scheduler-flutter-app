import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/routine_provider.dart';
import '../../../providers/department_provider.dart';
import '../../../providers/batch_provider.dart';
import '../../../providers/teacher_provider.dart';
import '../../../providers/room_provider.dart';
import '../../../providers/course_provider.dart';
import '../../../data/models/department_model.dart';
import '../../../data/models/batch_model.dart';
import '../../../data/models/teacher_model.dart';
import '../../../data/models/room_model.dart';
import '../../../data/models/course_model.dart';
import '../../widgets/loading_widget.dart';
import 'conflict_resolution_screen.dart';
import 'workload_summary_screen.dart';
import 'view_routine_screen.dart';

class RoutineGenerationScreen extends StatefulWidget {
  const RoutineGenerationScreen({super.key});

  @override
  State<RoutineGenerationScreen> createState() => _RoutineGenerationScreenState();
}

class _RoutineGenerationScreenState extends State<RoutineGenerationScreen> {
  // Common
  String _routineType = 'Class'; // 'Class' or 'Exam'
  String _generationMode = 'Auto'; // 'Auto' or 'Manual'

  // Class Routine
  Department? _selectedDepartment;
  String _selectedProgram = 'HSC';
  String _selectedGenerateType = 'Batch-wise';

  // Exam Routine
  List<Department> _selectedDepartments = [];
  List<Batch> _selectedBatches = [];
  DateTime? _startDate;
  DateTime? _endDate;

  // Manual Mode
  List<Map<String, dynamic>> _manualEntries = [];

  String _statusMessage = '';

  final List<String> _programTypes = ['HSC', 'Diploma'];
  final List<String> _generateTypes = ['Central', 'Batch-wise'];
  final List<String> _routineTypes = ['Class', 'Exam'];
  final List<String> _generationModes = ['Auto', 'Manual'];

  final List<String> _days = [
    'Friday', 'Saturday', 'Sunday', 'Monday', 'Tuesday'
  ];

  final List<Map<String, dynamic>> _timeSlots = const [
    {'slot': 1, 'time': '9:30 - 11:00', 'start': '9:30', 'end': '11:00'},
    {'slot': 2, 'time': '11:10 - 12:40', 'start': '11:10', 'end': '12:40'},
    {'slot': 3, 'time': '14:00 - 15:30', 'start': '14:00', 'end': '15:30'},
    {'slot': 4, 'time': '15:40 - 17:10', 'start': '15:40', 'end': '17:10'},
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    await Future.wait([
      Provider.of<DepartmentProvider>(context, listen: false).loadDepartments(),
      Provider.of<BatchProvider>(context, listen: false).loadBatches(),
      Provider.of<TeacherProvider>(context, listen: false).loadTeachers(),
      Provider.of<RoomProvider>(context, listen: false).loadRooms(),
      Provider.of<CourseProvider>(context, listen: false).loadCourses(),
    ]);
  }

  void _addManualEntry() {
    setState(() {
      _manualEntries.add({
        'batchId': null,
        'courseId': null,
        'teacherId': null,
        'roomId': null,
        'day': 'Monday',
        'slot': 1,
      });
    });
  }

  void _removeManualEntry(int index) {
    setState(() {
      _manualEntries.removeAt(index);
    });
  }

  Future<void> _generateRoutine() async {
    if (_generationMode == 'Auto') {
      await _generateAutoRoutine();
    } else {
      await _generateManualRoutine();
    }
  }

  Future<void> _generateAutoRoutine() async {
    if (_routineType == 'Class') {
      await _generateClassRoutine();
    } else {
      await _generateExamRoutine();
    }
  }

  Future<void> _generateClassRoutine() async {
    if (_selectedDepartment == null) {
      _showError('Please select a department');
      return;
    }

    final routineProvider = Provider.of<RoutineProvider>(context, listen: false);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _buildGenerationDialog(),
    );

    await routineProvider.generateClassRoutine(
      departmentId: _selectedDepartment!.id!,
      programType: _selectedProgram,
      onStatusUpdate: (status) {
        setState(() {
          _statusMessage = status;
        });
      },
    );

    Navigator.pop(context);

    if (routineProvider.error != null) {
      _showError(routineProvider.error!);
    } else if (routineProvider.hasConflicts || routineProvider.hasOverload) {
      _showIssuesDialog(routineProvider);
    } else {
      _showSuccessDialog(routineProvider);
    }
  }

  Future<void> _generateExamRoutine() async {
    if (_selectedDepartments.isEmpty) {
      _showError('Please select at least one department');
      return;
    }
    if (_selectedBatches.isEmpty) {
      _showError('Please select at least one batch');
      return;
    }
    if (_startDate == null || _endDate == null) {
      _showError('Please select start and end date');
      return;
    }

    // TODO: Implement exam routine generation
    _showSuccessDialog(null);
  }

  Future<void> _generateManualRoutine() async {
    if (_manualEntries.isEmpty) {
      _showError('Please add at least one manual entry');
      return;
    }

    // Validate all entries
    for (var entry in _manualEntries) {
      if (entry['batchId'] == null) {
        _showError('Please select batch for all entries');
        return;
      }
      if (entry['courseId'] == null) {
        _showError('Please select course for all entries');
        return;
      }
    }

    // TODO: Save manual entries to provider
    _showSuccessDialog(null);
  }

  Widget _buildGenerationDialog() {
    return Consumer<RoutineProvider>(
      builder: (context, provider, child) {
        return AlertDialog(
          title: const Text('Generating Routine'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 20),
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 100,
                    height: 100,
                    child: CircularProgressIndicator(
                      value: provider.progress,
                      strokeWidth: 8,
                      backgroundColor: Colors.grey[200],
                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF1976D2)),
                    ),
                  ),
                  Text(
                    '${(provider.progress * 100).toInt()}%',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                _statusMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showIssuesDialog(RoutineProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('⚠️ Issues Detected'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (provider.hasConflicts) ...[
              const Text(
                '• Conflicts found in schedule',
                style: TextStyle(color: Colors.red),
              ),
              const SizedBox(height: 4),
            ],
            if (provider.hasOverload) ...[
              const Text(
                '• Teacher workload exceeded',
                style: TextStyle(color: Colors.orange),
              ),
            ],
            const SizedBox(height: 16),
            const Text(
              'Would you like to fix these issues manually?',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ConflictResolutionScreen(),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('Fix Issues'),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog(RoutineProvider? provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('✅ Routine Generated'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (provider != null) ...[
              Text('Total Classes: ${provider.routines.length}'),
              Text('Conflicts: ${provider.conflicts.length}'),
              Text('Teachers Assigned: ${provider.workloads.length}'),
            ] else ...[
              const Text('Manual routine created successfully'),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ViewRoutineScreen(),
                ),
              );
            },
            child: const Text('View Routine'),
          ),
        ],
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final deptProvider = Provider.of<DepartmentProvider>(context);
    final batchProvider = Provider.of<BatchProvider>(context);
    final teacherProvider = Provider.of<TeacherProvider>(context);
    final roomProvider = Provider.of<RoomProvider>(context);
    final courseProvider = Provider.of<CourseProvider>(context);
    final routineProvider = Provider.of<RoutineProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Generate Routine'),
        backgroundColor: const Color(0xFF1976D2),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              routineProvider.clear();
              setState(() {});
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Routine Type Selection
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Routine Type',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1976D2),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildSelectionChip(
                            label: 'Class Routine',
                            icon: Icons.class_,
                            isSelected: _routineType == 'Class',
                            onTap: () => setState(() => _routineType = 'Class'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildSelectionChip(
                            label: 'Exam Routine',
                            icon: Icons.quiz,
                            isSelected: _routineType == 'Exam',
                            onTap: () => setState(() => _routineType = 'Exam'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Generation Mode Selection
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Generation Mode',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1976D2),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildSelectionChip(
                            label: 'Auto Generate',
                            icon: Icons.auto_awesome,
                            isSelected: _generationMode == 'Auto',
                            onTap: () => setState(() => _generationMode = 'Auto'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildSelectionChip(
                            label: 'Manual Entry',
                            icon: Icons.edit,
                            isSelected: _generationMode == 'Manual',
                            onTap: () => setState(() => _generationMode = 'Manual'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Auto Generation UI
            if (_generationMode == 'Auto') ...[
              if (_routineType == 'Class') ...[
                _buildClassRoutineAutoUI(deptProvider),
              ] else ...[
                _buildExamRoutineAutoUI(deptProvider, batchProvider),
              ],
            ],

            // Manual Generation UI
            if (_generationMode == 'Manual') ...[
              _buildManualRoutineUI(
                deptProvider,
                batchProvider,
                teacherProvider,
                roomProvider,
                courseProvider,
              ),
            ],

            const SizedBox(height: 24),

            // Generate Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _generateRoutine,
                icon: Icon(_generationMode == 'Auto' ? Icons.auto_awesome : Icons.edit),
                label: Text(
                  '${_generationMode} Generate ${_routineType} Routine',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1976D2),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Quick Actions
            if (routineProvider.routines.isNotEmpty) ...[
              const Divider(height: 32),
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
                      icon: Icons.warning_amber,
                      label: 'Conflicts',
                      value: '${routineProvider.conflicts.length}',
                      color: routineProvider.hasConflicts ? Colors.red : Colors.green,
                      onTap: () {
                        if (routineProvider.hasConflicts) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ConflictResolutionScreen(),
                            ),
                          );
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildActionCard(
                      icon: Icons.speed,
                      label: 'Workload',
                      value: '${routineProvider.workloads.length} teachers',
                      color: routineProvider.hasOverload ? Colors.orange : Colors.green,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const WorkloadSummaryScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildActionCard(
                      icon: Icons.calendar_view_day,
                      label: 'View',
                      value: '${routineProvider.routines.length} classes',
                      color: Colors.blue,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ViewRoutineScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildClassRoutineAutoUI(DepartmentProvider deptProvider) {
    return Column(
      children: [
        // Department Selection
        Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Select Department',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1976D2),
                  ),
                ),
                const SizedBox(height: 12),
                Consumer<DepartmentProvider>(
                  builder: (context, provider, child) {
                    return DropdownButtonFormField<Department>(
                      value: _selectedDepartment,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.business),
                      ),
                      hint: const Text('Choose Department'),
                      items: provider.departments.map<DropdownMenuItem<Department>>(
                            (Department dept) {
                          return DropdownMenuItem<Department>(
                            value: dept,
                            child: Text('${dept.name} (${dept.code})'),
                          );
                        },
                      ).toList(),
                      onChanged: (Department? dept) {
                        setState(() {
                          _selectedDepartment = dept;
                        });
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Program Type
        Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Program Type',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1976D2),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildProgramChip(
                        label: 'HSC',
                        isSelected: _selectedProgram == 'HSC',
                        onTap: () => setState(() => _selectedProgram = 'HSC'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildProgramChip(
                        label: 'Diploma',
                        isSelected: _selectedProgram == 'Diploma',
                        onTap: () => setState(() => _selectedProgram = 'Diploma'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Generate Type
        Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Generate Type',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1976D2),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildGenerateChip(
                        label: 'Central',
                        isSelected: _selectedGenerateType == 'Central',
                        onTap: () => setState(() => _selectedGenerateType = 'Central'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildGenerateChip(
                        label: 'Batch-wise',
                        isSelected: _selectedGenerateType == 'Batch-wise',
                        onTap: () => setState(() => _selectedGenerateType = 'Batch-wise'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildExamRoutineAutoUI(DepartmentProvider deptProvider, BatchProvider batchProvider) {
    return Column(
      children: [
        // Departments Selection
        Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Select Departments',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1976D2),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: deptProvider.departments.map((dept) {
                      final isSelected = _selectedDepartments.contains(dept);
                      return CheckboxListTile(
                        title: Text('${dept.name} (${dept.code})'),
                        value: isSelected,
                        onChanged: (selected) {
                          setState(() {
                            if (selected!) {
                              _selectedDepartments.add(dept);
                            } else {
                              _selectedDepartments.remove(dept);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Batches Selection
        Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Select Batches',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1976D2),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: batchProvider.batches.map((batch) {
                      final isSelected = _selectedBatches.contains(batch);
                      return CheckboxListTile(
                        title: Text('Batch ${batch.batchNo} (${batch.programType})'),
                        subtitle: Text('Dept: ${batch.departmentName ?? 'Unknown'}'),
                        value: isSelected,
                        onChanged: (selected) {
                          setState(() {
                            if (selected!) {
                              _selectedBatches.add(batch);
                            } else {
                              _selectedBatches.remove(batch);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Date Range
        Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Exam Date Range',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1976D2),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          DateTime? picked = await showDatePicker(
                            context: context,
                            initialDate: _startDate ?? DateTime.now(),
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                          );
                          if (picked != null) {
                            setState(() {
                              _startDate = picked;
                            });
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            children: [
                              const Icon(Icons.calendar_today, size: 16),
                              const SizedBox(height: 4),
                              Text(
                                _startDate == null
                                    ? 'Start Date'
                                    : '${_startDate!.day}/${_startDate!.month}/${_startDate!.year}',
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          DateTime? picked = await showDatePicker(
                            context: context,
                            initialDate: _endDate ?? DateTime.now(),
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                          );
                          if (picked != null) {
                            setState(() {
                              _endDate = picked;
                            });
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            children: [
                              const Icon(Icons.calendar_today, size: 16),
                              const SizedBox(height: 4),
                              Text(
                                _endDate == null
                                    ? 'End Date'
                                    : '${_endDate!.day}/${_endDate!.month}/${_endDate!.year}',
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildManualRoutineUI(
      DepartmentProvider deptProvider,
      BatchProvider batchProvider,
      TeacherProvider teacherProvider,
      RoomProvider roomProvider,
      CourseProvider courseProvider,
      ) {
    return Column(
      children: [
        // Add Entry Button
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: ElevatedButton.icon(
            onPressed: _addManualEntry,
            icon: const Icon(Icons.add),
            label: const Text('Add Manual Entry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
        ),

        // Manual Entries List
        ..._manualEntries.asMap().entries.map((entry) {
          int index = entry.key;
          Map<String, dynamic> data = entry.value;

          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Entry ${index + 1}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _removeManualEntry(index),
                      ),
                    ],
                  ),

                  const Divider(),

                  // Batch Selection - FIXED
                  DropdownButtonFormField<Batch>(
                    value: data['batchId'] != null
                        ? batchProvider.batches.firstWhere(
                          (b) => b.id == data['batchId'],
                      orElse: () => null as Batch,
                    )
                        : null,
                    decoration: const InputDecoration(
                      labelText: 'Select Batch',
                      border: OutlineInputBorder(),
                    ),
                    hint: const Text('Choose Batch'),
                    items: batchProvider.batches.map<DropdownMenuItem<Batch>>((Batch batch) {
                      return DropdownMenuItem<Batch>(
                        value: batch,
                        child: Text('Batch ${batch.batchNo} (${batch.programType})'),
                      );
                    }).toList(),
                    onChanged: (Batch? batch) {
                      setState(() {
                        data['batchId'] = batch?.id;
                      });
                    },
                  ),

                  const SizedBox(height: 12),

                  // Course Selection (filtered by batch)
                  if (data['batchId'] != null)
                    DropdownButtonFormField<Course>(
                      value: data['courseId'] != null
                          ? courseProvider.courses.firstWhere(
                            (c) => c.id == data['courseId'],
                        orElse: () => null as Course,
                      )
                          : null,
                      decoration: const InputDecoration(
                        labelText: 'Select Course',
                        border: OutlineInputBorder(),
                      ),
                      hint: const Text('Choose Course'),
                      items: courseProvider.courses
                          .where((c) => c.batchId == data['batchId'])
                          .map<DropdownMenuItem<Course>>((Course course) {
                        return DropdownMenuItem<Course>(
                          value: course,
                          child: Text('${course.code} - ${course.title}'),
                        );
                      }).toList(),
                      onChanged: (Course? course) {
                        setState(() {
                          data['courseId'] = course?.id;
                        });
                      },
                    ),

                  const SizedBox(height: 12),

                  // Day Selection - FIXED
                  DropdownButtonFormField<String>(
                    value: data['day'],
                    decoration: const InputDecoration(
                      labelText: 'Day',
                      border: OutlineInputBorder(),
                    ),
                    items: _days.map<DropdownMenuItem<String>>((String day) {
                      return DropdownMenuItem<String>(
                        value: day,
                        child: Text(day),
                      );
                    }).toList(),
                    onChanged: (String? value) {
                      setState(() {
                        data['day'] = value;
                      });
                    },
                  ),

                  const SizedBox(height: 12),

                  // Slot Selection - FIXED
                  DropdownButtonFormField<int>(
                    value: data['slot'],
                    decoration: const InputDecoration(
                      labelText: 'Time Slot',
                      border: OutlineInputBorder(),
                    ),
                    items: _timeSlots.map<DropdownMenuItem<int>>((Map<String, dynamic> slot) {
                      return DropdownMenuItem<int>(
                        value: slot['slot'] as int,
                        child: Text('Slot ${slot['slot']}: ${slot['time']}'),
                      );
                    }).toList(),
                    onChanged: (int? value) {
                      setState(() {
                        data['slot'] = value;
                      });
                    },
                  ),

                  const SizedBox(height: 12),

                  // Teacher Selection - FIXED
                  DropdownButtonFormField<Teacher>(
                    value: data['teacherId'] != null
                        ? teacherProvider.teachers.firstWhere(
                          (t) => t.id == data['teacherId'],
                      orElse: () => null as Teacher,
                    )
                        : null,
                    decoration: const InputDecoration(
                      labelText: 'Teacher (Optional)',
                      border: OutlineInputBorder(),
                    ),
                    hint: const Text('Choose Teacher'),
                    items: [
                      const DropdownMenuItem<Teacher>(
                        value: null,
                        child: Text('None'),
                      ),
                      ...teacherProvider.teachers.map<DropdownMenuItem<Teacher>>((Teacher teacher) {
                        return DropdownMenuItem<Teacher>(
                          value: teacher,
                          child: Text(teacher.name),
                        );
                      }),
                    ],
                    onChanged: (Teacher? teacher) {
                      setState(() {
                        data['teacherId'] = teacher?.id;
                      });
                    },
                  ),

                  const SizedBox(height: 12),

                  // Room Selection - FIXED
                  DropdownButtonFormField<Room>(
                    value: data['roomId'] != null
                        ? roomProvider.rooms.firstWhere(
                          (r) => r.id == data['roomId'],
                      orElse: () => null as Room,
                    )
                        : null,
                    decoration: const InputDecoration(
                      labelText: 'Room (Optional)',
                      border: OutlineInputBorder(),
                    ),
                    hint: const Text('Choose Room'),
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
                    onChanged: (Room? room) {
                      setState(() {
                        data['roomId'] = room?.id;
                      });
                    },
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildSelectionChip({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(
            colors: [Color(0xFF1976D2), Color(0xFF64B5F6)],
          )
              : null,
          color: isSelected ? null : Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.grey.shade400,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? Colors.white : Colors.grey[700]),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey[700],
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgramChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(
            colors: [Color(0xFF1976D2), Color(0xFF64B5F6)],
          )
              : null,
          color: isSelected ? null : Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.grey.shade400,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.black87,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGenerateChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(
            colors: [Colors.green, Colors.lightGreen],
          )
              : null,
          color: isSelected ? null : Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.green : Colors.grey.shade400,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.black87,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required VoidCallback onTap,
  }) {
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
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}