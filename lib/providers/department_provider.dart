import 'package:flutter/material.dart';
import '../data/repositories/department_repository.dart';
import '../data/models/department_model.dart';

class DepartmentProvider extends ChangeNotifier {
  final DepartmentRepository _repository = DepartmentRepository();

  List<Department> _departments = [];
  bool _isLoading = false;
  String? _error;
  bool _isSearching = false;
  List<Department> _searchResults = [];

  // Getters
  List<Department> get departments => _isSearching ? _searchResults : _departments;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isSearching => _isSearching;
  int get totalDepartments => _departments.length;

  // Load all departments - FIXED
  Future<void> loadDepartments() async {
    if (_isLoading) return;

    _isLoading = true;
    _error = null;
    notifyListeners(); // Show loading state

    try {
      _departments = await _repository.getAllDepartments();
      print('✅ Loaded ${_departments.length} departments');
      _isLoading = false;
      notifyListeners(); // Important: Notify after loading
    } catch (e) {
      print('❌ Error loading departments: $e');
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Add new department - FIXED
  Future<bool> addDepartment(Department department) async {
    _isLoading = true;
    notifyListeners();

    try {
      bool exists = await _repository.isDepartmentCodeExists(department.code);
      if (exists) {
        _error = 'Department code already exists';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      int id = await _repository.addDepartment(department);
      if (id > 0) {
        print('✅ Department added with ID: $id');
        // Reload departments
        await loadDepartments();
        return true;
      } else {
        _error = 'Failed to add department';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      print('❌ Error: $e');
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Update department - FIXED
  Future<bool> updateDepartment(Department department) async {
    _isLoading = true;
    notifyListeners();

    try {
      bool exists = await _repository.isDepartmentCodeExists(
        department.code,
        excludeId: department.id,
      );
      if (exists) {
        _error = 'Department code already exists';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      int rowsAffected = await _repository.updateDepartment(department);
      if (rowsAffected > 0) {
        print('✅ Department updated');
        await loadDepartments();
        return true;
      } else {
        _error = 'Failed to update department';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      print('❌ Error: $e');
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Delete department - FIXED
  Future<bool> deleteDepartment(int id) async {
    _isLoading = true;
    notifyListeners();

    try {
      int rowsAffected = await _repository.deleteDepartment(id);
      if (rowsAffected > 0) {
        print('✅ Department deleted');
        await loadDepartments();
        return true;
      } else {
        _error = 'Failed to delete department';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      print('❌ Error: $e');
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Search departments
  void searchDepartments(String query) {
    if (query.isEmpty) {
      _isSearching = false;
      _searchResults = [];
    } else {
      _isSearching = true;
      _searchResults = _departments.where((dept) =>
      dept.name.toLowerCase().contains(query.toLowerCase()) ||
          dept.code.toLowerCase().contains(query.toLowerCase())
      ).toList();
    }
    notifyListeners();
  }

  // Clear search
  void clearSearch() {
    _isSearching = false;
    _searchResults = [];
    notifyListeners();
  }

  // Get department by id
  Department? getDepartmentById(int id) {
    try {
      return _departments.firstWhere((dept) => dept.id == id);
    } catch (e) {
      return null;
    }
  }

  // Refresh data
  Future<void> refresh() async {
    await loadDepartments();
  }
}