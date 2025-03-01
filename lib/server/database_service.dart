import 'package:mysql1/mysql1.dart';
import 'dart:convert'; // Required for utf8 decoding

class DatabaseService {
  static final ConnectionSettings settings = ConnectionSettings(
    host: '192.168.90.63',
    port: 3306,
    user: 'homeassistant',
    password: 'SQL123!',
    db: 'homeassistant',
  );

  /// **Test the database connection**
  static Future<void> testConnection() async {
    try {
      final conn = await MySqlConnection.connect(settings);
      print('[SUCCESS] Connected to the database!');
      await conn.close();
    } catch (e) {
      print('[ERROR] Failed to connect to the database: $e');
    }
  }

  // **USER MANAGEMENT FUNCTIONS**

  /// **Fetch all users from the server**
  static Future<List<Map<String, dynamic>>> fetchUsers() async {
    final conn = await MySqlConnection.connect(settings);
    try {
      final results = await conn.query('SELECT * FROM Users');
      return results.map((row) => row.fields).toList();
    } catch (e) {
      print('[ERROR] Failed to fetch users: $e');
      return [];
    } finally {
      await conn.close();
    }
  }

  /// **Insert a new user into the server**
  static Future<void> insertUser(Map<String, dynamic> userData) async {
    final conn = await MySqlConnection.connect(settings);
    try {
      await conn.query(
        'INSERT INTO Users (name, email, userType, house) VALUES (?, ?, ?, ?)',
        [userData['name'], userData['email'], userData['userType'], userData['house']],
      );
      print('[SUCCESS] User inserted successfully');
    } catch (e) {
      print('[ERROR] Failed to insert user: $e');
    } finally {
      await conn.close();
    }
  }

  /// **Update an existing user**
  static Future<void> updateUser(int userId, Map<String, dynamic> updatedData) async {
    final conn = await MySqlConnection.connect(settings);
    try {
      await conn.query(
        'UPDATE Users SET name = ?, email = ?, userType = ?, house = ? WHERE id = ?',
        [updatedData['name'], updatedData['email'], updatedData['userType'], updatedData['house'], userId],
      );
      print('[SUCCESS] User updated successfully');
    } catch (e) {
      print('[ERROR] Failed to update user: $e');
    } finally {
      await conn.close();
    }
  }

  /// **Delete a user**
  static Future<void> deleteUser(String userId) async {
    final conn = await MySqlConnection.connect(settings);
    try {
      await conn.query('DELETE FROM Users WHERE id = ?', [userId]);
      print('[SUCCESS] User deleted successfully with UUID: $userId');
    } catch (e) {
      print('[ERROR] Failed to delete user: $e');
    } finally {
      await conn.close();
    }
  }

  // **HOUSE MANAGEMENT FUNCTIONS**

  /// **Fetch all houses**
  static Future<List<Map<String, dynamic>>> fetchHouses() async {
    final conn = await MySqlConnection.connect(settings);
    try {
      final results = await conn.query('SELECT * FROM Houses');
      return results.map((row) => row.fields).toList();
    } catch (e) {
      print('[ERROR] Failed to fetch houses: $e');
      return [];
    } finally {
      await conn.close();
    }
  }

  /// **Send house data to the MariaDB server**
  static Future<void> sendHouseData(int houseId, String houseName, List<Map<String, dynamic>> rooms) async {
  final conn = await MySqlConnection.connect(settings);
    try {
      print("[MariaDB] Inserting House: $houseName");

      // Insert house and get its ID
      await conn.query(
        'INSERT INTO Houses (name) VALUES (?) ON DUPLICATE KEY UPDATE name = VALUES(name)',
        [houseName],
      );

      // Retrieve the correct house ID
      var result = await conn.query('SELECT id FROM Houses WHERE name = ?', [houseName]);
      if (result.isNotEmpty) {
        houseId = result.first['id']; // Assign the retrieved house ID
        print("[MariaDB] Retrieved House ID: $houseId");
      } else {
        print("[ERROR] Failed to retrieve house ID.");
        return;
      }

      for (var room in rooms) {
        print("[MariaDB] Inserting Room: $room");

        // Ensure position values are correctly extracted
        var position = room['position'];
        double posX = position is Map ? position['x'] ?? 0.0 : 0.0;
        double posY = position is Map ? position['y'] ?? 0.0 : 0.0;

        await conn.query(
          'INSERT INTO Rooms (house_id, house_name, name, width, height, position_x, position_y) '
          'VALUES (?, ?, ?, ?, ?, ?, ?) '
          'ON DUPLICATE KEY UPDATE house_name = VALUES(house_name), name = VALUES(name), width = VALUES(width), height = VALUES(height), position_x = VALUES(position_x), position_y = VALUES(position_y)',
          [
            houseId,
            houseName,
            room['name'] ?? 'Unnamed Room',
            room['width'],
            room['height'],
            posX, // Extracted from position map
            posY,
          ],
        );
      }

      print('[MariaDB] House and rooms successfully saved.');
    } catch (e) {
      print('[ERROR] Failed to send house data to MariaDB: $e');
    } finally {
      await conn.close();
    }
  }




  /// **Delete a house**
  static Future<void> deleteHouse(int houseId) async {
    final conn = await MySqlConnection.connect(settings);
    try {
      await conn.query('DELETE FROM Houses WHERE id = ?', [houseId]);
      print('[SUCCESS] House deleted successfully');
    } catch (e) {
      print('[ERROR] Failed to delete house: $e');
    } finally {
      await conn.close();
    }
  }


  // **SQL MANAGEMENT FUNCTIONS (FOR `ManageSQLPage`)**

  /// **Fetch data from any table**
  static Future<List<Map<String, dynamic>>> fetchData(String tableName) async {
    final conn = await MySqlConnection.connect(settings);
    try {
      final results = await conn.query('SELECT * FROM `$tableName`');
      return results.map((row) => row.fields).toList();
    } catch (e) {
      print('[ERROR] Failed to query table: $e');
      return [];
    } finally {
      await conn.close();
    }
  }

  /// **Insert data into any table**
  static Future<void> insertData(String tableName, Map<String, dynamic> data) async {
    final conn = await MySqlConnection.connect(settings);
    try {
      var fields = data.keys.join(', ');
      var placeholders = data.keys.map((_) => '?').join(', ');
      var values = data.values.toList();
      var query = 'INSERT INTO `$tableName` ($fields) VALUES ($placeholders)';

      await conn.query(query, values);
      print('[SUCCESS] Data inserted successfully into $tableName');
    } catch (e) {
      print('[ERROR] Failed to insert data: $e');
    } finally {
      await conn.close();
    }
  }

  /// **Delete data from any table**
  static Future<void> deleteData(String tableName, String condition) async {
    final conn = await MySqlConnection.connect(settings);
    try {
      final query = 'DELETE FROM `$tableName` WHERE $condition';
      await conn.query(query);
      print('[SUCCESS] Data deleted from $tableName');
    } catch (e) {
      print('[ERROR] Failed to delete data: $e');
    } finally {
      await conn.close();
    }
  }
}
