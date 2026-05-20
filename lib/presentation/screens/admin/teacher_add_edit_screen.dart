import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/teacher_provider.dart';
import '../../../providers/department_provider.dart';
import '../../../providers/dashboard_provider.dart';
import '../../../data/models/teacher_model.dart';
import '../../../data/models/department_model.dart';
import '../../../data/models/course_model.dart';
import '../../widgets/loading_widget.dart';

class TeacherAddEditScreen extends StatefulWidget {
  final Teacher? teacher;

  const TeacherAddEditScreen({super.key, this.teacher});

  @override
  State<TeacherAddEditScreen> createState() => _TeacherAddEditScreenState();
}

class _TeacherAddEditScreenState extends State<TeacherAddEditScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _shortNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();

  Department? _selectedDepartment;
  List<Course> _selectedCourses = [];
  List<String> _selectedDays = [];
  List<int> _selectedSlots = [];
  int _maxLoad = 0;

  bool _isLoading = false;
  bool _showAdvanced = false;

  final List<String> _availableDays = [
    'Friday', 'Saturday', 'Sunday', 'Monday', 'Tuesday'
  ];

  final List<Map<String, dynamic>> _availableSlots = const [
    {'slot': 1, 'time': '9:30 - 11:00'},
    {'slot': 2, 'time': '11:10 - 12:40'},
    {'slot': 3, 'time': '14:00 - 15:30'},
    {'slot': 4, 'time': '15:40 - 17:10'},
  ];

  bool get _isEditMode => widget.teacher != null;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });

    if (_isEditMode) {
      _populateFields();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _shortNameController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    final teacherProvider = Provider.of<TeacherProvider>(context, listen: false);
    await teacherProvider.loadDepartments();

    // If edit mode, load courses after departments are loaded
    if (_isEditMode && _selectedDepartment != null) {
      await _loadCoursesForDepartment(_selectedDepartment!.id!);
    }
  }

  void _populateFields() {
    final teacher = widget.teacher!;

    _nameController.text = teacher.name;
    _shortNameController.text = teacher.shortName;
    _usernameController.text = teacher.username;
    _passwordController.text = teacher.password;
    _phoneController.text = teacher.phone;
    _selectedDays = teacher.availableDays;
    _selectedSlots = teacher.availableSlots;
    _maxLoad = teacher.maxLoad;
    _selectedDepartment = Department(
      id: teacher.departmentId,
      name: '',
      code: '',
    );

    print('📝 Editing teacher: ${teacher.id} - ${teacher.name}');
  }

  Future<void> _loadCoursesForDepartment(int departmentId) async {
    final teacherProvider = Provider.of<TeacherProvider>(context, listen: false);
    await teacherProvider.loadCoursesByDepartment(departmentId);

    // Select existing courses
    if (_isEditMode && mounted) {
      final courses = teacherProvider.availableCourses;
      _selectedCourses = courses.where((c) =>
          widget.teacher!.interestedCourses.contains(c.id)
      ).toList();
      print('✅ Loaded ${_selectedCourses.length} interested courses');
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? 'Edit Teacher' : 'Add New Teacher'),
        backgroundColor: const Color(0xFF1976D2),
        foregroundColor: Colors.white,
      ),
      body: Consumer<TeacherProvider>(
        builder: (context, teacherProvider, child) {
          return Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Basic Info Card
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Basic Information', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                              const Divider(),

                              TextFormField(
                                controller: _nameController,
                                decoration: const InputDecoration(
                                  labelText: 'Full Name *',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.person),
                                ),
                                validator: (value) => (value == null || value.isEmpty) ? 'Required' : null,
                              ),
                              const SizedBox(height: 16),

                              TextFormField(
                                controller: _shortNameController,
                                decoration: const InputDecoration(
                                  labelText: 'Short Name *',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.short_text),
                                ),
                                validator: (value) => (value == null || value.isEmpty) ? 'Required' : null,
                              ),
                              const SizedBox(height: 16),

                              // Department Dropdown
                              Consumer<DepartmentProvider>(
                                builder: (context, deptProvider, child) {
                                  if (deptProvider.departments.isEmpty) {
                                    return const Center(child: Text('Loading departments...'));
                                  }

                                  Department? selectedDept;
                                  if (_selectedDepartment != null) {
                                    try {
                                      selectedDept = deptProvider.departments.firstWhere(
                                            (dept) => dept.id == _selectedDepartment!.id,
                                      );
                                    } catch (e) {
                                      print('Department not found');
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
                                        _selectedCourses = [];
                                      });
                                      if (dept != null) {
                                        _loadCoursesForDepartment(dept.id!);
                                      }
                                    },
                                    validator: (value) => value == null ? 'Required' : null,
                                  );
                                },
                              ),
                              const SizedBox(height: 16),

                              TextFormField(
                                controller: _phoneController,
                                decoration: const InputDecoration(
                                  labelText: 'Phone Number *',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.phone),
                                ),
                                validator: (value) => (value == null || value.isEmpty) ? 'Required' : null,
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Login Card
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Login Credentials', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                              const Divider(),

                              TextFormField(
                                controller: _usernameController,
                                decoration: const InputDecoration(
                                  labelText: 'Username *',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.person_outline),
                                ),
                                enabled: !_isEditMode,
                                validator: (value) => (!_isEditMode && (value == null || value.isEmpty)) ? 'Required' : null,
                              ),
                              const SizedBox(height: 16),

                              TextFormField(
                                controller: _passwordController,
                                decoration: InputDecoration(
                                  labelText: _isEditMode ? 'New Password (leave blank to keep current)' : 'Password *',
                                  border: const OutlineInputBorder(),
                                  prefixIcon: const Icon(Icons.lock),
                                ),
                                obscureText: true,
                                validator: (value) {
                                  if (!_isEditMode && (value == null || value.isEmpty)) {
                                    return 'Required';
                                  }
                                  return null;
                                },
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Academic Settings
                      Card(
                        child: Column(
                          children: [
                            ListTile(
                              leading: const Icon(Icons.settings),
                              title: const Text('Academic Settings'),
                              trailing: IconButton(
                                icon: Icon(_showAdvanced ? Icons.expand_less : Icons.expand_more),
                                onPressed: () => setState(() => _showAdvanced = !_showAdvanced),
                              ),
                            ),
                            if (_showAdvanced) ...[
                              const Divider(),
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Interested Courses', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 8),
                                    if (_selectedDepartment == null)
                                      const Center(child: Padding(
                                        padding: EdgeInsets.all(16),
                                        child: Text('Select department first'),
                                      ))
                                    else if (teacherProvider.isLoading)
                                      const Center(child: CircularProgressIndicator())
                                    else if (teacherProvider.availableCourses.isEmpty)
                                        const Center(child: Text('No courses found'))
                                      else
                                        Wrap(
                                          spacing: 8,
                                          runSpacing: 8,
                                          children: teacherProvider.availableCourses.map((course) {
                                            final isSelected = _selectedCourses.any((c) => c.id == course.id);
                                            return FilterChip(
                                              label: Text(course.code),
                                              selected: isSelected,
                                              onSelected: (selected) {
                                                setState(() {
                                                  if (selected) {
                                                    _selectedCourses.add(course);
                                                  } else {
                                                    _selectedCourses.removeWhere((c) => c.id == course.id);
                                                  }
                                                });
                                              },
                                            );
                                          }).toList(),
                                        ),

                                    const Divider(height: 32),

                                    const Text('Available Days', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 8),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: _availableDays.map((day) {
                                        final isSelected = _selectedDays.contains(day);
                                        return FilterChip(
                                          label: Text(day),
                                          selected: isSelected,
                                          onSelected: (selected) {
                                            setState(() {
                                              if (selected) {
                                                _selectedDays.add(day);
                                              } else {
                                                _selectedDays.remove(day);
                                              }
                                            });
                                          },
                                        );
                                      }).toList(),
                                    ),

                                    const Divider(height: 32),

                                    const Text('Available Slots', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 8),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: _availableSlots.map((slot) {
                                        final slotNum = slot['slot'] as int;
                                        final isSelected = _selectedSlots.contains(slotNum);
                                        return FilterChip(
                                          label: Text('Slot ${slot['slot']}'),
                                          selected: isSelected,
                                          onSelected: (selected) {
                                            setState(() {
                                              if (selected) {
                                                _selectedSlots.add(slotNum);
                                              } else {
                                                _selectedSlots.remove(slotNum);
                                              }
                                            });
                                          },
                                        );
                                      }).toList(),
                                    ),

                                    const Divider(height: 32),

                                    const Text('Max Load', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Slider(
                                            value: _maxLoad.toDouble(),
                                            min: 0,
                                            max: 30,
                                            divisions: 30,
                                            onChanged: (value) => setState(() => _maxLoad = value.round()),
                                          ),
                                        ),
                                        Container(
                                          width: 50,
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: Colors.purple[50],
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            '$_maxLoad',
                                            textAlign: TextAlign.center,
                                            style: const TextStyle(fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Submit Button
                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _submitForm,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1976D2),
                            foregroundColor: Colors.white,
                          ),
                          child: _isLoading
                              ? const CircularProgressIndicator(color: Colors.white)
                              : Text(_isEditMode ? 'Update Teacher' : 'Add Teacher'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (_isLoading)
                Container(
                  color: Colors.black.withOpacity(0.3),
                  child: const Center(child: CircularProgressIndicator()),
                ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDepartment == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select department'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isLoading = true);

    final teacherProvider = Provider.of<TeacherProvider>(context, listen: false);
    final dashboardProvider = Provider.of<DashboardProvider>(context, listen: false);

    Teacher teacher = Teacher(
      id: widget.teacher?.id,
      name: _nameController.text.trim(),
      shortName: _shortNameController.text.trim(),
      username: _usernameController.text.trim(),
      password: _passwordController.text.trim().isEmpty && _isEditMode
          ? widget.teacher!.password
          : _passwordController.text.trim(),
      phone: _phoneController.text.trim(),
      departmentId: _selectedDepartment!.id!,
      role: 'teacher',
      interestedCourses: _selectedCourses.map((c) => c.id!).toList(),
      availableDays: _selectedDays,
      availableSlots: _selectedSlots,
      maxLoad: _maxLoad,
      isProfileCompleted: _isEditMode ? widget.teacher!.isProfileCompleted : false,
    );

    bool success;
    if (_isEditMode) {
      print('✏️ Updating teacher ID: ${widget.teacher!.id}');
      success = await teacherProvider.updateTeacher(teacher);
    } else {
      print('➕ Adding new teacher');
      success = await teacherProvider.addTeacher(teacher);
    }

    if (success && mounted) {
      await dashboardProvider.refreshDashboard();
      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditMode ? 'Teacher updated' : 'Teacher added'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } else {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(teacherProvider.error ?? 'Failed to save'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}