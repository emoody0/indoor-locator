import 'package:mysql1/mysql1.dart';

class DatabaseService {
  // Database connection settings
  static final ConnectionSettings settings = ConnectionSettings(
    host: '127.0.0.1', // Replace with your MariaDB server's IP or localhost (if port-forwarded)
    port: 3306,        // MariaDB port (default is 3306)
    user: 'homeassistant', // Replace with your MariaDB username
    password: 'SQL123!', // Replace with your MariaDB password
    db: 'homeassistant',      // Replace with your database name
  );

  /// Test database connection
  static Future<void> testConnection() async {
    print('Attempting to connect to the database...');
    try {
      // Establish a connection
      final conn = await MySqlConnection.connect(settings);
      print('[SUCCESS] Connected to the database!');

      // Close the connection
      await conn.close();
      print('[INFO] Database connection closed.');
    } catch (e) {
      print('[ERROR] Failed to connect to the database: $e');
    }
  }

  
  static Future<List<Map<String, dynamic>>> fetchData(String tableName) async {
    final conn = await MySqlConnection.connect(settings);
    try {
      print('[INFO] Querying table: $tableName');
      final results = await conn.query('SELECT * FROM $tableName');

      // Convert the results into a list of maps
      final data = results.map((row) {
        final map = <String, dynamic>{};
        for (var columnName in row.fields.keys) {
          map[columnName] = row[columnName];
        }
        return map;
      }).toList();

      print('[SUCCESS] Data fetched successfully: $data');
      return data;
    } catch (e) {
      print('[ERROR] Failed to query table: $e');
      rethrow; // Rethrow the error for handling in the UI
    } finally {
      await conn.close();
      print('[INFO] Database connection closed.');
    }
  }


  /// Insert data into a specific table
  static Future<void> insertData(String tableName, Map<String, dynamic> data) async {
    print('Inserting data into table: $tableName...');
    print('[INFO] Data: $data');
    try {
      final conn = await MySqlConnection.connect(settings);
      print('[SUCCESS] Connected to the database.');

      // Construct query and parameters
      var fields = data.keys.join(', ');
      var placeholders = data.keys.map((key) => '?').join(', ');
      var values = data.values.toList();

      // Execute the INSERT query
      var query = 'INSERT INTO $tableName ($fields) VALUES ($placeholders)';
      await conn.query(query, values);
      print('[SUCCESS] Data inserted successfully into table: $tableName');

      // Close the connection
      await conn.close();
      print('[INFO] Database connection closed.');
    } catch (e) {
      print('[ERROR] Failed to insert data: $e');
    }
  }


  static Future<void> deleteData(String tableName, String condition) async {
  final conn = await MySqlConnection.connect(settings);
  try {
    // Execute the DELETE query
    final query = 'DELETE FROM $tableName WHERE $condition';
    print('[INFO] Executing query: $query');
    await conn.query(query);
    print('[SUCCESS] Data deleted successfully from $tableName');
  } catch (e) {
    print('[ERROR] Failed to delete data: $e');
    rethrow; // Rethrow the error for handling in the UI
  } finally {
    await conn.close();
    print('[INFO] Database connection closed.');
  }
}

}
