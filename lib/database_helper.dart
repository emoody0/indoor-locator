import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'houses/room.dart';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart' as fb; 
import 'package:cloud_firestore/cloud_firestore.dart';



class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  static const int _databaseVersion = 4; // Incremented to include users table

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
      version: 4, // Update the version number if you have schema changes
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
            name TEXT,
            houseName TEXT,
            groupId INTEGER,
            sensors TEXT DEFAULT "[]" -- Ensure sensors column exists from the start
          )
        ''');

        await db.execute('''
          CREATE TABLE sensors (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            houseName TEXT,
            roomName TEXT,
            position TEXT,
            sensorType TEXT
          )
        ''');

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
    },

      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
            await db.execute('ALTER TABLE rooms ADD COLUMN houseName TEXT');
        }
        if (oldVersion < 4) {
            await db.execute('ALTER TABLE rooms ADD COLUMN sensors TEXT DEFAULT "[]"');
            await db.execute('''
              CREATE TABLE IF NOT EXISTS users (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                name TEXT,
                email TEXT,
                userType TEXT,
                house TEXT,
                organization TEXT
              )
            ''');
        }
    },

    );
  }



  /*Future<void> _migrateDatabase(Database db, int oldVersion, int newVersion) async {
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
  }*/

  // Room-related methods (untouched)
  Future<int> insertRoom(Room room) async {
    print('Updating room: ${room.toJson()}');
    final db = await database;
    //return await db.insert('rooms', room.toJson());
    return await db.insert(
      'rooms',
      room.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace, // Ensures no duplicate insert issues
    );

  }

  Future<int> updateRoom(Room room) async {
    print('Updating room: ${room.toJson()}');
    final db = await database;
    /*return await db.update(
      'rooms',
      room.toJson(),
      where: 'id = ?',
      whereArgs: [room.id],
    );*/
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

  Future<void> clearDatabase() async {
    final dbPath = join(await getDatabasesPath(), 'house_setup.db');
    await deleteDatabase(dbPath);
    _database = null; // Reset cached database instance to avoid errors
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

  Future<void> storeUserInDatabase(fb.User user) async {
    final db = await DatabaseHelper().database;
    final List<Map<String, dynamic>> existingUsers = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [user.email],
    );

    if (existingUsers.isEmpty) {
      String userType = user.email!.endsWith('@admin.com') ? 'Admin' : 'Resident';

      // Save to SQLite
      await db.insert('users', {
        'name': user.displayName ?? 'Unknown',
        'email': user.email,
        'userType': userType,
        'house': null,
        'organization': 'Google Auth',
      });

      // Save to Firestore
      DocumentReference userDoc = FirebaseFirestore.instance.collection('users').doc(user.uid);
      await userDoc.set({
        'name': user.displayName ?? 'Unknown',
        'email': user.email,
        'userType': userType,
        'lastLogin': FieldValue.serverTimestamp(),
      });

      print("✅ User stored: ${user.email} as $userType");
    } else {
      print("⚠️ User already exists: ${user.email}");
    }
  }



  Future<String?> getUserType(String email) async {
    final db = await DatabaseHelper().database;
    final List<Map<String, dynamic>> users = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email],
    );

    if (users.isNotEmpty) {
      return users.first['userType']; // Return "Admin" or "Resident"
    }
    return null;
  }


}
