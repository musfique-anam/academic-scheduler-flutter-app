import 'package:flutter/material.dart';
import '../data/repositories/batch_repository.dart';
import '../data/repositories/department_repository.dart';
import '../data/repositories/merge_repository.dart';
import '../data/models/batch_model.dart';
import '../data/models/department_model.dart';
import '../data/models/merge_model.dart';

class MergeProvider extends ChangeNotifier {
  final BatchRepository _batchRepository = BatchRepository();
  final DepartmentRepository _deptRepository = DepartmentRepository();
  final MergeRepository _mergeRepository = MergeRepository();

  List<Department> _departments = [];
  List<Batch> _allBatches = [];
  List<Batch> _filteredBatches = [];
  List<Batch> _selectedBatches = [];
  List<MergedClass> _merges = [];

  Department? _selectedDepartment;
  bool _isLoading = false;
  String? _error;
  String _searchQuery = '';

  // Getters
  List<Department> get departments => _departments;
  List<Batch> get filteredBatches => _filteredBatches;
  List<Batch> get selectedBatches => _selectedBatches;
  Department? get selectedDepartment => _selectedDepartment;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get selectedCount => _selectedBatches.length;
  bool get canSelectMore => _selectedBatches.length < 3;
  bool get hasSelection => _selectedBatches.isNotEmpty;
  List<MergedClass> get merges => _merges;
  int get totalMerges => _merges.length;

  // Load initial data
  Future<void> loadData() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Load departments
      _departments = await _deptRepository.getAllDepartments();
      print('✅ Loaded ${_departments.length} departments in MergeProvider');

      // Load all batches
      _allBatches = await _batchRepository.getAllBatches();
      print('✅ Loaded ${_allBatches.length} batches in MergeProvider');

      // Load all merges
      _merges = await _mergeRepository.getAllMerges();
      print('✅ Loaded ${_merges.length} merges');

      // Attach department names to batches
      for (var batch in _allBatches) {
        try {
          final dept = _departments.firstWhere(
                (d) => d.id == batch.departmentId,
          );
          batch.departmentName = dept.name;
        } catch (e) {
          batch.departmentName = 'Unknown Department';
        }
        batch.isSelected = false;
      }

      _filteredBatches = List.from(_allBatches);
      _error = null;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      print('❌ Error loading data: $e');
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Create merge
  Future<bool> createMerge(MergedClass merge) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Check for conflicts
      bool hasConflict = await _mergeRepository.hasConflict(
          merge.day,
          merge.timeSlot,
          merge.roomId,
          merge.teacherId
      );

