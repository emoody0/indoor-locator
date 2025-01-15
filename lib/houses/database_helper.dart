import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'room.dart';
import 'dart:convert';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  static const int _databaseVersion = 2; // Increment the version

  static Database? _database;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'house_setup.db');
    return await openDatabase(
      path,
      version: 3,// we shall see
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE rooms (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              position TEXT,
              width REAL,
              height REAL,
              isGrouped INTEGER,
              connectedRoom TEXT,
              connectedWall TEXT,
              name TEXT, -- Room name
              houseName TEXT, -- House name
              groupId INTEGER
          )
        ''');
      },
      onUpgrade: _migrateDatabase,
    );
  }


  Future<void> _migrateDatabase(Database db, int oldVersion, int newVersion) async {
    print('Upgrading database from $oldVersion to $newVersion');
    if (oldVersion < 2) {
        await db.execute('ALTER TABLE rooms ADD COLUMN houseName TEXT');
    }
    if (oldVersion < 3) {
        await db.execute('ALTER TABLE rooms ADD COLUMN sensors TEXT');
    }
  }





  Future<int> insertRoom(Room room) async {
    print('Updating room: ${room.toJson()}');
    final db = await database;
    return await db.insert('rooms', room.toJson());
  }

  Future<int> updateRoom(Room room) async {
    print('Updating room: ${room.toJson()}');
    final db = await database;
    return await db.update(
      'rooms',
      room.toJson(),
      where: 'id = ?',
      whereArgs: [room.id],
    );
  }



  Future<void> deleteHouseByName(String houseName) async {
    final db = await database;
    print('Deleting house: $houseName'); // Debug log
    await db.delete(
      'rooms',
      where: 'houseName = ?',
      whereArgs: [houseName],
    );
  }



  Future<int> deleteRoom(int id) async {
    final db = await database;
    return await db.delete(
      'rooms',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  void clearDatabase() async {
    final dbPath = join(await getDatabasesPath(), 'house_setup.db');
    await deleteDatabase(dbPath);
  }



  Future<List<String>> getDistinctHouseNames() async {
    final db = await database;
    final List<Map<String, dynamic>> result = await db.rawQuery('SELECT DISTINCT houseName FROM rooms WHERE houseName IS NOT NULL');
    print('Distinct house names from DB: $result'); // Debug log
    return result.map((row) => row['houseName'] as String).toList();
  }


  Future<List<Room>> getRoomsByHouseName(String houseName) async {
    final db = await database;
    final List<Map<String, dynamic>> results = await db.query(
      'rooms',
      where: 'houseName = ?',
      whereArgs: [houseName],
    );
    return results.map((json) => Room.fromJson(json)).toList();
  }



}
