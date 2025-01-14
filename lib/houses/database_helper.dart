import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'room.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;

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
      version: 2,
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
    if (oldVersion < 2) {
      // Check if the 'houseName' column already exists
      final tableInfo = await db.rawQuery("PRAGMA table_info(rooms)");
      final columnExists = tableInfo.any((column) => column['name'] == 'houseName');

      if (!columnExists) {
        await db.execute('ALTER TABLE rooms ADD COLUMN houseName TEXT');
        print('Added column houseName to rooms table');
      } else {
        print('Column houseName already exists in rooms table');
      }
    }
  }


  Future<int> insertRoom(Room room) async {
    final db = await database;
    int id = await db.insert('rooms', room.toJson());
    print('Inserted room with ID: $id'); // Debug log
    return id;
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

  


  Future<int> updateRoom(Room room) async {
    final db = await database;
    print('Updating room with ID: ${room.id}'); // Debug log
    return await db.update(
      'rooms',
      room.toJson(),
      where: 'id = ?',
      whereArgs: [room.id],
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

  Future<void> clearDatabase() async {
    final db = await database;
    await db.delete('rooms');
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
