import 'dart:async';
import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

// Import sqflite_common_ffi for non-mobile platforms
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class HomeAssistantDatabase {
  static final HomeAssistantDatabase _instance = HomeAssistantDatabase._internal();
  factory HomeAssistantDatabase() => _instance;

  static Database? _database;

  HomeAssistantDatabase._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;

    // Initialize databaseFactory for desktop/testing environments
    if (!Platform.isAndroid && !Platform.isIOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final String path = "/homeassistant/home-assistant_v2.db"; 
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS sensor_distance (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              entity_id TEXT NOT NULL,
              distance TEXT NOT NULL,
              attributes TEXT,
              last_updated TEXT NOT NULL
          );
        ''');
        print("Created sensor_distance table if it didn't exist.");
      },
      onOpen: (db) {
        print("Connected to SQLite Database at $path");
      },
    );
  }

  Future<List<Map<String, dynamic>>> query(String table, {String? where, List<dynamic>? whereArgs}) async {
    final db = await database;
    return await db.query(table, where: where, whereArgs: whereArgs);
  }

  Future<int> insert(String table, Map<String, dynamic> data) async {
    try {
      final db = await database;
      return await db.insert(table, data);
    } catch (e) {
      print("Error inserting into $table: $e");
      rethrow;
    }
  }

  Future<int> update(String table, Map<String, dynamic> data, {String? where, List<dynamic>? whereArgs}) async {
    final db = await database;
    return await db.update(table, data, where: where, whereArgs: whereArgs);
  }

  Future<int> delete(String table, {String? where, List<dynamic>? whereArgs}) async {
    final db = await database;
    return await db.delete(table, where: where, whereArgs: whereArgs);
  }

  Future<void> execute(String sql, [List<dynamic>? arguments]) async {
    final db = await database;
    await db.execute(sql, arguments);
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}
