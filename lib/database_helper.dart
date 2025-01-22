import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'houses/room.dart';
import 'dart:convert';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  static const int _databaseVersion = 3; // Incremented to include users table

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
      version: _databaseVersion,
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
        '''); // Unchanged: Room table creation

        await db.execute('''
          CREATE TABLE users (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              name TEXT,
              email TEXT,
              userType TEXT,
              house TEXT,
              organization TEXT
          )
        '''); // User table creation
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
      await db.execute('''
        CREATE TABLE IF NOT EXISTS users (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT,
            email TEXT,
            userType TEXT,
            house TEXT,
            organization TEXT
        )
      '''); // Create users table if it does not exist
    }
  }

  // Room-related methods (untouched)
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
    print('Deleting house: $houseName');
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
    final List<Map<String, dynamic>> result =
        await db.rawQuery('SELECT DISTINCT houseName FROM rooms WHERE houseName IS NOT NULL');
    print('Distinct house names from DB: $result');
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

  // User-related methods
  Future<int> insertUser(Map<String, dynamic> user) async {
    print('Inserting user: $user');
    final db = await database;
    return await db.insert('users', user);
  }

  Future<List<Map<String, dynamic>>> getUsers() async {
    final db = await database;
    final List<Map<String, dynamic>> users = await db.query('users');
    print('Retrieved users: $users');
    return users;
  }

  Future<int> updateUser(int id, Map<String, dynamic> user) async {
    print('Updating user with ID $id: $user');
    final db = await database;
    return await db.update('users', user, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteUser(int id) async {
    print('Deleting user with ID $id');
    final db = await database;
    return await db.delete('users', where: 'id = ?', whereArgs: [id]);
  }


  Future<bool> tableExists(String tableName) async {
    final db = await database;
    final result = await db.rawQuery(
      '''
      SELECT name 
      FROM sqlite_master 
      WHERE type='table' AND name=? LIMIT 1
      ''',
      [tableName],
    );
    return result.isNotEmpty;
  }

  Future<void> ensureUsersTableExists() async {
    final db = await database;
    final result = await db.rawQuery(
      '''
      SELECT name 
      FROM sqlite_master 
      WHERE type='table' AND name='users'
      '''
    );

    if (result.isEmpty) {
      print('Users table does not exist. Creating...');
      await db.execute('''
        CREATE TABLE users (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT,
            email TEXT,
            userType TEXT,
            house TEXT,
            organization TEXT
        )
      ''');
      print('Users table created.');
    } else {
      print('Users table already exists.');
    }
  }


}
