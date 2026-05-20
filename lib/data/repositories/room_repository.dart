import '../services/database_helper.dart';
import '../models/room_model.dart';

class RoomRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final String tableName = 'rooms';

  // Create - Add new room
  Future<int> addRoom(Room room) async {
    try {
      print('📝 Adding room: ${room.roomNo}');
      return await _dbHelper.insert(tableName, room.toMap());
    } catch (e) {
      print('❌ Error adding room: $e');
      throw Exception('Failed to add room: $e');
    }
  }

  // Read - Get all rooms
  Future<List<Room>> getAllRooms() async {
    try {
      final List<Map<String, dynamic>> maps = await _dbHelper.queryAll(tableName);
      print('📚 Found ${maps.length} rooms');
      return List.generate(maps.length, (i) {
        return Room.fromMap(maps[i]);
      });
    } catch (e) {
      print('❌ Error getting rooms: $e');
      throw Exception('Failed to get rooms: $e');
    }
  }

  // Read - Get rooms by floor
  Future<List<Room>> getRoomsByFloor(int floor) async {
    try {
      final List<Map<String, dynamic>> maps = await _dbHelper.query(
        tableName,
        where: 'floor = ?',
        whereArgs: [floor],
        orderBy: 'roomNo ASC',
      );

      return List.generate(maps.length, (i) {
        return Room.fromMap(maps[i]);
      });
    } catch (e) {
      throw Exception('Failed to get rooms by floor: $e');
    }
  }

  // Read - Get rooms by department
  Future<List<Room>> getRoomsByDepartment(int departmentId) async {
    try {
      final List<Map<String, dynamic>> maps = await _dbHelper.query(
        tableName,
        where: 'departmentId = ?',
        whereArgs: [departmentId],
        orderBy: 'roomNo ASC',
      );

      return List.generate(maps.length, (i) {
        return Room.fromMap(maps[i]);
      });
    } catch (e) {
      throw Exception('Failed to get rooms by department: $e');
    }
  }

  // Read - Get rooms by type
  Future<List<Room>> getRoomsByType(String type) async {
    try {
      final List<Map<String, dynamic>> maps = await _dbHelper.query(
        tableName,
        where: 'type = ?',
        whereArgs: [type],
        orderBy: 'roomNo ASC',
      );

      return List.generate(maps.length, (i) {
        return Room.fromMap(maps[i]);
      });
    } catch (e) {
      throw Exception('Failed to get rooms by type: $e');
    }
  }

  // Read - Get single room by id
  Future<Room?> getRoomById(int id) async {
    try {
      final List<Map<String, dynamic>> maps = await _dbHelper.query(
        tableName,
        where: 'id = ?',
        whereArgs: [id],
      );

      if (maps.isNotEmpty) {
        return Room.fromMap(maps.first);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get room: $e');
    }
  }

  // Read - Get room by room number
  Future<Room?> getRoomByNumber(String roomNo) async {
    try {
      final List<Map<String, dynamic>> maps = await _dbHelper.query(
        tableName,
        where: 'roomNo = ?',
        whereArgs: [roomNo],
      );

      if (maps.isNotEmpty) {
        return Room.fromMap(maps.first);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get room by number: $e');
    }
  }

  // Update - Update room
  Future<int> updateRoom(Room room) async {
    try {
      print('🔄 Updating room: ${room.id} - ${room.roomNo}');

      // First check if room exists
      final existing = await getRoomById(room.id!);
      if (existing == null) {
        print('❌ Room with id ${room.id} not found!');
        return 0;
      }

      int result = await _dbHelper.update(
        tableName,
        room.toMap(),
        where: 'id = ?',
        whereArgs: [room.id],
      );

      print('✅ Update result: $result rows affected');
      return result;
    } catch (e) {
      print('❌ Error updating room: $e');
      throw Exception('Failed to update room: $e');
    }
  }

  // Delete - Delete room
  Future<int> deleteRoom(int id) async {
    try {
      print('🗑️ Deleting room with ID: $id');
      int result = await _dbHelper.delete(
        tableName,
        where: 'id = ?',
        whereArgs: [id],
      );
      print('✅ Delete result: $result rows affected');
      return result;
    } catch (e) {
      print('❌ Error deleting room: $e');
      throw Exception('Failed to delete room: $e');
    }
  }

  // Assign department to room
  Future<int> assignDepartment(int roomId, int? departmentId) async {
    try {
      int result = await _dbHelper.update(
        tableName,
        {'departmentId': departmentId},
        where: 'id = ?',
        whereArgs: [roomId],
      );
      return result;
    } catch (e) {
      throw Exception('Failed to assign department: $e');
    }
  }

  // Check if room number exists
  Future<bool> isRoomExists(String roomNo, {int? excludeId}) async {
    try {
      String where = 'roomNo = ?';
      List<dynamic> args = [roomNo];

      if (excludeId != null) {
        where += ' AND id != ?';
        args.add(excludeId);
      }

      final List<Map<String, dynamic>> maps = await _dbHelper.query(
        tableName,
        where: where,
        whereArgs: args,
      );

      return maps.isNotEmpty;
    } catch (e) {
      throw Exception('Failed to check room: $e');
    }
  }

  // Get room count
  Future<int> getRoomCount() async {
    try {
      final List<Map<String, dynamic>> maps = await _dbHelper.queryAll(tableName);
      return maps.length;
    } catch (e) {
      throw Exception('Failed to get room count: $e');
    }
  }

  // Get available rooms (not assigned to any department)
  Future<List<Room>> getAvailableRooms() async {
    try {
      final List<Map<String, dynamic>> maps = await _dbHelper.query(
        tableName,
        where: 'departmentId IS NULL',
        orderBy: 'roomNo ASC',
      );

      return List.generate(maps.length, (i) {
        return Room.fromMap(maps[i]);
      });
    } catch (e) {
      throw Exception('Failed to get available rooms: $e');
    }
  }
}