      if (hasConflict) {
        _error = 'Conflict: Room or Teacher already assigned at this time';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      int id = await _mergeRepository.createMerge(merge);
      if (id > 0) {
        await loadData(); // Reload all data
        return true;
      }
      return false;
    } catch (e) {
      print('❌ Error creating merge: $e');
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update merge
  Future<bool> updateMerge(MergedClass merge) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Check for conflicts (excluding current merge)
      bool hasConflict = await _mergeRepository.hasConflict(
          merge.day,
          merge.timeSlot,
          merge.roomId,
          merge.teacherId,
          excludeId: merge.id
      );

      if (hasConflict) {
        _error = 'Conflict: Room or Teacher already assigned at this time';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      int rowsAffected = await _mergeRepository.updateMerge(merge);
      if (rowsAffected > 0) {
        await loadData(); // Reload all data
        return true;
      }
      return false;
    } catch (e) {
      print('❌ Error updating merge: $e');
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Delete merge
  Future<bool> deleteMerge(int id) async {
    _isLoading = true;
    notifyListeners();

    try {
      int rowsAffected = await _mergeRepository.deleteMerge(id);
      if (rowsAffected > 0) {
        await loadData(); // Reload all data
        return true;
      }
      return false;
    } catch (e) {
      print('❌ Error deleting merge: $e');
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Filter by department
  void filterByDepartment(Department? department) {
    _selectedDepartment = department;
    _applyFilters();
  }

  // Search batches
  void searchBatches(String query) {
    _searchQuery = query;
    _applyFilters();
  }

  // Apply both department filter and search
  void _applyFilters() {
    var filtered = List<Batch>.from(_allBatches);

    if (_selectedDepartment != null) {
      filtered = filtered.where((batch) =>
      batch.departmentId == _selectedDepartment!.id
      ).toList();
    }

    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((batch) {
        final query = _searchQuery.toLowerCase();
        return batch.batchNo.toString().contains(query) ||
            (batch.departmentName?.toLowerCase().contains(query) ?? false) ||
            batch.programType.toLowerCase().contains(query);
      }).toList();
    }

    for (var batch in filtered) {
      batch.isSelected = _selectedBatches.contains(batch);
    }

    _filteredBatches = filtered;
    notifyListeners();
  }

  // Toggle batch selection
  void toggleBatch(Batch batch) {
    if (_selectedBatches.contains(batch)) {
      _selectedBatches.remove(batch);
      batch.isSelected = false;
    } else {
      if (_selectedBatches.length < 3) {
        _selectedBatches.add(batch);
        batch.isSelected = true;
      } else {
        _error = 'You can select maximum 3 batches';
        Future.delayed(const Duration(seconds: 2), () {
          if (_error == 'You can select maximum 3 batches') {
            _error = null;
            notifyListeners();
          }
        });
      }
    }

    for (var b in _filteredBatches) {
      b.isSelected = _selectedBatches.contains(b);
    }

    notifyListeners();
  }

  // Remove batch from selection
  void removeBatch(Batch batch) {
    _selectedBatches.remove(batch);
    batch.isSelected = false;

    for (var b in _filteredBatches) {
      if (b.id == batch.id) {
        b.isSelected = false;
      }
    }

    notifyListeners();
  }

  // Clear all selections
  void clearSelections() {
    for (var batch in _selectedBatches) {
      batch.isSelected = false;
    }
    _selectedBatches.clear();

    for (var b in _filteredBatches) {
      b.isSelected = false;
    }

    notifyListeners();
  }

  // Get selected batch summary
  String getSelectedBatchSummary() {
    if (_selectedBatches.isEmpty) return 'No batches selected';
    return _selectedBatches.map((b) =>
    '${b.departmentName} Batch ${b.batchNo}'
    ).join(' + ');
  }

  // Check if all selected batches are from same department
  bool get isSameDepartment {
    if (_selectedBatches.length < 2) return true;
    final firstDept = _selectedBatches.first.departmentId;
    return _selectedBatches.every((b) => b.departmentId == firstDept);
  }

  // Get common program type
  String? get commonProgramType {
    if (_selectedBatches.isEmpty) return null;
    final firstType = _selectedBatches.first.programType;
    final allSame = _selectedBatches.every((b) => b.programType == firstType);
    return allSame ? firstType : null;
  }

  // Get total students across selected batches
  int get totalSelectedStudents {
    return _selectedBatches.fold(0, (sum, batch) => sum + batch.totalStudents);
  }

  // Get merges by day
  List<MergedClass> getMergesByDay(String day) {
    return _merges.where((m) => m.day == day).toList();
  }

  // Get merges by teacher
  List<MergedClass> getMergesByTeacher(int teacherId) {
    return _merges.where((m) => m.teacherId == teacherId).toList();
  }

  // Get merges by room
  List<MergedClass> getMergesByRoom(int roomId) {
    return _merges.where((m) => m.roomId == roomId).toList();
  }

  // Check if slot is available
  Future<bool> isSlotAvailable(String day, int timeSlot, int? roomId, int? teacherId) async {
    return !(await _mergeRepository.hasConflict(day, timeSlot, roomId, teacherId));
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Refresh data
  Future<void> refresh() async {
    await loadData();
  }
}