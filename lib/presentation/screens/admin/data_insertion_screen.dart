import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/department_provider.dart';
import '../../../providers/batch_provider.dart';
import '../../../providers/course_provider.dart';
import '../../../providers/teacher_provider.dart';
import '../../../data/initial_data.dart';
import '../../../data/services/database_helper.dart'; // ← ADD THIS IMPORT
import '../../widgets/loading_widget.dart';

class DataInsertionScreen extends StatefulWidget {
  const DataInsertionScreen({super.key});

  @override
  State<DataInsertionScreen> createState() => _DataInsertionScreenState();
}

class _DataInsertionScreenState extends State<DataInsertionScreen> {
  bool _isLoading = false;
  String _status = '';

  Future<void> _insertAllData() async {
    setState(() {
      _isLoading = true;
      _status = 'Starting data insertion...';
    });

    try {
      final dbHelper = DatabaseHelper(); // Now this will work
      final db = await dbHelper.database;

      await InitialData.insertAllData(db);

      // Reload all providers
      await Future.wait([
        Provider.of<DepartmentProvider>(context, listen: false).loadDepartments(),
        Provider.of<BatchProvider>(context, listen: false).loadBatches(),
        Provider.of<CourseProvider>(context, listen: false).loadCourses(),
        Provider.of<TeacherProvider>(context, listen: false).loadTeachers(),
      ]);

      setState(() {
        _isLoading = false;
        _status = '✅ All data inserted successfully!';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Data inserted successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
        _status = '❌ Error: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Insert Initial Data'),
        backgroundColor: const Color(0xFF1976D2),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'This will insert:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildBulletPoint('3 Departments (CSE, EEE, CE)'),
            _buildBulletPoint('8 Batches per department (Total 24 batches)'),
            _buildBulletPoint('Complete CSE curriculum (All 8 semesters)'),
            _buildBulletPoint('Complete EEE curriculum'),
            _buildBulletPoint('Complete Civil curriculum'),
            _buildBulletPoint('15 Teachers per department (Total 45 teachers)'),

            const SizedBox(height: 32),

            if (_status.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _status.contains('✅') ? Colors.green[50] : Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(_status),
              ),

            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _insertAllData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                child: _isLoading
                    ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
                    : const Text('Insert All Data'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 16),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}