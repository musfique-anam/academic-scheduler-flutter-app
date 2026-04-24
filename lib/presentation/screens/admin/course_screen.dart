import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/course_provider.dart';
import '../../../providers/batch_provider.dart';
import '../../../providers/teacher_provider.dart';
import '../../../providers/department_provider.dart';
import '../../../providers/dashboard_provider.dart';
import '../../../data/models/course_model.dart';
import '../../../data/models/batch_model.dart';
import '../../../data/models/teacher_model.dart';
import '../../../data/models/department_model.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/error_widget.dart';

class CourseScreen extends StatefulWidget {
  const CourseScreen({super.key});

  @override
  State<CourseScreen> createState() => _CourseScreenState();
}

class _CourseScreenState extends State<CourseScreen> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _creditController = TextEditingController();

  // Filter variables
  Department? _selectedDepartment;
  Batch? _selectedBatch;
  String _selectedType = 'All';
  Teacher? _selectedTeacher;
  String _selectedStatus = 'All'; // 'All', 'Assigned', 'Unassigned'
  String _sortBy = 'code'; // 'code' or 'credit'
  bool _sortAscending = true;

  // Course edit variables
  Course? _selectedCourse;
  bool _isEditMode = false;

  final List<String> _courseTypes = ['All', 'Theory', 'Lab'];
  final List<String> _courseStatus = ['All', 'Assigned', 'Unassigned'];
  final List<String> _sortOptions = ['Course Code', 'Credit'];

  List<Batch> _allBatches = [];
  List<Batch> _filteredBatches = [];
  List<Teacher> _filteredTeachers = [];

  @override
  void initState() {
    super.initState();
    _loadData();

    _searchController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _codeController.dispose();
    _titleController.dispose();
    _creditController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final courseProvider = Provider.of<CourseProvider>(context, listen: false);
    final batchProvider = Provider.of<BatchProvider>(context, listen: false);
    final teacherProvider = Provider.of<TeacherProvider>(context, listen: false);
    final deptProvider = Provider.of<DepartmentProvider>(context, listen: false);

    await Future.wait([
      courseProvider.loadCourses(),
      batchProvider.loadBatches(),
      teacherProvider.loadTeachers(),
      deptProvider.loadDepartments(),
      courseProvider.loadBatches(),
      courseProvider.loadTeachers(),
    ]);

    _allBatches = batchProvider.batches;
    _filteredBatches = List.from(_allBatches);
    setState(() {});
  }

  void _filterBatchesByDepartment(int? departmentId) {
    if (departmentId == null) {
      _filteredBatches = List.from(_allBatches);
    } else {
      _filteredBatches = _allBatches
          .where((batch) => batch.departmentId == departmentId)
          .toList();
    }
    setState(() {});
  }

  void _filterTeachersByDepartment(int? departmentId) {
    final teacherProvider = Provider.of<TeacherProvider>(context, listen: false);

    if (departmentId == null) {
      _filteredTeachers = List.from(teacherProvider.teachers);
    } else {
      _filteredTeachers = teacherProvider.teachers
          .where((teacher) => teacher.departmentId == departmentId)
          .toList();
    }
    setState(() {});
  }

  void _clearFilters() {
    setState(() {
      _selectedDepartment = null;
      _selectedBatch = null;
      _selectedType = 'All';
      _selectedTeacher = null;
      _selectedStatus = 'All';
      _searchController.clear();
      _filteredBatches = List.from(_allBatches);
      _filteredTeachers = [];
    });

    final courseProvider = Provider.of<CourseProvider>(context, listen: false);
    courseProvider.clearFilters();
  }

  void _showAddEditDialog({Course? course}) {
    _isEditMode = course != null;
    _selectedCourse = course;

    if (_isEditMode) {
      print('✏️ Editing course: ${course!.id} - ${course.code}');
      _codeController.text = course.code;
      _titleController.text = course.title;
      _creditController.text = course.credit.toString();
      _selectedType = course.type;

      // Find batch
      final batch = _allBatches.firstWhere(
            (b) => b.id == course.batchId,
        orElse: () => Batch(
          id: course.batchId,
          departmentId: 0,
          batchNo: 0,
          programType: '',
          totalStudents: 0,
        ),
      );

      _selectedBatch = batch.id != 0 ? batch : null;

      if (batch.id != 0) {
        // Find department
        final deptProvider = Provider.of<DepartmentProvider>(context, listen: false);
        final dept = deptProvider.departments.firstWhere(
              (d) => d.id == batch.departmentId,
          orElse: () => Department(id: batch.departmentId, name: '', code: ''),
        );

        _selectedDepartment = dept.id != 0 ? dept : null;
        _filterBatchesByDepartment(dept.id);
        _filterTeachersByDepartment(dept.id);
      }

      // Load teacher info
      if (course.teacherId != null) {
        final teacherProvider = Provider.of<TeacherProvider>(context, listen: false);
        _selectedTeacher = teacherProvider.teachers.firstWhere(
              (t) => t.id == course.teacherId,
          orElse: () => Teacher(
            id: course.teacherId!,
            name: '',
            shortName: '',
            username: '',
            password: '',
            phone: '',
            departmentId: 0,
          ),
        );
      } else {
        _selectedTeacher = null;
      }
    } else {
      _codeController.clear();
      _titleController.clear();
      _creditController.clear();
      _selectedType = 'Theory';
      _selectedDepartment = null;
      _selectedBatch = null;
      _selectedTeacher = null;
      _filteredBatches = List.from(_allBatches);
      _filteredTeachers = [];
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(_isEditMode ? 'Edit Course' : 'Add New Course'),
              content: Container(
                width: MediaQuery.of(context).size.width * 0.9,
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.7,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Course Information',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const Divider(),

                      // Department Dropdown (Optional)
                      Consumer<DepartmentProvider>(
                        builder: (context, deptProvider, child) {
                          return DropdownButtonFormField<Department>(
                            value: _selectedDepartment,
                            decoration: const InputDecoration(
                              labelText: 'Department (Optional)',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.business),
                            ),
                            hint: const Text('Select Department'),
                            items: [
                              const DropdownMenuItem(
                                value: null,
                                child: Text('None'),
                              ),
                              ...deptProvider.departments.map((dept) {
                                return DropdownMenuItem(
                                  value: dept,
                                  child: Text('${dept.name} (${dept.code})'),
                                );
                              }),
                            ],
                            onChanged: (dept) {
                              setState(() {
                                _selectedDepartment = dept;
                                _selectedBatch = null;
                                if (dept != null) {
                                  _filteredBatches = _allBatches
                                      .where((b) => b.departmentId == dept.id)
                                      .toList();
                                } else {
                                  _filteredBatches = List.from(_allBatches);
                                }
                              });
                            },
                          );
                        },
                      ),
                      const SizedBox(height: 16),

                      // Batch Dropdown
                      DropdownButtonFormField<Batch>(
                        value: _selectedBatch,
                        decoration: const InputDecoration(
                          labelText: 'Batch *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.group),
                        ),
                        hint: const Text('Select Batch'),
                        items: (_selectedDepartment == null
                            ? _allBatches
                            : _filteredBatches).map((batch) {
                          return DropdownMenuItem(
                            value: batch,
                            child: Text('Batch ${batch.batchNo} (${batch.programType})'),
                          );
                        }).toList(),
                        onChanged: (batch) {
                          setState(() {
                            _selectedBatch = batch;
                          });
                        },
                      ),
                      const SizedBox(height: 16),

                      // Course Code
                      TextFormField(
                        controller: _codeController,
                        decoration: const InputDecoration(
                          labelText: 'Course Code *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.code),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Course Title
                      TextFormField(
                        controller: _titleController,
                        decoration: const InputDecoration(
                          labelText: 'Course Title *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.title),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Credit
                      TextFormField(
                        controller: _creditController,
                        decoration: const InputDecoration(
                          labelText: 'Credit *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.star),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 16),

                      // Course Type
                      DropdownButtonFormField<String>(
                        value: _selectedType,
                        decoration: const InputDecoration(
                          labelText: 'Course Type *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.category),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'Theory', child: Text('Theory')),
                          DropdownMenuItem(value: 'Lab', child: Text('Lab')),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedType = value!;
                          });
                        },
                      ),
                      const SizedBox(height: 16),

                      // Teacher Assignment
                      Consumer<TeacherProvider>(
                        builder: (context, teacherProvider, child) {
                          List<Teacher> teachersToShow = _selectedDepartment != null
                              ? teacherProvider.teachers
                              .where((t) => t.departmentId == _selectedDepartment!.id)
                              .toList()
                              : teacherProvider.teachers;

                          return DropdownButtonFormField<Teacher>(
                            value: _selectedTeacher,
                            decoration: const InputDecoration(
                              labelText: 'Assign Teacher (Optional)',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.person),
                            ),
                            hint: const Text('Select Teacher'),
                            items: [
                              const DropdownMenuItem(
                                value: null,
                                child: Text('None'),
                              ),
                              ...teachersToShow.map((teacher) {
                                return DropdownMenuItem(
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
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () => _saveCourse(dialogContext),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1976D2),
                    foregroundColor: Colors.white,
                  ),
                  child: Text(_isEditMode ? 'Update Course' : 'Add Course'),
                ),
              ],
            );
          },
        );
      },
    ).then((_) {
      _loadData();
    });
  }

  Future<void> _saveCourse(BuildContext dialogContext) async {
    if (_selectedBatch == null) {
      _showError('Please select batch');
      return;
    }

    if (_codeController.text.isEmpty) {
      _showError('Please enter course code');
      return;
    }

    if (_titleController.text.isEmpty) {
      _showError('Please enter course title');
      return;
    }

    double? credit = double.tryParse(_creditController.text);
    if (credit == null || credit <= 0) {
      _showError('Please enter valid credit');
      return;
    }

    final courseProvider = Provider.of<CourseProvider>(context, listen: false);
    final dashboardProvider = Provider.of<DashboardProvider>(context, listen: false);

    Course course = Course(
      id: _isEditMode ? _selectedCourse!.id : null,
      code: _codeController.text.trim().toUpperCase(),
      title: _titleController.text.trim(),
      credit: credit,
      type: _selectedType,
      batchId: _selectedBatch!.id!,
      teacherId: _selectedTeacher?.id,
    );

    bool success;
    if (_isEditMode) {
      print('✏️ Updating course: ${course.id} - ${course.code}');
      success = await courseProvider.updateCourse(course);
    } else {
      print('➕ Adding new course: ${course.code}');
      success = await courseProvider.addCourse(course);
    }

    if (success) {
      Navigator.pop(dialogContext);
      await dashboardProvider.refreshDashboard();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditMode ? 'Course updated' : 'Course added'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  Future<void> _deleteCourse(Course course) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Course'),
        content: Text('Delete ${course.code} - ${course.title}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final courseProvider = Provider.of<CourseProvider>(context, listen: false);
              bool success = await courseProvider.deleteCourse(course.id!);
              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Course deleted'), backgroundColor: Colors.green),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  List<Course> _getFilteredCourses(CourseProvider courseProvider) {
    List<Course> filtered = List.from(courseProvider.courses);

    // Search filter
    if (_searchController.text.isNotEmpty) {
      final query = _searchController.text.toLowerCase();
      filtered = filtered.where((c) =>
      c.code.toLowerCase().contains(query) ||
          c.title.toLowerCase().contains(query)
      ).toList();
    }

    // Department filter - FIXED
    if (_selectedDepartment != null) {
      // Get all batches in this department
      final deptBatchIds = _allBatches
          .where((b) => b.departmentId == _selectedDepartment!.id)
          .map((b) => b.id)
          .toSet();

      filtered = filtered.where((c) =>
          deptBatchIds.contains(c.batchId)
      ).toList();
    }

    // Batch filter
    if (_selectedBatch != null) {
      filtered = filtered.where((c) => c.batchId == _selectedBatch!.id).toList();
    }

    // Type filter
    if (_selectedType != 'All') {
      filtered = filtered.where((c) => c.type == _selectedType).toList();
    }

    // Teacher filter
    if (_selectedTeacher != null) {
      filtered = filtered.where((c) => c.teacherId == _selectedTeacher!.id).toList();
    }

    // Status filter
    if (_selectedStatus == 'Assigned') {
      filtered = filtered.where((c) => c.teacherId != null).toList();
    } else if (_selectedStatus == 'Unassigned') {
      filtered = filtered.where((c) => c.teacherId == null).toList();
    }

    // Sort
    if (_sortBy == 'code') {
      filtered.sort((a, b) => _sortAscending
          ? a.code.compareTo(b.code)
          : b.code.compareTo(a.code));
    } else {
      filtered.sort((a, b) => _sortAscending
          ? a.credit.compareTo(b.credit)
          : b.credit.compareTo(a.credit));
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Course Management'),
        backgroundColor: const Color(0xFF1976D2),
        foregroundColor: Colors.white,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search courses...',
                hintStyle: const TextStyle(color: Colors.white70),
                prefixIcon: const Icon(Icons.search, color: Colors.white),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear, color: Colors.white),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {});
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
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditDialog(),
        backgroundColor: const Color(0xFF1976D2),
        child: const Icon(Icons.add),
      ),
      body: Consumer<CourseProvider>(
        builder: (context, courseProvider, child) {
          if (courseProvider.isLoading) {
            return const LoadingWidget();
          }

          final displayCourses = _getFilteredCourses(courseProvider);

          return Column(
            children: [
              // Filter Bar
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                height: 100,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    _buildFilterChip(
                      label: 'Dept: ${_selectedDepartment?.code ?? 'All'}',
                      icon: Icons.business,
                      color: Colors.blue,
                      isSelected: _selectedDepartment != null,
                      onTap: () => _showDepartmentFilterDialog(),
                      onClear: _selectedDepartment != null
                          ? () {
                        setState(() {
                          _selectedDepartment = null;
                          _selectedBatch = null;
                          _filteredBatches = List.from(_allBatches);
                        });
                      }
                          : null,
                    ),
                    _buildFilterChip(
                      label: _selectedBatch != null
                          ? 'Batch ${_selectedBatch!.batchNo}'
                          : 'Batch: All',
                      icon: Icons.group,
                      color: Colors.orange,
                      isSelected: _selectedBatch != null,
                      onTap: () => _showBatchFilterDialog(),
                      onClear: _selectedBatch != null
                          ? () => setState(() => _selectedBatch = null)
                          : null,
                    ),
                    _buildFilterChip(
                      label: 'Type: $_selectedType',
                      icon: Icons.category,
                      color: Colors.green,
                      isSelected: _selectedType != 'All',
                      onTap: () => _showTypeFilterDialog(),
                      onClear: _selectedType != 'All'
                          ? () => setState(() => _selectedType = 'All')
                          : null,
                    ),
                    _buildFilterChip(
                      label: _selectedTeacher != null
                          ? 'Teacher: ${_selectedTeacher!.shortName}'
                          : 'Teacher: All',
                      icon: Icons.person,
                      color: Colors.purple,
                      isSelected: _selectedTeacher != null,
                      onTap: () => _showTeacherFilterDialog(),
                      onClear: _selectedTeacher != null
                          ? () => setState(() => _selectedTeacher = null)
                          : null,
                    ),
                    _buildFilterChip(
                      label: 'Status: $_selectedStatus',
                      icon: Icons.check_circle,
                      color: Colors.teal,
                      isSelected: _selectedStatus != 'All',
                      onTap: () => _showStatusFilterDialog(),
                      onClear: _selectedStatus != 'All'
                          ? () => setState(() => _selectedStatus = 'All')
                          : null,
                    ),
                    if (_selectedDepartment != null ||
                        _selectedBatch != null ||
                        _selectedType != 'All' ||
                        _selectedTeacher != null ||
                        _selectedStatus != 'All')
                      Container(
                        margin: const EdgeInsets.only(left: 8),
                        child: ActionChip(
                          label: const Text('Clear All'),
                          avatar: const Icon(Icons.clear, size: 16),
                          onPressed: _clearFilters,
                          backgroundColor: Colors.red[100],
                        ),
                      ),
                  ],
                ),
              ),

              // Results and Sort
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('${displayCourses.length} courses'),
                    Row(
                      children: [
                        const Text('Sort:'),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: DropdownButton<String>(
                            value: _sortBy,
                            underline: const SizedBox(),
                            items: const [
                              DropdownMenuItem(value: 'code', child: Text('Code')),
                              DropdownMenuItem(value: 'credit', child: Text('Credit')),
                            ],
                            onChanged: (value) {
                              setState(() => _sortBy = value!);
                            },
                          ),
                        ),
                        IconButton(
                          icon: Icon(_sortAscending ? Icons.arrow_upward : Icons.arrow_downward),
                          onPressed: () => setState(() => _sortAscending = !_sortAscending),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Course List
              Expanded(
                child: displayCourses.isEmpty
                    ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.book, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text('No courses found', style: TextStyle(fontSize: 18)),
                      const SizedBox(height: 8),
                      Text('Try adjusting filters', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                )
                    : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: displayCourses.length,
                  itemBuilder: (context, index) {
                    final course = displayCourses[index];
                    final batch = _allBatches.firstWhere(
                          (b) => b.id == course.batchId,
                      orElse: () => Batch(
                        id: course.batchId,
                        departmentId: 0,
                        batchNo: 0,
                        programType: '',
                        totalStudents: 0,
                      ),
                    );

                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: course.type == 'Theory'
                              ? Colors.blue
                              : Colors.orange,
                          child: Text(
                            course.code.substring(0, 1),
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        title: Text('${course.code} - ${course.title}'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Credit: ${course.credit} | Batch: ${batch.batchNo}'),
                            if (course.teacherName != null)
                              Text('Teacher: ${course.teacherName}',
                                  style: const TextStyle(color: Colors.green)),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () => _showAddEditDialog(course: course),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteCourse(course),
                            ),
                          ],
                        ),
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

  Widget _buildFilterChip({
    required String label,
    required IconData icon,
    required Color color,
    required bool isSelected,
    required VoidCallback onTap,
    VoidCallback? onClear,
  }) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: InputChip(
        label: Text(label),
        avatar: Icon(icon, size: 16, color: isSelected ? Colors.white : color),
        selected: isSelected,
        onPressed: onTap,
        onDeleted: onClear,
        deleteIcon: const Icon(Icons.close, size: 16),
        selectedColor: color,
        backgroundColor: Colors.grey[200],
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : Colors.black87,
          fontSize: 12,
        ),
      ),
    );
  }

  void _showDepartmentFilterDialog() {
    final deptProvider = Provider.of<DepartmentProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Department'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: deptProvider.departments.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return ListTile(
                  title: const Text('All Departments'),
                  leading: const Icon(Icons.business),
                  onTap: () {
                    setState(() {
                      _selectedDepartment = null;
                      _selectedBatch = null;
                      _filteredBatches = List.from(_allBatches);
                    });
                    Navigator.pop(context);
                  },
                );
              }
              final dept = deptProvider.departments[index - 1];
              return ListTile(
                title: Text('${dept.name} (${dept.code})'),
                leading: const Icon(Icons.business),
                onTap: () {
                  setState(() {
                    _selectedDepartment = dept;
                    _selectedBatch = null;
                    _filteredBatches = _allBatches
                        .where((b) => b.departmentId == dept.id)
                        .toList();
                  });
                  Navigator.pop(context);
                },
              );
            },
          ),
        ),
      ),
    );
  }

  void _showBatchFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Batch'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _filteredBatches.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return ListTile(
                  title: const Text('All Batches'),
                  leading: const Icon(Icons.group),
                  onTap: () {
                    setState(() => _selectedBatch = null);
                    Navigator.pop(context);
                  },
                );
              }
              final batch = _filteredBatches[index - 1];
              return ListTile(
                title: Text('Batch ${batch.batchNo} (${batch.programType})'),
                leading: const Icon(Icons.group),
                onTap: () {
                  setState(() => _selectedBatch = batch);
                  Navigator.pop(context);
                },
              );
            },
          ),
        ),
      ),
    );
  }

  void _showTypeFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Type'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('All Types'),
              leading: const Icon(Icons.category),
              onTap: () {
                setState(() => _selectedType = 'All');
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('Theory'),
              leading: const Icon(Icons.menu_book),
              onTap: () {
                setState(() => _selectedType = 'Theory');
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('Lab'),
              leading: const Icon(Icons.science),
              onTap: () {
                setState(() => _selectedType = 'Lab');
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showTeacherFilterDialog() {
    final teacherProvider = Provider.of<TeacherProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Teacher'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: teacherProvider.teachers.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return ListTile(
                  title: const Text('All Teachers'),
                  leading: const Icon(Icons.person),
                  onTap: () {
                    setState(() => _selectedTeacher = null);
                    Navigator.pop(context);
                  },
                );
              }
              final teacher = teacherProvider.teachers[index - 1];
              return ListTile(
                title: Text(teacher.name),
                subtitle: Text(teacher.shortName),
                leading: const Icon(Icons.person),
                onTap: () {
                  setState(() => _selectedTeacher = teacher);
                  Navigator.pop(context);
                },
              );
            },
          ),
        ),
      ),
    );
  }

  void _showStatusFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Status'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('All Courses'),
              leading: const Icon(Icons.check_circle, color: Colors.grey),
              onTap: () {
                setState(() => _selectedStatus = 'All');
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('Assigned'),
              leading: const Icon(Icons.check_circle, color: Colors.green),
              onTap: () {
                setState(() => _selectedStatus = 'Assigned');
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('Unassigned'),
              leading: const Icon(Icons.check_circle, color: Colors.orange),
              onTap: () {
                setState(() => _selectedStatus = 'Unassigned');
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}