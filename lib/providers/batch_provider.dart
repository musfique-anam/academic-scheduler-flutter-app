import 'package:flutter/material.dart';
import '../data/repositories/batch_repository.dart';
import '../data/repositories/department_repository.dart';
import '../data/models/batch_model.dart';
import '../data/models/department_model.dart';

class BatchProvider extends ChangeNotifier {
  final BatchRepository _repository = BatchRepository();
  final DepartmentRepository _deptRepository = DepartmentRepository();

  List<Batch> _batches = [];
  List<Department> _departments = [];
  bool _isLoading = false;
  String? _error;
  bool _isSearching = false;
  List<Batch> _searchResults = [];
  int? _selectedDepartmentId;
  String? _selectedProgramType;

  // Getters
  List<Batch> get batches => _isSearching ? _searchResults : _batches;
  List<Department> get departments => _departments;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isSearching => _isSearching;
  int get totalBatches => _batches.length;
  int? get selectedDepartmentId => _selectedDepartmentId;
  String? get selectedProgramType => _selectedProgramType;

  // Load all batches
  Future<void> loadBatches() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _batches = await _repository.getAllBatches();

      // Load department names for display
      await loadDepartments();

      // Attach department names to batches
      for (var batch in _batches) {
        try {
          final dept = _departments.firstWhere(
                (d) => d.id == batch.departmentId,
          );
          batch.departmentName = dept.name;
        } catch (e) {
          batch.departmentName = 'Unknown';
        }
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load departments for dropdown
  Future<void> loadDepartments() async {
    try {
      _departments = await _deptRepository.getAllDepartments();
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading departments: $e');
    }
  }

  // Add new batch
  Future<bool> addBatch(Batch batch) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Check if batch number already exists in this department
      bool exists = await _repository.isBatchExists(
          batch.departmentId,
          batch.batchNo
      );

      if (exists) {
        _error = 'Batch ${batch.batchNo} already exists in this department';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      int id = await _repository.addBatch(batch);
      if (id > 0) {
        await loadBatches();
        return true;
      } else {
        _error = 'Failed to add batch';
        return false;
      }
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update batch - FIXED VERSION
  Future<bool> updateBatch(Batch batch) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      print('Updating batch: ${batch.id} - ${batch.batchNo}');

      // Check if batch number already exists (excluding current batch)
      bool exists = await _repository.isBatchExists(
        batch.departmentId,
        batch.batchNo,
        excludeId: batch.id,
      );

      if (exists) {
        _error = 'Batch ${batch.batchNo} already exists in this department';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      int rowsAffected = await _repository.updateBatch(batch);
      print('Rows affected: $rowsAffected');

      if (rowsAffected > 0) {
        await loadBatches();
        return true;
      } else {
        _error = 'Failed to update batch';
        return false;
      }
    } catch (e) {
      print('Error updating batch: $e');
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Delete batch
  Future<bool> deleteBatch(int id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      int rowsAffected = await _repository.deleteBatch(id);
      if (rowsAffected > 0) {
        await loadBatches();
        return true;
      } else {
        _error = 'Failed to delete batch';
        return false;
      }
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Filter by department
  void filterByDepartment(int? departmentId) {
    _selectedDepartmentId = departmentId;
    _applyFilters();
  }

  // Filter by program type
  void filterByProgramType(String? programType) {
    _selectedProgramType = programType;
    _applyFilters();
  }

  // Apply all filters
  void _applyFilters() {
    if (_selectedDepartmentId == null && _selectedProgramType == null) {
      _isSearching = false;
      _searchResults = [];
    } else {
      _isSearching = true;

      _searchResults = _batches.where((batch) {
        bool matchesDepartment = _selectedDepartmentId == null ||
            batch.departmentId == _selectedDepartmentId;
        bool matchesProgramType = _selectedProgramType == null ||
            batch.programType == _selectedProgramType;

        return matchesDepartment && matchesProgramType;
      }).toList();
    }
    notifyListeners();
  }

  // Clear filters
  void clearFilters() {
    _isSearching = false;
    _selectedDepartmentId = null;
    _selectedProgramType = null;
    _searchResults = [];
    notifyListeners();
  }

  // Search batches by number
  void searchBatches(String query) {
    if (query.isEmpty) {
      _isSearching = false;
      _searchResults = [];
    } else {
      _isSearching = true;
      int? batchNo = int.tryParse(query);

      if (batchNo != null) {
        _searchResults = _batches.where((batch) =>
        batch.batchNo == batchNo
        ).toList();
      } else {
        _searchResults = [];
      }
    }
    notifyListeners();
  }

  // Get batches by department
  List<Batch> getBatchesByDepartment(int departmentId) {
    return _batches.where((batch) => batch.departmentId == departmentId).toList();
  }

  // Get batches by program type
  List<Batch> getBatchesByProgramType(String programType) {
    return _batches.where((batch) => batch.programType == programType).toList();
  }

  // Get batch by id
  Batch? getBatchById(int id) {
    try {
      return _batches.firstWhere((batch) => batch.id == id);
    } catch (e) {
      return null;
    }
  }

  // Get total students count
  Future<int> getTotalStudents() async {
    return await _repository.getTotalStudents();
  }

  // Refresh data
  Future<void> refresh() async {
    await loadBatches();
  }
}