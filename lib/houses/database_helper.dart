import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'house_database.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE rooms (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT,
            width REAL,
            height REAL,
            posX REAL,
            posY REAL
          )
        ''');
      },
    );
  }

  Future<int> insertRoom(Map<String, dynamic> room) async {
    final db = await database;
    return await db.insert('rooms', room);
  }

  Future<List<Map<String, dynamic>>> getRooms() async {
    final db = await database;
    return await db.query('rooms');
  }

  Future<int> deleteRoom(int id) async {
    final db = await database;
    return await db.delete('rooms', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> clearRooms() async {
    final db = await database;
    await db.delete('rooms');
  }
}
