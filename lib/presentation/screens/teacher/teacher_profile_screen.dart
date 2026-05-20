import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/teacher_provider.dart';
import '../../../providers/department_provider.dart';
import '../../../data/models/teacher_model.dart';
import '../../../data/models/department_model.dart';

class TeacherProfileScreen extends StatefulWidget {
  final Teacher teacher;

  const TeacherProfileScreen({super.key, required this.teacher});

  @override
  State<TeacherProfileScreen> createState() => _TeacherProfileScreenState();
}

class _TeacherProfileScreenState extends State<TeacherProfileScreen> {
  late Teacher _teacher;
  bool _isEditing = false;
  bool _isLoading = false;

  // Controllers
  final _nameController = TextEditingController();
  final _shortNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _maxLoadController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _teacher = widget.teacher;
    _initializeControllers();
  }

  void _initializeControllers() {
    _nameController.text = _teacher.name;
    _shortNameController.text = _teacher.shortName;
    _phoneController.text = _teacher.phone;
    _maxLoadController.text = _teacher.maxLoad.toString();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _shortNameController.dispose();
    _phoneController.dispose();
    _maxLoadController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    setState(() => _isLoading = true);

    try {
      final teacherProvider = Provider.of<TeacherProvider>(context, listen: false);

      Teacher updatedTeacher = Teacher(
        id: _teacher.id,
        name: _nameController.text.trim(),
        shortName: _shortNameController.text.trim(),
        username: _teacher.username,
        password: _teacher.password,
        phone: _phoneController.text.trim(),
        departmentId: _teacher.departmentId,
        role: _teacher.role,
        interestedCourses: _teacher.interestedCourses,
        availableDays: _teacher.availableDays,
        availableSlots: _teacher.availableSlots,
        maxLoad: int.tryParse(_maxLoadController.text) ?? _teacher.maxLoad,
        isProfileCompleted: _teacher.isProfileCompleted,
      );

      bool success = await teacherProvider.updateTeacher(updatedTeacher);

      if (success && mounted) {
        setState(() {
          _teacher = updatedTeacher;
          _isEditing = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final deptProvider = Provider.of<DepartmentProvider>(context);
    final department = deptProvider.departments.firstWhere(
          (d) => d.id == _teacher.departmentId,
      orElse: () => Department(id: 0, name: 'Unknown', code: ''),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        backgroundColor: const Color(0xFF1976D2),
        foregroundColor: Colors.white,
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                setState(() {
                  _isEditing = true;
                });
              },
            ),
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _isLoading ? null : _saveProfile,
            ),
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                setState(() {
                  _isEditing = false;
                  _initializeControllers();
                });
              },
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Profile Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: _teacher.isProfileCompleted
                            ? Colors.green
                            : Colors.orange,
                        child: Text(
                          _teacher.shortName[0].toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (!_teacher.isProfileCompleted)
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.orange,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.warning,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _isEditing
                      ? TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Full Name',
                      border: OutlineInputBorder(),
                    ),
                  )
                      : Text(
                    _teacher.name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _teacher.isProfileCompleted
                          ? Colors.green.withOpacity(0.1)
                          : Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _teacher.isProfileCompleted
                          ? 'Profile Complete'
                          : 'Profile Incomplete',
                      style: TextStyle(
                        color: _teacher.isProfileCompleted
                            ? Colors.green
                            : Colors.orange,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Personal Information Card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Personal Information',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Divider(height: 20),

                    // Username (Read Only)
                    ListTile(
                      leading: const Icon(Icons.person_outline, size: 20),
                      title: const Text('Username', style: TextStyle(fontSize: 12)),
                      subtitle: Text(
                        _teacher.username,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                      ),
                    ),

                    // Short Name
                    ListTile(
                      leading: const Icon(Icons.short_text, size: 20),
                      title: const Text('Short Name', style: TextStyle(fontSize: 12)),
                      subtitle: _isEditing
                          ? TextFormField(
                        controller: _shortNameController,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          hintText: 'Enter short name',
                        ),
                      )
                          : Text(
                        _teacher.shortName,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                      ),
                    ),

                    // Phone
                    ListTile(
                      leading: const Icon(Icons.phone, size: 20),
                      title: const Text('Phone', style: TextStyle(fontSize: 12)),
                      subtitle: _isEditing
                          ? TextFormField(
                        controller: _phoneController,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          hintText: 'Enter phone number',
                        ),
                        keyboardType: TextInputType.phone,
                      )
                          : Text(
                        _teacher.phone,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                      ),
                    ),

                    // Department
                    ListTile(
                      leading: const Icon(Icons.business, size: 20),
                      title: const Text('Department', style: TextStyle(fontSize: 12)),
                      subtitle: Text(
                        '${department.name} (${department.code})',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Academic Information Card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Academic Information',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Divider(height: 20),

                    // Max Load
                    ListTile(
                      leading: const Icon(Icons.speed, size: 20),
                      title: const Text('Maximum Load (credits/week)', style: TextStyle(fontSize: 12)),
                      subtitle: _isEditing
                          ? TextFormField(
                        controller: _maxLoadController,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          hintText: 'Enter max load',
                        ),
                        keyboardType: TextInputType.number,
                      )
                          : Text(
                        '${_teacher.maxLoad} credits',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                      ),
                    ),

                    // Available Days
                    ListTile(
                      leading: const Icon(Icons.calendar_today, size: 20),
                      title: const Text('Available Days', style: TextStyle(fontSize: 12)),
                      subtitle: Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: _teacher.availableDays.isEmpty
                            ? [const Text('Not set', style: TextStyle(color: Colors.grey))]
                            : _teacher.availableDays.map((day) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue[100],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              day.substring(0, 3),
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.blue[700],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),

                    // Available Slots
                    ListTile(
                      leading: const Icon(Icons.access_time, size: 20),
                      title: const Text('Available Slots', style: TextStyle(fontSize: 12)),
                      subtitle: Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: _teacher.availableSlots.isEmpty
                            ? [const Text('Not set', style: TextStyle(color: Colors.grey))]
                            : _teacher.availableSlots.map((slot) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green[100],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Slot $slot',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.green[700],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Password Change Button
            OutlinedButton.icon(
              onPressed: () {
                _showChangePasswordDialog(context);
              },
              icon: const Icon(Icons.lock_reset),
              label: const Text('Change Password'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                side: const BorderSide(color: Color(0xFF1976D2)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showChangePasswordDialog(BuildContext context) {
    final oldPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: oldPasswordController,
              decoration: const InputDecoration(
                labelText: 'Current Password',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: newPasswordController,
              decoration: const InputDecoration(
                labelText: 'New Password',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: confirmPasswordController,
              decoration: const InputDecoration(
                labelText: 'Confirm Password',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
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
              if (newPasswordController.text == confirmPasswordController.text) {
                // TODO: Implement password change
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Password changed successfully'),
                    backgroundColor: Colors.green,
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Passwords do not match'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Change'),
          ),
        ],
      ),
    );
  }
}