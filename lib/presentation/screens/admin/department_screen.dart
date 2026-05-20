import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/department_provider.dart';
import '../../../providers/dashboard_provider.dart';
import '../../../data/models/department_model.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/error_widget.dart';

class DepartmentScreen extends StatefulWidget {
  const DepartmentScreen({super.key});

  @override
  State<DepartmentScreen> createState() => _DepartmentScreenState();
}

class _DepartmentScreenState extends State<DepartmentScreen> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();

  Department? _selectedDepartment;
  bool _isEditMode = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDepartments();
    });

    _searchController.addListener(() {
      final provider = Provider.of<DepartmentProvider>(context, listen: false);
      provider.searchDepartments(_searchController.text);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _nameController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _loadDepartments() async {
    final provider = Provider.of<DepartmentProvider>(context, listen: false);
    await provider.loadDepartments();
  }

  void _showAddEditDialog({Department? department}) {
    _isEditMode = department != null;
    _selectedDepartment = department;

    if (_isEditMode) {
      _nameController.text = department!.name;
      _codeController.text = department.code;
    } else {
      _nameController.clear();
      _codeController.clear();
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_isEditMode ? 'Edit Department' : 'Add New Department'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Department Name',
                hintText: 'e.g., Computer Science & Engineering',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.business),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _codeController,
              decoration: const InputDecoration(
                labelText: 'Department Code',
                hintText: 'e.g., CSE',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.code),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: _saveDepartment,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1976D2),
              foregroundColor: Colors.white,
            ),
            child: Text(_isEditMode ? 'Update' : 'Add'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveDepartment() async {
    if (_nameController.text.isEmpty || _codeController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all fields'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final provider = Provider.of<DepartmentProvider>(context, listen: false);

    Department department = Department(
      id: _isEditMode ? _selectedDepartment!.id : null,
      name: _nameController.text.trim(),
      code: _codeController.text.trim().toUpperCase(),
    );

    bool success;
    if (_isEditMode) {
      success = await provider.updateDepartment(department);
    } else {
      success = await provider.addDepartment(department);
    }

    if (success && mounted) {
      Navigator.pop(context);

      final dashboardProvider = Provider.of<DashboardProvider>(context, listen: false);
      await dashboardProvider.refreshDashboard();

      dashboardProvider.addRecentActivity(
        _isEditMode
            ? 'Department ${department.code} updated'
            : 'New department ${department.code} added',
        Icons.business,
        Colors.blue,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isEditMode
              ? 'Department updated successfully'
              : 'Department added successfully'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _deleteDepartment(Department department) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Department'),
        content: Text(
          'Are you sure you want to delete ${department.name} (${department.code})?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);

              final provider = Provider.of<DepartmentProvider>(context, listen: false);
              final dashboardProvider = Provider.of<DashboardProvider>(context, listen: false);

              bool success = await provider.deleteDepartment(department.id!);

              if (success && mounted) {
                await dashboardProvider.refreshDashboard();

                dashboardProvider.addRecentActivity(
                  'Department ${department.code} deleted',
                  Icons.delete,
                  Colors.red,
                );

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Department deleted successfully'),
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
        title: const Text('Department Management'),
        backgroundColor: const Color(0xFF1976D2),
        foregroundColor: Colors.white,
        elevation: 4,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search departments...',
                hintStyle: const TextStyle(color: Colors.white70),
                prefixIcon: const Icon(Icons.search, color: Colors.white),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear, color: Colors.white),
                  onPressed: () {
                    _searchController.clear();
                    Provider.of<DepartmentProvider>(context, listen: false)
                        .clearSearch();
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
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
      body: Consumer<DepartmentProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.departments.isEmpty) {
            return const LoadingWidget(message: 'Loading departments...');
          }

          if (provider.error != null && provider.departments.isEmpty) {
            return ErrorWidgetWithRetry(
              error: provider.error!,
              onRetry: _loadDepartments,
            );
          }

          if (provider.departments.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.business,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No departments found',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Click + button to add new department',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              // Summary Card
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1976D2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.business,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Total Departments',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                          Text(
                            '${provider.totalDepartments}',
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1976D2),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (provider.isSearching)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange[100],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${provider.departments.length} results',
                          style: TextStyle(
                            color: Colors.orange[800],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // Department List
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: provider.departments.length,
                  itemBuilder: (context, index) {
                    final department = provider.departments[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: const Color(0xFF1976D2).withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              department.code.isNotEmpty
                                  ? department.code.substring(0, 1)
                                  : '?', // ← এই line টা fix করলাম
                              style: const TextStyle(
                                color: Color(0xFF1976D2),
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        title: Text(
                          department.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            'Code: ${department.code}',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Color(0xFF1976D2)),
                              onPressed: () => _showAddEditDialog(department: department),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteDepartment(department),
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