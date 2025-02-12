import 'package:mysql1/mysql1.dart';
import 'dart:convert'; // Required for utf8 decoding
class DatabaseService {
  static final ConnectionSettings settings = ConnectionSettings(
    host: 'homeassistant',
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

      return results.map((row) {
        final rowData = Map<String, dynamic>.from(row.fields);

        // Convert Blob fields to String
        rowData.forEach((key, value) {
          if (value is Blob) {
            rowData[key] = utf8.decode(value.toBytes()); // Correct conversion
          }
        });

        return rowData;
      }).toList();
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
  static Future<void> deleteUser(int userId) async {
    final conn = await MySqlConnection.connect(settings);
    try {
      await conn.query('DELETE FROM Users WHERE id = ?', [userId]);
      print('[SUCCESS] User deleted successfully');
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

  /// **Insert a new house**
  static Future<void> insertHouse(Map<String, dynamic> houseData) async {
    final conn = await MySqlConnection.connect(settings);
    try {
      await conn.query(
        'INSERT INTO Houses (name) VALUES (?)',
        [houseData['name']],
      );
      print('[SUCCESS] House inserted successfully');
    } catch (e) {
      print('[ERROR] Failed to insert house: $e');
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
