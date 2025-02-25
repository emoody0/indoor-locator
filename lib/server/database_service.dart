import 'package:mysql1/mysql1.dart';

class DatabaseService {
  static final ConnectionSettings settings = ConnectionSettings(
    host: 'homeassistant', 
    port: 3306,
    user: 'homeassistant',
    password: 'SQL123!',
    db: 'homeassistant',
  );

  /// Test database connection
  static Future<void> testConnection() async {
    print('Attempting to connect to the database...');
    try {
      final conn = await MySqlConnection.connect(settings);
      print('[SUCCESS] Connected to the database!');
      await conn.close();
      print('[INFO] Database connection closed.');
    } catch (e) {
      print('[ERROR] Failed to connect to the database: $e');
    }
  }

  /// Fetch all data from a table
  static Future<List<Map<String, dynamic>>> fetchData(String tableName) async {
    final conn = await MySqlConnection.connect(settings);
    try {
      final results = await conn.query('SELECT * FROM $tableName');
      final data = results.map((row) => row.fields).toList();
      return data;
    } catch (e) {
      print('[ERROR] Failed to query table: $e');
      return [];
    } finally {
      await conn.close();
    }
  }

  /// Insert data into a table (Auto-generate UUID for 'id')
  static Future<void> insertData(String tableName, Map<String, dynamic> data) async {
    final conn = await MySqlConnection.connect(settings);
    try {
      // Ensure 'id' is generated as a UUID
      if (!data.containsKey('id')) {
        data['id'] = await _generateUUID(conn);
      }

      var fields = data.keys.join(', ');
      var placeholders = data.keys.map((_) => '?').join(', ');
      var values = data.values.toList();
      var query = 'INSERT INTO $tableName ($fields) VALUES ($placeholders)';

      await conn.query(query, values);
      print('[SUCCESS] Data inserted successfully into table: $tableName');
    } catch (e) {
      print('[ERROR] Failed to insert data: $e');
    } finally {
      await conn.close();
    }
  }

  /// Delete data from a table based on condition
  static Future<void> deleteData(String tableName, String condition) async {
    final conn = await MySqlConnection.connect(settings);
    try {
      final query = 'DELETE FROM $tableName WHERE $condition';
      await conn.query(query);
      print('[SUCCESS] Data deleted successfully from $tableName');
    } catch (e) {
      print('[ERROR] Failed to delete data: $e');
    } finally {
      await conn.close();
    }
  }

  /// Generate a UUID for the 'id' field
  static Future<String> _generateUUID(MySqlConnection conn) async {
    var result = await conn.query('SELECT UUID()');
    return result.first[0].toString();
  }
}
