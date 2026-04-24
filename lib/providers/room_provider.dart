import 'package:flutter/material.dart';
import '../data/repositories/room_repository.dart';
import '../data/repositories/department_repository.dart';
import '../data/models/room_model.dart';
import '../data/models/department_model.dart';

class RoomProvider extends ChangeNotifier {
  final RoomRepository _repository = RoomRepository();
  final DepartmentRepository _deptRepository = DepartmentRepository();

  List<Room> _rooms = [];
  List<Department> _departments = [];
  bool _isLoading = false;
  String? _error;
  bool _isSearching = false;
  List<Room> _searchResults = [];
  int? _selectedFloor;
  String? _selectedType;
  int? _selectedDepartmentId;

  // Getters
  List<Room> get rooms => _isSearching ? _searchResults : _rooms;
  List<Department> get departments => _departments;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isSearching => _isSearching;
  int get totalRooms => _rooms.length;
  int? get selectedFloor => _selectedFloor;
  String? get selectedType => _selectedType;
  int? get selectedDepartmentId => _selectedDepartmentId;

  Future<void> loadRooms() async {
    _isLoading = true;
    _error = null;

    try {
      _rooms = await _repository.getAllRooms();

      await loadDepartments();

      for (var room in _rooms) {
        if (room.departmentId != null) {
          try {
            final dept = _departments.firstWhere(
                  (d) => d.id == room.departmentId,
            );
            room.departmentName = dept.name;
          } catch (e) {
            room.departmentName = 'Unknown';
          }
        }
      }

      print('✅ Loaded ${_rooms.length} rooms');
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      print('❌ Error loading rooms: $e');
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadDepartments() async {
    try {
      _departments = await _deptRepository.getAllDepartments();
    } catch (e) {
      print('❌ Error loading departments: $e');
    }
  }

  Future<bool> addRoom(Room room) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      bool exists = await _repository.isRoomExists(room.roomNo);
      if (exists) {
        _error = 'Room ${room.roomNo} already exists';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      int id = await _repository.addRoom(room);
      if (id > 0) {
        print('✅ Room added with ID: $id');
        await loadRooms();
        return true;
      } else {
        _error = 'Failed to add room';
        return false;
      }
    } catch (e) {
      print('❌ Error adding room: $e');
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateRoom(Room room) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      bool exists = await _repository.isRoomExists(
        room.roomNo,
        excludeId: room.id,
      );
      if (exists) {
        _error = 'Room ${room.roomNo} already exists';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      int rowsAffected = await _repository.updateRoom(room);
      if (rowsAffected > 0) {
        print('✅ Room updated');
        await loadRooms();
        return true;
      } else {
        _error = 'Failed to update room';
        return false;
      }
    } catch (e) {
      print('❌ Error updating room: $e');
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteRoom(int id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      int rowsAffected = await _repository.deleteRoom(id);
      if (rowsAffected > 0) {
        print('✅ Room deleted');
        await loadRooms();
        return true;
      } else {
        _error = 'Failed to delete room';
        return false;
      }
    } catch (e) {
      print('❌ Error deleting room: $e');
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> assignDepartment(int roomId, int? departmentId) async {
    try {
      int result = await _repository.assignDepartment(roomId, departmentId);
      if (result > 0) {
        await loadRooms();
        return true;
      }
      return false;
    } catch (e) {
      print('❌ Error assigning department: $e');
      return false;
    }
  }

  void filterByFloor(int? floor) {
    _selectedFloor = floor;
    _applyFilters();
  }

  void filterByType(String? type) {
    _selectedType = type;
    _applyFilters();
  }

  void filterByDepartment(int? departmentId) {
    _selectedDepartmentId = departmentId;
    _applyFilters();
  }

  void _applyFilters() {
    _isSearching = true;

    _searchResults = _rooms.where((room) {
      bool matchesFloor = _selectedFloor == null || room.floor == _selectedFloor;
      bool matchesType = _selectedType == null || room.type == _selectedType;
      bool matchesDepartment = _selectedDepartmentId == null ||
          room.departmentId == _selectedDepartmentId;

      return matchesFloor && matchesType && matchesDepartment;
    }).toList();

    notifyListeners();
  }

  void clearFilters() {
    _isSearching = false;
    _selectedFloor = null;
    _selectedType = null;
    _selectedDepartmentId = null;
    _searchResults = [];
    notifyListeners();
  }

  void searchRooms(String query) {
    if (query.isEmpty) {
      _isSearching = false;
      _searchResults = [];
    } else {
      _isSearching = true;
      _searchResults = _rooms.where((room) =>
          room.roomNo.toLowerCase().contains(query.toLowerCase())
      ).toList();
    }
    notifyListeners();
  }

  List<Room> getRoomsByFloor(int floor) {
    return _rooms.where((room) => room.floor == floor).toList();
  }

  List<Room> getRoomsByDepartment(int departmentId) {
    return _rooms.where((room) => room.departmentId == departmentId).toList();
  }

  List<Room> getAvailableRooms() {
    return _rooms.where((room) => room.departmentId == null).toList();
  }

  Room? getRoomById(int id) {
    try {
      return _rooms.firstWhere((room) => room.id == id);
    } catch (e) {
      return null;
    }
  }

  int getRoomCountByType(String type) {
    return _rooms.where((room) => room.type == type).toList().length;
  }

  Map<String, int> getLabPCStats() {
    int totalPCs = 0;
    int activePCs = 0;

    for (var room in _rooms.where((r) => r.type == 'Lab')) {
      totalPCs += room.pcTotal ?? 0;
      activePCs += room.pcActive ?? 0;
    }

    return {'total': totalPCs, 'active': activePCs};
  }

  Future<void> refresh() async {
    await loadRooms();
  }
}