import 'package:g14_indoor_locator/server/database_service.dart';
import 'package:mysql1/mysql1.dart';
import 'room.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  /// Insert a room into the database
  Future<int> insertRoom(Room room) async {
    try {
      await DatabaseService.insertData('rooms', room.toJson());
      print('Inserted room: ${room.name}'); // Debug log
      return 1; // Assuming success (MySQL doesn't return auto-increment IDs directly in this setup)
    } catch (e) {
      print('[ERROR] Failed to insert room: $e');
      rethrow;
    }
  }

  /// Delete a house by its name
  Future<void> deleteHouseByName(String houseName) async {
    try {
      await DatabaseService.deleteData('rooms', 'houseName = "$houseName"');
      print('Deleted house: $houseName'); // Debug log
    } catch (e) {
      print('[ERROR] Failed to delete house: $e');
      rethrow;
    }
  }

  /// Update a room in the database
  Future<int> updateRoom(Room room) async {
    try {
      final query = '''
        UPDATE rooms
        SET position = ?, width = ?, height = ?, isGrouped = ?, connectedRoom = ?, connectedWall = ?, name = ?, houseName = ?, groupId = ?
        WHERE id = ?
      ''';
      final conn = await MySqlConnection.connect(DatabaseService.settings);
      await conn.query(query, [
        room.position,
        room.width,
        room.height,
        room.isGrouped ? 1 : 0,
        room.connectedRoom,
        room.connectedWall,
        room.name,
        room.houseName,
        room.groupId,
        room.id,
      ]);
      await conn.close();
      print('Updated room with ID: ${room.id}'); // Debug log
      return 1; // Assuming success
    } catch (e) {
      print('[ERROR] Failed to update room: $e');
      rethrow;
    }
  }

  /// Delete a room by its ID
  Future<int> deleteRoom(int id) async {
    try {
      await DatabaseService.deleteData('rooms', 'id = $id');
      print('Deleted room with ID: $id'); // Debug log
      return 1; // Assuming success
    } catch (e) {
      print('[ERROR] Failed to delete room: $e');
      rethrow;
    }
  }

  /// Clear all rooms from the database
  Future<void> clearDatabase() async {
    try {
      await DatabaseService.deleteData('rooms', '1 = 1'); // Delete all rows
      print('Cleared all rooms from the database'); // Debug log
    } catch (e) {
      print('[ERROR] Failed to clear database: $e');
      rethrow;
    }
  }

  /// Get distinct house names from the database
  Future<List<String>> getDistinctHouseNames() async {
    try {
      final conn = await MySqlConnection.connect(DatabaseService.settings);
      final results = await conn.query('SELECT DISTINCT houseName FROM rooms WHERE houseName IS NOT NULL');
      await conn.close();
      final houseNames = results.map((row) => row['houseName'] as String).toList();
      print('Distinct house names from DB: $houseNames'); // Debug log
      return houseNames;
    } catch (e) {
      print('[ERROR] Failed to fetch distinct house names: $e');
      rethrow;
    }
  }

  /// Get rooms by house name
  Future<List<Room>> getRoomsByHouseName(String houseName) async {
    try {
      final conn = await MySqlConnection.connect(DatabaseService.settings);
      final results = await conn.query('SELECT * FROM rooms WHERE houseName = ?', [houseName]);
      await conn.close();
      final rooms = results.map((row) => Room.fromJson(row.fields)).toList();
      print('Fetched rooms for house: $houseName'); // Debug log
      return rooms;
    } catch (e) {
      print('[ERROR] Failed to fetch rooms by house name: $e');
      rethrow;
    }
  }
}