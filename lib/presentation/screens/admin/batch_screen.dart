import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/batch_provider.dart';
import '../../../providers/department_provider.dart';
import '../../../providers/dashboard_provider.dart';
import '../../../providers/course_provider.dart';
import '../../../data/models/batch_model.dart';
import '../../../data/models/department_model.dart';
import '../../../data/models/course_model.dart';
import '../../../data/services/database_helper.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/error_widget.dart';

class BatchScreen extends StatefulWidget {
  const BatchScreen({super.key});

  @override
  State<BatchScreen> createState() => _BatchScreenState();
}

class _BatchScreenState extends State<BatchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _batchNoController = TextEditingController();
  final TextEditingController _studentsController = TextEditingController();

  // Course Controllers
  final List<TextEditingController> _courseCodeControllers = [];
  final List<TextEditingController> _courseTitleControllers = [];
  final List<TextEditingController> _courseCreditControllers = [];
  final List<String> _courseTypes = [];
  final List<int?> _courseIds = [];
  final List<bool> _isCourseExpanded = [];

  Department? _selectedDepartment;
  String _selectedProgramType = 'HSC';
  Batch? _selectedBatch;
  bool _isEditMode = false;
  int _courseCount = 0;

  final List<String> _programTypes = ['HSC', 'Diploma'];
  final List<String> _availableCourseTypes = ['Theory', 'Lab'];

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });

    _searchController.addListener(() {
      final provider = Provider.of<BatchProvider>(context, listen: false);
      provider.searchBatches(_searchController.text);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _batchNoController.dispose();
    _studentsController.dispose();
    _disposeCourseControllers();
    super.dispose();
  }

  void _disposeCourseControllers() {
    for (var controller in _courseCodeControllers) {
      controller.dispose();
    }
    for (var controller in _courseTitleControllers) {
      controller.dispose();
    }
    for (var controller in _courseCreditControllers) {
      controller.dispose();
    }
    _courseCodeControllers.clear();
    _courseTitleControllers.clear();
    _courseCreditControllers.clear();
    _courseTypes.clear();
    _courseIds.clear();
    _isCourseExpanded.clear();
  }

  Future<void> _loadData() async {
    final batchProvider = Provider.of<BatchProvider>(context, listen: false);
    final deptProvider = Provider.of<DepartmentProvider>(context, listen: false);
    final courseProvider = Provider.of<CourseProvider>(context, listen: false);

    await Future.wait([
      batchProvider.loadBatches(),
      deptProvider.loadDepartments(),
      batchProvider.loadDepartments(),
      courseProvider.loadCourses(),
    ]);
  }

  void _updateCourseControllers(int count) {
    _disposeCourseControllers();
    _courseCount = count;

    for (int i = 0; i < count; i++) {
      _courseCodeControllers.add(TextEditingController());
      _courseTitleControllers.add(TextEditingController());
      _courseCreditControllers.add(TextEditingController());
      _courseTypes.add('Theory');
      _courseIds.add(null);
      _isCourseExpanded.add(false);
    }
    setState(() {});
  }

  Future<void> _loadCoursesForBatch(int batchId) async {
    final courseProvider = Provider.of<CourseProvider>(context, listen: false);
    final courses = courseProvider.getCoursesByBatch(batchId);

    print('📚 Loading ${courses.length} courses for batch ID: $batchId');

    _updateCourseControllers(courses.length);

    for (int i = 0; i < courses.length; i++) {
      final course = courses[i];
      _courseCodeControllers[i].text = course.code;
      _courseTitleControllers[i].text = course.title;
      _courseCreditControllers[i].text = course.credit.toString();
      _courseTypes[i] = course.type;
      _courseIds[i] = course.id;
    }
    setState(() {});
  }

  void _showAddEditDialog({Batch? batch}) {
    _isEditMode = batch != null;
    _selectedBatch = batch;

    if (_isEditMode) {
      print('✏️ Editing batch: ${batch!.id} - ${batch.batchNo}');
      _batchNoController.text = batch.batchNo.toString();
      _studentsController.text = batch.totalStudents.toString();

      _selectedDepartment = Department(
        id: batch.departmentId,
        name: '',
        code: '',
      );

      _selectedProgramType = batch.programType;
      _loadCoursesForBatch(batch.id!);
    } else {
      _batchNoController.clear();
      _studentsController.clear();
      _selectedDepartment = null;
      _selectedProgramType = 'HSC';
      _updateCourseControllers(0);
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(_isEditMode ? 'Edit Batch' : 'Add New Batch'),
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
                        'Basic Information',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const Divider(),

                      // Department Dropdown
                      Consumer<DepartmentProvider>(
                        builder: (context, deptProvider, child) {
                          if (deptProvider.departments.isEmpty) {
                            return const Center(
                              child: Text('No departments found'),
                            );
                          }

                          Department? selectedDept;
                          if (_selectedDepartment != null) {
                            try {
                              selectedDept = deptProvider.departments.firstWhere(
                                    (dept) => dept.id == _selectedDepartment!.id,
                              );
                            } catch (e) {
                              print('Department not found in list: ${_selectedDepartment!.id}');
                            }
                          }

                          return DropdownButtonFormField<Department>(
                            value: selectedDept,
                            decoration: const InputDecoration(
                              labelText: 'Department *',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.business),
                            ),
                            hint: const Text('Select Department'),
                            items: deptProvider.departments.map((dept) {
                              return DropdownMenuItem(
                                value: dept,
                                child: Text('${dept.name} (${dept.code})'),
                              );
                            }).toList(),
                            onChanged: (dept) {
                              setState(() {
                                _selectedDepartment = dept;
                              });
                            },
                          );
                        },
                      ),
                      const SizedBox(height: 16),

                      // Batch Number
                      TextFormField(
                        controller: _batchNoController,
                        decoration: const InputDecoration(
                          labelText: 'Batch Number *',
                          hintText: 'e.g., 1, 2, 3...',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.numbers),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 16),

                      // Program Type
                      DropdownButtonFormField<String>(
                        value: _selectedProgramType,
                        decoration: const InputDecoration(
                          labelText: 'Program Type *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.school),
                        ),
                        items: _programTypes.map((type) {
                          return DropdownMenuItem(
                            value: type,
                            child: Text(type),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedProgramType = value!;
                          });
                        },
                      ),
                      const SizedBox(height: 16),

                      // Total Students
                      TextFormField(
                        controller: _studentsController,
                        decoration: const InputDecoration(
                          labelText: 'Total Students *',
                          hintText: 'e.g., 60',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.people),
                        ),
                        keyboardType: TextInputType.number,
                      ),

                      const SizedBox(height: 24),

                      // Courses Section Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Courses',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove_circle, color: Colors.red),
                                onPressed: _courseCount > 0 ? () {
                                  setState(() {
                                    _courseCount--;
                                    _updateCourseControllers(_courseCount);
                                  });
                                } : null,
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.blue[100],
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  '$_courseCount',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.add_circle, color: Colors.green),
                                onPressed: () {
                                  setState(() {
                                    _courseCount++;
                                    _updateCourseControllers(_courseCount);
                                  });
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                      const Divider(),

                      if (_courseCount == 0)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: Text(
                              'No courses added. Click + to add courses.',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                        )
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _courseCount,
                          itemBuilder: (context, index) {
                            return Card(
                              margin: const EdgeInsets.only(bottom: 16),
                              color: Colors.grey[50],
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(
                                  color: _courseIds[index] != null
                                      ? Colors.green
                                      : Colors.grey[300]!,
                                  width: _courseIds[index] != null ? 2 : 1,
                                ),
                              ),
                              child: Column(
                                children: [
                                  ListTile(
                                    leading: Container(
                                      width: 30,
                                      height: 30,
                                      decoration: BoxDecoration(
                                        color: _courseIds[index] != null
                                            ? Colors.green
                                            : Colors.blue,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Center(
                                        child: Text(
                                          '${index + 1}',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                    title: Text(
                                      _courseCodeControllers[index].text.isNotEmpty
                                          ? _courseCodeControllers[index].text
                                          : 'New Course ${index + 1}',
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    subtitle: Text(
                                      _courseTitleControllers[index].text.isNotEmpty
                                          ? _courseTitleControllers[index].text
                                          : 'Enter course details',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    trailing: IconButton(
                                      icon: Icon(
                                        _isCourseExpanded[index]
                                            ? Icons.expand_less
                                            : Icons.expand_more,
                                        color: Colors.blue,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _isCourseExpanded[index] = !_isCourseExpanded[index];
                                        });
                                      },
                                    ),
                                  ),
                                  if (_isCourseExpanded[index])
                                    Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: Column(
                                        children: [
                                          TextFormField(
                                            controller: _courseCodeControllers[index],
                                            decoration: const InputDecoration(
                                              labelText: 'Course Code *',
                                              hintText: 'e.g., CSE101',
                                              border: OutlineInputBorder(),
                                              prefixIcon: Icon(Icons.code),
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          TextFormField(
                                            controller: _courseTitleControllers[index],
                                            decoration: const InputDecoration(
                                              labelText: 'Course Title *',
                                              hintText: 'e.g., Programming Fundamentals',
                                              border: OutlineInputBorder(),
                                              prefixIcon: Icon(Icons.title),
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Row(
                                            children: [
                                              Expanded(
                                                child: TextFormField(
                                                  controller: _courseCreditControllers[index],
                                                  decoration: const InputDecoration(
                                                    labelText: 'Credit',
                                                    hintText: 'e.g., 3.0',
                                                    border: OutlineInputBorder(),
                                                    prefixIcon: Icon(Icons.star),
                                                  ),
                                                  keyboardType: TextInputType.number,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: DropdownButtonFormField<String>(
                                                  value: _courseTypes[index],
                                                  decoration: const InputDecoration(
                                                    labelText: 'Type',
                                                    border: OutlineInputBorder(),
                                                  ),
                                                  items: _availableCourseTypes.map((type) {
                                                    return DropdownMenuItem(
                                                      value: type,
                                                      child: Text(type),
                                                    );
                                                  }).toList(),
                                                  onChanged: (value) {
                                                    setState(() {
                                                      _courseTypes[index] = value!;
                                                    });
                                                  },
                                                ),
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
                  onPressed: () => _saveBatch(dialogContext),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1976D2),
                    foregroundColor: Colors.white,
                  ),
                  child: Text(_isEditMode ? 'Update Batch' : 'Add Batch'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // FIXED: _saveBatch method
  Future<void> _saveBatch(BuildContext dialogContext) async {
    // Validate Basic Info
    if (_selectedDepartment == null) {
      _showError('Please select department');
      return;
    }

    if (_batchNoController.text.isEmpty) {
      _showError('Please enter batch number');
      return;
    }

    if (_studentsController.text.isEmpty) {
      _showError('Please enter total students');
      return;
    }

    int? batchNo = int.tryParse(_batchNoController.text);
    int? totalStudents = int.tryParse(_studentsController.text);

    if (batchNo == null || batchNo < 1 || batchNo > 100) {
      _showError('Batch number must be between 1-100');
      return;
    }

    if (totalStudents == null || totalStudents < 1) {
      _showError('Please enter valid number of students');
      return;
    }

    // Validate and prepare Courses
    List<Map<String, dynamic>> newCourses = [];
    List<Map<String, dynamic>> updatedCourses = [];

    for (int i = 0; i < _courseCount; i++) {
      String code = _courseCodeControllers[i].text.trim();
      String title = _courseTitleControllers[i].text.trim();
      String creditStr = _courseCreditControllers[i].text.trim();

      if (code.isEmpty) {
        _showError('Please enter course code for course ${i + 1}');
        return;
      }

      if (title.isEmpty) {
        _showError('Please enter course title for course ${i + 1}');
        return;
      }

      double? credit = double.tryParse(creditStr);
      if (credit == null || credit <= 0) {
        _showError('Please enter valid credit for course ${i + 1}');
        return;
      }

      final courseData = {
        'id': _courseIds[i],
        'code': code.toUpperCase(),
        'title': title,
        'credit': credit,
        'type': _courseTypes[i],
      };

      if (_courseIds[i] != null) {
        updatedCourses.add(courseData);
      } else {
        newCourses.add(courseData);
      }
    }

    final batchProvider = Provider.of<BatchProvider>(context, listen: false);
    final courseProvider = Provider.of<CourseProvider>(context, listen: false);
    final dashboardProvider = Provider.of<DashboardProvider>(context, listen: false);

    Batch batch = Batch(
      id: _isEditMode ? _selectedBatch!.id : null,
      departmentId: _selectedDepartment!.id!,
      batchNo: batchNo,
      programType: _selectedProgramType,
      totalStudents: totalStudents,
    );

    bool batchSuccess;

    if (_isEditMode) {
      print('✏️ Updating batch ID: ${_selectedBatch!.id}');
      batchSuccess = await batchProvider.updateBatch(batch);
    } else {
      print('➕ Adding new batch');
      batchSuccess = await batchProvider.addBatch(batch);
    }

    if (batchSuccess) {
      // Get the batch ID
      int batchId;
      if (_isEditMode) {
        batchId = _selectedBatch!.id!;
      } else {
        // For new batch, find the newly added batch
        await batchProvider.loadBatches();

        Batch? newBatch;
        try {
          newBatch = batchProvider.batches.firstWhere(
                (b) =>
            b.departmentId == batch.departmentId &&
                b.batchNo == batch.batchNo &&
                b.programType == batch.programType,
          );
        } catch (e) {
          if (batchProvider.batches.isNotEmpty) {
            newBatch = batchProvider.batches.last;
          }
        }

        if (newBatch != null) {
          batchId = newBatch.id!;
        } else {
          print('❌ Could not find newly added batch');
          Navigator.pop(dialogContext);
          return;
        }
      }

      print('📚 Processing courses for batch ID: $batchId');
      print('🆕 New courses: ${newCourses.length}');
      print('🔄 Updated courses: ${updatedCourses.length}');

      // Save new courses
      for (var courseData in newCourses) {
        Course course = Course(
          code: courseData['code'],
          title: courseData['title'],
          credit: courseData['credit'],
          type: courseData['type'],
          batchId: batchId,
        );
        await courseProvider.addCourse(course);
        print('✅ Added new course: ${course.code}');
      }

      // Update existing courses
      for (var courseData in updatedCourses) {
        Course course = Course(
          id: courseData['id'],
          code: courseData['code'],
          title: courseData['title'],
          credit: courseData['credit'],
          type: courseData['type'],
          batchId: batchId,
        );
        await courseProvider.updateCourse(course);
        print('✅ Updated course: ${course.code}');
      }

      Navigator.pop(dialogContext);

      await dashboardProvider.refreshDashboard();

      dashboardProvider.addRecentActivity(
        _isEditMode
            ? 'Batch ${batch.batchNo} updated with ${newCourses.length} new courses'
            : 'New batch ${batch.batchNo} added with ${newCourses.length} courses',
        Icons.group_add,
        Colors.orange,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditMode
                ? 'Batch updated successfully'
                : 'Batch added successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } else {
      print('❌ Batch operation failed');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save batch'),
            backgroundColor: Colors.red,
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

  Future<void> _deleteBatch(Batch batch) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Batch'),
        content: Text(
          'Are you sure you want to delete Batch ${batch.batchNo}?\n\nThis will also delete all courses under this batch!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);

              final batchProvider = Provider.of<BatchProvider>(context, listen: false);
              final dashboardProvider = Provider.of<DashboardProvider>(context, listen: false);

              bool success = await batchProvider.deleteBatch(batch.id!);

              if (success && mounted) {
                await dashboardProvider.refreshDashboard();
                dashboardProvider.addRecentActivity(
                  'Batch ${batch.batchNo} deleted',
                  Icons.delete,
                  Colors.red,
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Batch deleted successfully'),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Batch Management'),
        backgroundColor: const Color(0xFF1976D2),
        foregroundColor: Colors.white,
        elevation: 4,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(120),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search by batch number...',
                    hintStyle: const TextStyle(color: Colors.white70),
                    prefixIcon: const Icon(Icons.search, color: Colors.white),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                      icon: const Icon(Icons.clear, color: Colors.white),
                      onPressed: () {
                        _searchController.clear();
                        final provider = Provider.of<BatchProvider>(context, listen: false);
                        provider.clearFilters();
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
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                child: Consumer2<BatchProvider, DepartmentProvider>(
                  builder: (context, batchProvider, deptProvider, child) {
                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          Container(
                            height: 40,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: batchProvider.selectedProgramType,
                                hint: const Text('All Programs', style: TextStyle(color: Colors.white)),
                                icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                                items: [
                                  const DropdownMenuItem(
                                    value: null,
                                    child: Text('All Programs', style: TextStyle(color: Colors.black)),
                                  ),
                                  ..._programTypes.map((type) {
                                    return DropdownMenuItem(
                                      value: type,
                                      child: Text(type, style: const TextStyle(color: Colors.black)),
                                    );
                                  }),
                                ],
                                onChanged: (value) {
                                  batchProvider.filterByProgramType(value);
                                },
                                dropdownColor: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            height: 40,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<int?>(
                                value: batchProvider.selectedDepartmentId,
                                hint: const Text('All Depts', style: TextStyle(color: Colors.white)),
                                icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                                items: [
                                  const DropdownMenuItem(
                                    value: null,
                                    child: Text('All Departments', style: TextStyle(color: Colors.black)),
                                  ),
                                  ...deptProvider.departments.map((dept) {
                                    return DropdownMenuItem(
                                      value: dept.id,
                                      child: Text(dept.code, style: const TextStyle(color: Colors.black)),
                                    );
                                  }),
                                ],
                                onChanged: (value) {
                                  batchProvider.filterByDepartment(value);
                                },
                                dropdownColor: Colors.white,
                              ),
                            ),
                          ),
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
        onPressed: () => _showAddEditDialog(),
        backgroundColor: const Color(0xFF1976D2),
        foregroundColor: Colors.white,
        child: const Icon(Icons.group_add),
      ),
      body: Consumer<BatchProvider>(
        builder: (context, batchProvider, child) {
          if (batchProvider.isLoading && batchProvider.batches.isEmpty) {
            return const LoadingWidget(message: 'Loading batches...');
          }

          if (batchProvider.error != null && batchProvider.batches.isEmpty) {
            return ErrorWidgetWithRetry(
              error: batchProvider.error!,
              onRetry: _loadData,
            );
          }

          if (batchProvider.batches.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.group, size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text('No batches found', style: TextStyle(fontSize: 18, color: Colors.grey[600])),
                  const SizedBox(height: 8),
                  Text('Click + button to add new batch', style: TextStyle(fontSize: 14, color: Colors.grey[500])),
                ],
              ),
            );
          }

          return Column(
            children: [
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
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.orange, shape: BoxShape.circle),
                      child: const Icon(Icons.group, color: Colors.white, size: 30),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Total Batches', style: TextStyle(fontSize: 14, color: Colors.grey)),
                          Text('${batchProvider.totalBatches}',
                              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.orange)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: batchProvider.batches.length,
                  itemBuilder: (context, index) {
                    final batch = batchProvider.batches[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), shape: BoxShape.circle),
                          child: Center(
                              child: Text('${batch.batchNo}',
                                  style: const TextStyle(color: Colors.orange, fontSize: 18, fontWeight: FontWeight.bold))),
                        ),
                        title: Row(
                          children: [
                            Expanded(child: Text('Batch ${batch.batchNo}',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: batch.programType == 'HSC' ? Colors.blue.withOpacity(0.1) : Colors.green.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(batch.programType,
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: batch.programType == 'HSC' ? Colors.blue[700] : Colors.green[700],
                                    fontWeight: FontWeight.w500,
                                  )),
                            ),
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text('Department: ${batch.departmentName ?? 'Unknown'}',
                                style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                            const SizedBox(height: 2),
                            Text('Students: ${batch.totalStudents}',
                                style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Color(0xFF1976D2)),
                              onPressed: () => _showAddEditDialog(batch: batch),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteBatch(batch),
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
}