import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/department_provider.dart';
import '../../../providers/batch_provider.dart';
import '../../../providers/teacher_provider.dart';
import '../../../providers/room_provider.dart';
import '../../../providers/course_provider.dart';
import '../../../data/models/batch_model.dart';
import '../../../data/models/department_model.dart';
import '../../../data/models/teacher_model.dart';
import '../../../data/models/room_model.dart';
import '../../../data/models/course_model.dart';
import '../../../data/models/merge_model.dart';
import '../../widgets/loading_widget.dart';

class MergeSectionScreen extends StatefulWidget {
  const MergeSectionScreen({super.key});

  @override
  State<MergeSectionScreen> createState() => _MergeSectionScreenState();
}

class _MergeSectionScreenState extends State<MergeSectionScreen> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _courseTitleController = TextEditingController();
  final TextEditingController _creditController = TextEditingController();

  // Multiple course code controllers for each batch
  final List<TextEditingController> _courseCodeControllers = [];

  // Merge type
  bool _isAutoMerge = true;

  // Selected items
  List<Batch> _selectedBatches = [];
  List<Map<String, dynamic>> _batchCourseCodes = [];
  Teacher? _selectedTeacher;
  Room? _selectedRoom;
  String _selectedDay = 'Monday';
  int _selectedSlot = 1;

  // Filters
  Department? _selectedFilterDepartment;
  Department? _selectedTeacherDepartment;
  int? _selectedRoomFloor;
  Department? _selectedRoomDepartment;
  String _searchQuery = '';

  // Auto merge suggestions
  List<Map<String, dynamic>> _mergeSuggestions = [];
  Map<String, dynamic>? _selectedSuggestion;

  // Existing merges list
  List<MergedClass> _existingMerges = [];
  MergedClass? _editingMerge;

  final List<String> _days = [
    'Friday', 'Saturday', 'Sunday', 'Monday', 'Tuesday'
  ];

  final List<Map<String, dynamic>> _timeSlots = [
    {'slot': 1, 'time': '9:30 - 11:00', 'start': '9:30', 'end': '11:00'},
    {'slot': 2, 'time': '11:10 - 12:40', 'start': '11:10', 'end': '12:40'},
    {'slot': 3, 'time': '14:00 - 15:30', 'start': '14:00', 'end': '15:30'},
    {'slot': 4, 'time': '15:40 - 17:10', 'start': '15:40', 'end': '17:10'},
  ];

  List<int> _floors = List.generate(20, (i) => i + 1);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAllData();
    });

    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });

    _courseTitleController.addListener(() {
      if (_isAutoMerge && _selectedBatches.isNotEmpty) {
        _findMergeSuggestions();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _courseTitleController.dispose();
    _creditController.dispose();
    for (var controller in _courseCodeControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _loadAllData() async {
    await Future.wait([
      Provider.of<DepartmentProvider>(context, listen: false).loadDepartments(),
      Provider.of<BatchProvider>(context, listen: false).loadBatches(),
      Provider.of<TeacherProvider>(context, listen: false).loadTeachers(),
      Provider.of<RoomProvider>(context, listen: false).loadRooms(),
      Provider.of<CourseProvider>(context, listen: false).loadCourses(),
    ]);
  }

  void _editMerge(MergedClass merge) {
    setState(() {
      _editingMerge = merge;
      _isAutoMerge = false; // Manual mode for editing

      // Clear existing selections
      _selectedBatches.clear();
      _courseCodeControllers.clear();

      // Load batches from merge
      final batchProvider = Provider.of<BatchProvider>(context, listen: false);
      for (int i = 0; i < merge.batchIds.length; i++) {
        final batchId = merge.batchIds[i];
        try {
          final batch = batchProvider.batches.firstWhere((b) => b.id == batchId);
          _selectedBatches.add(batch);

          // Create controller for this batch's course code
          final controller = TextEditingController();

          // Extract course code from merged string
          String code = '';
          if (merge.mergedCourseCode.contains('+')) {
            final codes = merge.mergedCourseCode.split('+');
            if (i < codes.length) {
              code = codes[i].trim().split('-').last;
            }
          }
          controller.text = code;
          _courseCodeControllers.add(controller);

        } catch (e) {
          print('❌ Batch not found: $batchId');
        }
      }

      // Load course details
      _courseTitleController.text = merge.mergedCourseTitle;
      _creditController.text = merge.credit.toString();

      // Load teacher
      if (merge.teacherId != null) {
        final teacherProvider = Provider.of<TeacherProvider>(context, listen: false);
        try {
          _selectedTeacher = teacherProvider.teachers.firstWhere(
                  (t) => t.id == merge.teacherId
          );
        } catch (e) {
          _selectedTeacher = null;
        }
      } else {
        _selectedTeacher = null;
      }

      // Load room
      if (merge.roomId != null) {
        final roomProvider = Provider.of<RoomProvider>(context, listen: false);
        try {
          _selectedRoom = roomProvider.rooms.firstWhere(
                  (r) => r.id == merge.roomId
          );
        } catch (e) {
          _selectedRoom = null;
        }
      } else {
        _selectedRoom = null;
      }

      // Load time
      _selectedDay = merge.day;
      _selectedSlot = merge.timeSlot;
    });

    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Loading merge for editing...'),
        backgroundColor: Colors.blue,
      ),
    );

    // Switch to first tab (Create Merge tab)
    //DefaultTabController.of(context)?.animateTo(0);
  }

  void _deleteMerge(MergedClass merge) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Merge'),
        content: Text('Delete this merged class?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _existingMerges.remove(merge);
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Merge deleted'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _createMerge() {
    // Validate inputs
    if (_selectedBatches.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one batch'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_courseTitleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter course title'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_creditController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter credit hours'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    double? credit = double.tryParse(_creditController.text);
    if (credit == null || credit <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter valid credit hours'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Generate merged course code
    String mergedCode = _isAutoMerge
        ? _getMergedCourseDisplay()
        : _getManualMergedCode();

    // Create merge object
    final newMerge = MergedClass(
      id: _editingMerge?.id,
      mergedCourseCode: mergedCode,
      mergedCourseTitle: _courseTitleController.text,
      credit: credit,
      batchIds: _selectedBatches.map((b) => b.id!).toList(),
      batchNames: _selectedBatches.map((b) => '${b.departmentName} Batch ${b.batchNo}').toList(),
      teacherId: _selectedTeacher?.id,
      teacherName: _selectedTeacher?.name,
      roomId: _selectedRoom?.id,
      roomNo: _selectedRoom?.roomNo,
      day: _selectedDay,
      timeSlot: _selectedSlot,
      startTime: _timeSlots[_selectedSlot - 1]['start'] as String,
      endTime: _timeSlots[_selectedSlot - 1]['end'] as String,
    );

    // Get time display safely
    String timeDisplay = '';
    if (_selectedSlot >= 1 && _selectedSlot <= _timeSlots.length) {
      timeDisplay = _timeSlots[_selectedSlot - 1]['time'] as String;
    } else {
      timeDisplay = 'Invalid Slot';
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_editingMerge != null ? 'Merge Updated' : 'Merge Created'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '✅ $_selectedDay $timeDisplay',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '📚 ${newMerge.mergedCourseCode}',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '👥 ${newMerge.batchNames.join(' + ')}',
                    style: const TextStyle(fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '🏫 ${_selectedRoom?.roomNo ?? 'TBA'} ${_selectedTeacher?.shortName ?? 'TBA'}',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);

              setState(() {
                if (_editingMerge != null) {
                  // Update existing merge
                  final index = _existingMerges.indexWhere((m) => m.id == _editingMerge!.id);
                  if (index != -1) {
                    _existingMerges[index] = newMerge;
                  }
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Merge updated successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } else {
                  // Add new merge
                  _existingMerges.add(newMerge);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Merge created successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              });

              _clearForm();
            },
            child: const Text('OK'),
          ),
          if (_editingMerge == null)
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                // Continue editing
              },
              child: const Text('Edit More'),
            ),
        ],
      ),
    );
  }

  String _getMergedCourseDisplay() {
    if (_selectedBatches.isEmpty) return '';

    List<String> displays = [];
    for (int i = 0; i < _selectedBatches.length; i++) {
      final batch = _selectedBatches[i];
      String code = _courseCodeControllers.length > i
          ? _courseCodeControllers[i].text
          : '';
      String deptCode = batch.departmentName?.substring(0, 3).toUpperCase() ?? 'XXX';
      displays.add('$deptCode-${code.isEmpty ? 'XXX' : code}');
    }
    return displays.join(' + ');
  }

  String _getManualMergedCode() {
    if (_selectedBatches.isEmpty) return 'Manual Merge';

    List<String> codes = [];
    for (int i = 0; i < _selectedBatches.length; i++) {
      final batch = _selectedBatches[i];
      String deptCode = batch.departmentName?.substring(0, 3).toUpperCase() ?? 'XXX';
      String courseCode = i < _courseCodeControllers.length
          ? _courseCodeControllers[i].text
          : 'XXX';
      codes.add('$deptCode-${courseCode.isEmpty ? 'XXX' : courseCode}');
    }
    return codes.join(' + ');
  }

  String _getBatchDisplay() {
    if (_selectedBatches.isEmpty) return '';
    return _selectedBatches.map((b) =>
    '${b.departmentName} Batch ${b.batchNo}'
    ).join(' + ');
  }

  void _clearForm() {
    setState(() {
      _selectedBatches.clear();
      _selectedTeacher = null;
      _selectedRoom = null;
      _selectedDay = 'Monday';
      _selectedSlot = 1;
      _courseTitleController.clear();
      _creditController.clear();
      _courseCodeControllers.clear();
      _batchCourseCodes.clear();
      _mergeSuggestions.clear();
      _selectedSuggestion = null;
      _editingMerge = null;
      _selectedFilterDepartment = null;
      _selectedTeacherDepartment = null;
      _selectedRoomFloor = null;
      _selectedRoomDepartment = null;
    });
  }

  List<Batch> _getFilteredBatches(BatchProvider batchProvider) {
    var batches = batchProvider.batches;

    if (_selectedFilterDepartment != null) {
      batches = batches.where((b) =>
      b.departmentId == _selectedFilterDepartment!.id
      ).toList();
    }

    if (_searchQuery.isNotEmpty) {
      batches = batches.where((b) {
        final query = _searchQuery.toLowerCase();
        return b.batchNo.toString().contains(query) ||
            (b.departmentName?.toLowerCase().contains(query) ?? false);
      }).toList();
    }

    batches = batches.where((b) => !_selectedBatches.contains(b)).toList();

    return batches;
  }

  List<Teacher> _getFilteredTeachers(TeacherProvider teacherProvider) {
    var teachers = teacherProvider.teachers;

    if (_selectedTeacherDepartment != null) {
      teachers = teachers.where((t) =>
      t.departmentId == _selectedTeacherDepartment!.id
      ).toList();
    }

    return teachers;
  }

  List<Room> _getFilteredRooms(RoomProvider roomProvider) {
    var rooms = roomProvider.rooms;

    if (_selectedRoomFloor != null) {
      rooms = rooms.where((r) => r.floor == _selectedRoomFloor).toList();
    }

    if (_selectedRoomDepartment != null) {
      rooms = rooms.where((r) => r.departmentId == _selectedRoomDepartment!.id).toList();
    }

    return rooms;
  }

  void _findMergeSuggestions() {
    final courseProvider = Provider.of<CourseProvider>(context, listen: false);
    _mergeSuggestions.clear();

    // Group by course code
    Map<String, List<Course>> codeGroups = {};
    // Group by course title
    Map<String, List<Course>> titleGroups = {};

    for (var batch in _selectedBatches) {
      final batchCourses = courseProvider.getCoursesByBatch(batch.id!);
      for (var course in batchCourses) {
        // Group by code
        if (!codeGroups.containsKey(course.code)) {
          codeGroups[course.code] = [];
        }
        codeGroups[course.code]!.add(course);

        // Group by title
        if (!titleGroups.containsKey(course.title)) {
          titleGroups[course.title] = [];
        }
        titleGroups[course.title]!.add(course);
      }
    }

    // Add code-based suggestions
    codeGroups.forEach((code, courses) {
      if (courses.length > 1) {
        _mergeSuggestions.add({
          'type': 'code',
          'value': code,
          'title': courses.first.title,
          'credit': courses.first.credit,
          'batches': courses.map((c) => c.batchId).toList(),
          'courses': courses,
        });
      }
    });

    // Add title-based suggestions
    titleGroups.forEach((title, courses) {
      if (courses.length > 1 && !_mergeSuggestions.any((s) => s['title'] == title)) {
        _mergeSuggestions.add({
          'type': 'title',
          'value': title,
          'title': title,
          'credit': courses.first.credit,
          'batches': courses.map((c) => c.batchId).toList(),
          'courses': courses,
        });
      }
    });

    setState(() {});
  }

  void _showAutoMergeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Auto Merge Suggestions'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _mergeSuggestions.length,
            itemBuilder: (context, index) {
              final suggestion = _mergeSuggestions[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: suggestion['type'] == 'code' ? Colors.blue : Colors.green,
                  child: Text(suggestion['type'] == 'code' ? 'C' : 'T'),
                ),
                title: Text(suggestion['value']),
                subtitle: Text('${suggestion['title']} (${suggestion['credit']} cr)'),
                trailing: Text('${suggestion['batches'].length} batches'),
                onTap: () {
                  setState(() {
                    _selectedSuggestion = suggestion;
                    _courseTitleController.text = suggestion['title'];
                    _creditController.text = suggestion['credit'].toString();
                  });
                  Navigator.pop(context);
                },
              );
            },
          ),
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

  void _showBatchEditDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Batches'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Current Selected Batches:'),
              const SizedBox(height: 8),
              ..._selectedBatches.map((batch) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 4),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text('${batch.departmentName} Batch ${batch.batchNo}'),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.red, size: 16),
                        onPressed: () {
                          setState(() {
                            _selectedBatches.remove(batch);
                          });
                          Navigator.pop(context);
                          _showBatchEditDialog();
                        },
                      ),
                    ],
                  ),
                );
              }).toList(),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showCourseEditDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Course'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _courseTitleController,
              decoration: const InputDecoration(
                labelText: 'Course Title',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _creditController,
              decoration: const InputDecoration(
                labelText: 'Credit',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
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
              setState(() {});
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showTimeEditDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Time'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              value: _selectedDay,
              decoration: const InputDecoration(labelText: 'Day'),
              items: _days.map((String day) {
                return DropdownMenuItem<String>(
                  value: day,
                  child: Text(day),
                );
              }).toList(),
              onChanged: (String? value) {
                setState(() {
                  _selectedDay = value!;
                });
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              value: _selectedSlot,
              decoration: const InputDecoration(labelText: 'Slot'),
              items: _timeSlots.map<DropdownMenuItem<int>>((Map<String, dynamic> slot) {
                return DropdownMenuItem<int>(
                  value: slot['slot'] as int,
                  child: Text('Slot ${slot['slot']}'),
                );
              }).toList(),
              onChanged: (int? value) {
                setState(() {
                  _selectedSlot = value!;
                });
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  // ============== UI BUILD METHODS ==============

  @override
  Widget build(BuildContext context) {
    final deptProvider = Provider.of<DepartmentProvider>(context);
    final batchProvider = Provider.of<BatchProvider>(context);
    final teacherProvider = Provider.of<TeacherProvider>(context);
    final roomProvider = Provider.of<RoomProvider>(context);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Merge Sections'),
          backgroundColor: const Color(0xFF1976D2),
          foregroundColor: Colors.white,
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.merge_type), text: 'Create Merge'),
              Tab(icon: Icon(Icons.list), text: 'Existing Merges'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Create Merge Tab
            _buildCreateMergeTab(deptProvider, batchProvider, teacherProvider, roomProvider),

            // Existing Merges Tab
            _buildExistingMergesTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildCreateMergeTab(
      DepartmentProvider deptProvider,
      BatchProvider batchProvider,
      TeacherProvider teacherProvider,
      RoomProvider roomProvider,
      ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildMergeTypeSelector(),
          const SizedBox(height: 16),
          _buildDepartmentFilter(deptProvider),
          const SizedBox(height: 16),
          _buildBatchSelectionSection(batchProvider),
          const SizedBox(height: 20),
          if (_selectedBatches.isNotEmpty) _buildSelectedBatchesCard(),
          const SizedBox(height: 20),
          if (_isAutoMerge && _mergeSuggestions.isNotEmpty) _buildAutoMergeSuggestions(),
          const SizedBox(height: 20),
          if (_selectedBatches.isNotEmpty && !_isAutoMerge) _buildManualCourseCodeSection(),
          const SizedBox(height: 20),
          _buildCourseDetailsSection(),
          const SizedBox(height: 20),
          if (_selectedBatches.isNotEmpty && _courseTitleController.text.isNotEmpty)
            _buildPreviewSection(),
          const SizedBox(height: 20),
          _buildTeacherSection(teacherProvider, deptProvider),
          const SizedBox(height: 20),
          _buildRoomSection(roomProvider, deptProvider),
          const SizedBox(height: 20),
          _buildTimeSlotSection(),
          const SizedBox(height: 30),
          _buildMergeButton(),
          const SizedBox(height: 20),
          if (_selectedBatches.isNotEmpty) _buildEditOptions(),
        ],
      ),
    );
  }

  Widget _buildExistingMergesTab() {
    return _existingMerges.isEmpty
        ? Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.merge_type, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No merges yet',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first merge',
            style: TextStyle(color: Colors.grey[500]),
          ),
        ],
      ),
    )
        : ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _existingMerges.length,
      itemBuilder: (context, index) {
        final merge = _existingMerges[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.blue,
              child: Text(
                '${index + 1}',
                style: const TextStyle(color: Colors.white),
              ),
            ),
            title: Text(
              merge.mergedCourseCode,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(merge.mergedCourseTitle),
                Text(
                  merge.batchNames.join(' + '),
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  onPressed: () => _editMerge(merge),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _deleteMerge(merge),
                ),
              ],
            ),
            onTap: () => _editMerge(merge),
          ),
        );
      },
    );
  }

  Widget _buildMergeTypeSelector() {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Merge Type',
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
                  child: _buildMergeTypeChip(
                    label: 'Auto Merge',
                    icon: Icons.auto_awesome,
                    isSelected: _isAutoMerge,
                    onTap: () {
                      setState(() {
                        _isAutoMerge = true;
                        _findMergeSuggestions();
                      });
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMergeTypeChip(
                    label: 'Manual Merge',
                    icon: Icons.edit,
                    isSelected: !_isAutoMerge,
                    onTap: () {
                      setState(() {
                        _isAutoMerge = false;
                        _mergeSuggestions.clear();
                      });
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMergeTypeChip({
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
            Icon(
              icon,
              color: isSelected ? Colors.white : Colors.grey[700],
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey[700],
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDepartmentFilter(DepartmentProvider deptProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Filter Batches by Department',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1976D2),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButtonFormField<Department>(
            value: _selectedFilterDepartment,
            decoration: const InputDecoration(
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              border: InputBorder.none,
              prefixIcon: Icon(Icons.filter_alt, color: Color(0xFF1976D2)),
            ),
            hint: const Text('All Departments'),
            items: [
              const DropdownMenuItem<Department>(
                value: null,
                child: Text('All Departments'),
              ),
              ...deptProvider.departments.map((dept) {
                return DropdownMenuItem<Department>(
                  value: dept,
                  child: Text('${dept.name} (${dept.code})'),
                );
              }),
            ],
            onChanged: (dept) {
              setState(() {
                _selectedFilterDepartment = dept;
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBatchSelectionSection(BatchProvider batchProvider) {
    final filteredBatches = _getFilteredBatches(batchProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Available Batches (${filteredBatches.length})',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1976D2),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _selectedBatches.length == 3 ? Colors.red : Colors.blue,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${_selectedBatches.length}/3 Selected',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        filteredBatches.isEmpty
            ? Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              _selectedBatches.length >= 3
                  ? 'Maximum 3 batches selected'
                  : 'No batches available',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
        )
            : GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 1.5,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: filteredBatches.length,
          itemBuilder: (context, index) {
            final batch = filteredBatches[index];
            return _buildBatchCard(batch);
          },
        ),
      ],
    );
  }

  Widget _buildBatchCard(Batch batch) {
    final canSelect = _selectedBatches.length < 3;

    return InkWell(
      onTap: canSelect ? () {
        setState(() {
          _selectedBatches.add(batch);
          if (_isAutoMerge) {
            _findMergeSuggestions();
          } else {
            final controller = TextEditingController();
            _courseCodeControllers.add(controller);
          }
        });
      } : null,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: canSelect
                ? [const Color(0xFF1976D2), const Color(0xFF64B5F6)]
                : [Colors.grey[400]!, Colors.grey[300]!],
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: canSelect ? Colors.blue.withOpacity(0.3) : Colors.grey.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              batch.batchNo.toString(),
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              batch.departmentName ?? 'Unknown',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.white70,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                batch.programType,
                style: const TextStyle(
                  fontSize: 8,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedBatchesCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.green, Colors.lightGreen],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Selected Batches',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_selectedBatches.length} Selected',
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ..._selectedBatches.map((batch) {
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${batch.departmentName} Batch ${batch.batchNo}',
                          style: const TextStyle(color: Colors.white),
                        ),
                        if (!_isAutoMerge && _courseCodeControllers.length > _selectedBatches.indexOf(batch))
                          Text(
                            'Code: ${_courseCodeControllers[_selectedBatches.indexOf(batch)].text}',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 10,
                            ),
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white, size: 16),
                    onPressed: () {
                      setState(() {
                        final index = _selectedBatches.indexOf(batch);
                        _selectedBatches.remove(batch);
                        if (!_isAutoMerge && index < _courseCodeControllers.length) {
                          _courseCodeControllers.removeAt(index);
                        }
                        if (_isAutoMerge) {
                          _findMergeSuggestions();
                        }
                      });
                    },
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildAutoMergeSuggestions() {
    return Card(
      color: Colors.blue[50],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.auto_awesome, color: Color(0xFF1976D2)),
                const SizedBox(width: 8),
                const Text(
                  'Auto Merge Suggestions',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1976D2),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ..._mergeSuggestions.map((suggestion) {
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _selectedSuggestion == suggestion
                        ? Colors.green
                        : Colors.grey.shade300,
                    width: _selectedSuggestion == suggestion ? 2 : 1,
                  ),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: suggestion['type'] == 'code' ? Colors.blue : Colors.green,
                    child: Text(
                      suggestion['type'] == 'code' ? 'C' : 'T',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  title: Text(suggestion['value']),
                  subtitle: Text('${suggestion['title']} (${suggestion['credit']} cr)'),
                  trailing: Text('${suggestion['batches'].length} batches'),
                  onTap: () {
                    setState(() {
                      _selectedSuggestion = suggestion;
                      _courseTitleController.text = suggestion['title'];
                      _creditController.text = suggestion['credit'].toString();
                    });
                  },
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildManualCourseCodeSection() {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Course Codes (Per Batch)',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1976D2),
              ),
            ),
            const SizedBox(height: 12),
            ..._selectedBatches.asMap().entries.map((entry) {
              final index = entry.key;
              final batch = entry.value;
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.blue[100],
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1976D2),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: index < _courseCodeControllers.length
                            ? _courseCodeControllers[index]
                            : null,
                        decoration: InputDecoration(
                          labelText: '${batch.departmentName} Batch ${batch.batchNo}',
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.code, color: Color(0xFF1976D2)),
                        ),
                        onChanged: (value) {
                          setState(() {});
                        },
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildCourseDetailsSection() {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Common Course Details',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1976D2),
              ),
            ),
            const SizedBox(height: 12),

            // Course Title
            TextFormField(
              controller: _courseTitleController,
              decoration: InputDecoration(
                labelText: 'Course Title',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.title, color: Color(0xFF1976D2)),
                suffixIcon: _isAutoMerge && _mergeSuggestions.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.auto_awesome, color: Colors.amber),
                  onPressed: _showAutoMergeDialog,
                )
                    : null,
              ),
            ),
            const SizedBox(height: 12),

            // Credit
            TextFormField(
              controller: _creditController,
              decoration: const InputDecoration(
                labelText: 'Credit Hours',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.star, color: Color(0xFF1976D2)),
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewSection() {
    return Card(
      color: Colors.blue[50],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Preview (রুটিনে যেভাবে দেখাবে)',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1976D2),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$_selectedDay ${_timeSlots[_selectedSlot-1]['time']}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _isAutoMerge
                        ? _getMergedCourseDisplay()
                        : _getManualMergedCode(),
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      color: Colors.blue,
                    ),
                  ),
                  Text(
                    '($_getBatchDisplay())',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_selectedRoom?.roomNo ?? 'TBA'} ${_selectedTeacher?.shortName ?? 'TBA'}',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTeacherSection(TeacherProvider teacherProvider, DepartmentProvider deptProvider) {
    final filteredTeachers = _getFilteredTeachers(teacherProvider);

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Assign Teacher',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1976D2),
              ),
            ),
            const SizedBox(height: 12),

            // Department Filter for Teachers
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              child: DropdownButtonFormField<Department>(
                value: _selectedTeacherDepartment,
                decoration: const InputDecoration(
                  labelText: 'Filter Teachers by Department',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.filter_alt, color: Color(0xFF1976D2)),
                ),
                hint: const Text('All Departments'),
                items: [
                  const DropdownMenuItem<Department>(
                    value: null,
                    child: Text('All Departments'),
                  ),
                  ...deptProvider.departments.map((dept) {
                    return DropdownMenuItem<Department>(
                      value: dept,
                      child: Text('${dept.name} (${dept.code})'),
                    );
                  }),
                ],
                onChanged: (dept) {
                  setState(() {
                    _selectedTeacherDepartment = dept;
                  });
                },
              ),
            ),

            // Teacher Selection
            _selectedTeacher == null
                ? Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                children: [
                  const Icon(Icons.person_add, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<Teacher>(
                        hint: const Text('Select Teacher'),
                        isExpanded: true,
                        items: [
                          const DropdownMenuItem<Teacher>(
                            value: null,
                            child: Text('None'),
                          ),
                          ...filteredTeachers.map((teacher) {
                            return DropdownMenuItem<Teacher>(
                              value: teacher,
                              child: Text('${teacher.name} (${teacher.shortName})'),
                            );
                          }),
                        ],
                        onChanged: (teacher) {
                          setState(() {
                            _selectedTeacher = teacher;
                          });
                        },
                      ),
                    ),
                  ),
                ],
              ),
            )
                : Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: Colors.green,
                    child: Text(
                      _selectedTeacher!.shortName.substring(0, 1),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _selectedTeacher!.name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          _selectedTeacher!.shortName,
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.red),
                    onPressed: () {
                      setState(() {
                        _selectedTeacher = null;
                      });
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoomSection(RoomProvider roomProvider, DepartmentProvider deptProvider) {
    final filteredRooms = _getFilteredRooms(roomProvider);

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Assign Room',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1976D2),
              ),
            ),
            const SizedBox(height: 12),

            // Floor Filter
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              child: DropdownButtonFormField<int>(
                value: _selectedRoomFloor,
                decoration: const InputDecoration(
                  labelText: 'Filter by Floor',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.filter_alt, color: Color(0xFF1976D2)),
                ),
                hint: const Text('All Floors'),
                items: [
                  const DropdownMenuItem<int>(
                    value: null,
                    child: Text('All Floors'),
                  ),
                  ..._floors.map((floor) {
                    return DropdownMenuItem<int>(
                      value: floor,
                      child: Text('Floor $floor'),
                    );
                  }),
                ],
                onChanged: (floor) {
                  setState(() {
                    _selectedRoomFloor = floor;
                  });
                },
              ),
            ),

            // Department Filter for Rooms
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              child: DropdownButtonFormField<Department>(
                value: _selectedRoomDepartment,
                decoration: const InputDecoration(
                  labelText: 'Filter by Department',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.business, color: Color(0xFF1976D2)),
                ),
                hint: const Text('All Departments'),
                items: [
                  const DropdownMenuItem<Department>(
                    value: null,
                    child: Text('All Departments'),
                  ),
                  ...deptProvider.departments.map((dept) {
                    return DropdownMenuItem<Department>(
                      value: dept,
                      child: Text('${dept.name} (${dept.code})'),
                    );
                  }),
                ],
                onChanged: (dept) {
                  setState(() {
                    _selectedRoomDepartment = dept;
                  });
                },
              ),
            ),

            // Room Selection
            _selectedRoom == null
                ? Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                children: [
                  const Icon(Icons.meeting_room, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<Room>(
                        hint: const Text('Select Room'),
                        isExpanded: true,
                        items: [
                          const DropdownMenuItem<Room>(
                            value: null,
                            child: Text('None'),
                          ),
                          ...filteredRooms.map((room) {
                            return DropdownMenuItem<Room>(
                              value: room,
                              child: Text('${room.roomNo} (F${room.floor})'),
                            );
                          }),
                        ],
                        onChanged: (room) {
                          setState(() {
                            _selectedRoom = room;
                          });
                        },
                      ),
                    ),
                  ),
                ],
              ),
            )
                : Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(
                      color: Colors.orange,
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Icon(Icons.meeting_room, color: Colors.white, size: 16),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _selectedRoom!.roomNo,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Floor ${_selectedRoom!.floor} • Cap: ${_selectedRoom!.capacity}',
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.red),
                    onPressed: () {
                      setState(() {
                        _selectedRoom = null;
                      });
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeSlotSection() {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Time Slot',
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
                  child: DropdownButtonFormField<String>(
                    value: _selectedDay,
                    decoration: const InputDecoration(
                      labelText: 'Day',
                      border: OutlineInputBorder(),
                    ),
                    items: _days.map((String day) {
                      return DropdownMenuItem<String>(
                        value: day,
                        child: Text(day),
                      );
                    }).toList(),
                    onChanged: (String? value) {
                      setState(() {
                        _selectedDay = value!;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<int>(
                    value: _selectedSlot,
                    decoration: const InputDecoration(
                      labelText: 'Slot',
                      border: OutlineInputBorder(),
                    ),
                    items: _timeSlots.map<DropdownMenuItem<int>>((Map<String, dynamic> slot) {
                      return DropdownMenuItem<int>(
                        value: slot['slot'] as int,
                        child: Text('Slot ${slot['slot']}'),
                      );
                    }).toList(),
                    onChanged: (int? value) {
                      setState(() {
                        _selectedSlot = value!;
                      });
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditOptions() {
    return Card(
      color: Colors.amber[50],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.edit, color: Colors.amber),
                const SizedBox(width: 8),
                const Text(
                  'Edit Options',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.amber,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildEditChip(
                  label: 'Edit Batches',
                  icon: Icons.group,
                  onTap: _showBatchEditDialog,
                ),
                _buildEditChip(
                  label: 'Edit Course',
                  icon: Icons.book,
                  onTap: _showCourseEditDialog,
                ),
                _buildEditChip(
                  label: 'Edit Teacher',
                  icon: Icons.person,
                  onTap: () {
                    setState(() {
                      _selectedTeacher = null;
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Select new teacher'),
                        backgroundColor: Colors.blue,
                      ),
                    );
                  },
                ),
                _buildEditChip(
                  label: 'Edit Room',
                  icon: Icons.meeting_room,
                  onTap: () {
                    setState(() {
                      _selectedRoom = null;
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Select new room'),
                        backgroundColor: Colors.blue,
                      ),
                    );
                  },
                ),
                _buildEditChip(
                  label: 'Edit Time',
                  icon: Icons.access_time,
                  onTap: _showTimeEditDialog,
                ),
                _buildEditChip(
                  label: 'Clear All',
                  icon: Icons.clear_all,
                  onTap: _clearForm,
                  color: Colors.red,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditChip({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
    Color color = Colors.amber,
  }) {
    return ActionChip(
      avatar: Icon(icon, size: 16, color: color),
      label: Text(label, style: TextStyle(fontSize: 12, color: color)),
      onPressed: onTap,
      backgroundColor: color.withOpacity(0.1),
    );
  }

  Widget _buildMergeButton() {
    final isValid = _selectedBatches.isNotEmpty &&
        _courseTitleController.text.isNotEmpty &&
        _creditController.text.isNotEmpty;

    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: isValid ? _createMerge : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1976D2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          '${_editingMerge != null ? 'Update' : 'Create'} Merge (${_selectedBatches.length} batches)',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}