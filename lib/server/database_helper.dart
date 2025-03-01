import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import '../houses/room.dart';
import 'package:intl/intl.dart';
import 'dart:io';


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
    // Ensure databaseFactory is initialized if using sqflite_common_ffi
        // Initialize databaseFactory for desktop/testing environments
    if (!Platform.isAndroid && !Platform.isIOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
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
            organization TEXT,
            start_window INTEGER DEFAULT 28800000,
            end_window INTEGER DEFAULT 72000000,
            is_default INTEGER DEFAULT 1
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
        if (oldVersion < 5) {
          await db.execute("ALTER TABLE users ADD COLUMN start_window INTEGER DEFAULT 28800000");
          await db.execute("ALTER TABLE users ADD COLUMN end_window INTEGER DEFAULT 72000000");
          await db.execute("ALTER TABLE users ADD COLUMN is_default INTEGER DEFAULT 1");
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
    print('[DEBUG] Local DB: Inserting room into SQLite: ${room.toJson()}');
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
    print('Database cleared. Rebuilding...');
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

    // Ensure values are stored as integers
    user['start_window'] = user['start_window'] is String
        ? _timeToEpoch(user['start_window'])
        : user['start_window'] ?? _timeToEpoch('8:00 AM');
    
    user['end_window'] = user['end_window'] is String
        ? _timeToEpoch(user['end_window'])
        : user['end_window'] ?? _timeToEpoch('8:00 PM');
    
    user['is_default'] = user['is_default'] ?? 1;

    return await db.insert('users', user);
  }

  
  int _timeToEpoch(dynamic timeString) {
    if (timeString is int) return timeString; // If already an int, return as is

    try {
        // Extract only the needed part (e.g., "8:00 AM" → "8", "00", "AM")
        final match = RegExp(r'(\d{1,2}):(\d{2})\s*(AM|PM)').firstMatch(timeString.toString());

        if (match == null) {
            throw FormatException("Invalid time format: $timeString");
        }

        int hour = int.parse(match.group(1)!);
        int minute = int.parse(match.group(2)!);
        bool isPM = match.group(3) == 'PM';

        // Convert 12-hour format to 24-hour format
        if (isPM && hour != 12) {
            hour += 12;
        } else if (!isPM && hour == 12) {
            hour = 0;
        }

        DateTime now = DateTime.now();
        DateTime fullDateTime = DateTime(now.year, now.month, now.day, hour, minute);

        return fullDateTime.millisecondsSinceEpoch;
    } catch (e) {
        print("ERROR parsing time: '$timeString' - ${e.toString()}");
        return 28800000; // Default to 8:00 AM if parsing fails
    }
  }




  Future<List<Map<String, dynamic>>> getUsers() async {
  final db = await database;
  List<Map<String, dynamic>> results = await db.query('users');

    if (results.isEmpty) {
      // print("[DEBUG] No users found. Inserting default user...");

      // Insert a default user to bypass login issues
      await insertUser({
        'name': 'Default User',
        'email': 'default@gmail.com',
        'userType': 'User',
        'house': 'No House',
        'organization': 'DefaultOrg',
        'start_window': 28800000,
        'end_window': 72000000,
        'is_default': 1,
      });

      await insertUser({
        'name': 'Default User two',
        'email': 'default2@gmail.com',
        'userType': 'Admin',
        'house': 'No House',
        'organization': 'DefaultOrg',
        'start_window': 28800000,
        'end_window': 72000000,
        'is_default': 1,
      });


      results = await db.query('users'); // Retrieve again after inserting
      // print("[DEBUG] Default user added: $results");
    }
      
    // print("[DEBUG] Retrieved users from DB: $results");
    return results.map((user) {
      return {
        ...user,
        'start_window': user['start_window'] ?? 28800000,
        'end_window': user['end_window'] ?? 72000000,
        'is_default': user['is_default'] ?? 1,
      };
    }).toList();
  }


  Future<Map<String, dynamic>?> getUserById(int userId) async {
    final db = await database;
    final List<Map<String, dynamic>> results = await db.query(
        'users',
        where: 'id = ?',
        whereArgs: [userId],
    );

    if (results.isNotEmpty) {
        // print("DEBUG: Successfully retrieved user ID: $userId -> ${results.first}");
        return results.first;
    } else {
        // print("DEBUG: No user found with ID: $userId");
        return null;
    }
  }





  // Convert epoch (milliseconds) back to "HH:mm a"
  String _epochToTime(dynamic epoch) {
    if (epoch is String) {
        epoch = int.tryParse(epoch) ?? 0;
    }
    
    if (epoch == 0) return "00:00"; // Fallback if conversion fails

    DateTime date = DateTime.fromMillisecondsSinceEpoch(epoch, isUtc: true).toLocal();
    return DateFormat.Hm().format(date); // Convert to HH:mm format
  }





  Future<int> updateUser(int id, Map<String, dynamic> user) async {
    final db = await database;

    // Ensure time values are stored as integers (epoch timestamps)
    user['start_window'] = user.containsKey('start_window') && user['start_window'] is String
        ? _timeToEpoch(user['start_window'])
        : _timeToEpoch('8:00 AM'); // Ensures it defaults to 8 AM only if missing

    user['end_window'] = user.containsKey('end_window') && user['end_window'] is String
        ? _timeToEpoch(user['end_window'])
        : _timeToEpoch('8:00 PM'); // Ensures it defaults to 8 PM only if missing


    return await db.update('users', user, where: 'id = ?', whereArgs: [id]);
  }


  Future<int> deleteUser(int id) async {
    // print('Deleting user with ID $id');
    final db = await database;
    return await db.delete('users', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> updateAdminTimeWindow(int startWindow, int endWindow) async {
    final db = await database;

    // Ensure admin times are updated
    await db.update(
        'users',
        {'start_window': startWindow, 'end_window': endWindow},
        where: 'userType = ?',
        whereArgs: ['Admin'],
    );

    // Update all users who still have the default time settings
    int result = await db.update(
        'users',
        {'start_window': startWindow, 'end_window': endWindow},
        where: 'is_default = 1 AND userType != "Admin"',
    );

    // print("DEBUG: Admin updated time windows for $result users with is_default=1.");
  }


  Future<void> updateUserTimeWindow(int userId, dynamic startWindow, dynamic endWindow) async {
    final db = await database;

    final List<Map<String, dynamic>> userData = await db.query(
        'users',
        columns: ['userType', 'is_default'],
        where: 'id = ?',
        whereArgs: [userId],
    );

    if (userData.isNotEmpty) {
        String userType = userData.first['userType'];
        int isDefault = userData.first['is_default'];

        // ✅ Admins must always have is_default = 1
        if (userType == 'Admin') {
            // print("DEBUG: Admin (ID: $userId) is updating their own time. Ensuring is_default = 1.");

            await db.update(
                'users',
                {
                    'start_window': startWindow is int ? startWindow : _timeToEpoch(startWindow),
                    'end_window': endWindow is int ? endWindow : _timeToEpoch(endWindow),
                    'is_default': 1,  // ✅ Always keep Admin as default!
                },
                where: 'id = ?',
                whereArgs: [userId],
            );
            return;
        }

        // ✅ If a regular user is modifying their time, set `is_default = 0`
        if (isDefault == 1) {
            // print("DEBUG: User ID $userId is customizing their time. Changing is_default = 0.");
        } else {
            // print("DEBUG: User ID $userId already has custom settings (is_default=0). Keeping as is.");
        }
    }

    // 🚀 Update user time and set `is_default = 0` only if they were previously default
    await db.update(
        'users',
        {
            'start_window': startWindow is int ? startWindow : _timeToEpoch(startWindow),
            'end_window': endWindow is int ? endWindow : _timeToEpoch(endWindow),
            'is_default': 0,  // ✅ This only applies to regular users
        },
        where: 'id = ? AND is_default = 1',
        whereArgs: [userId],
    );

    // print("DEBUG: updateUserTimeWindow completed for user ID: $userId");
  }


  Future<void> verifyDatabaseUpdate(int userId) async {
    final db = await database;
    final result = await db.query('users', where: 'id = ?', whereArgs: [userId]);
    // print("DEBUG: Retrieved user after update: $result");
  }

  Future<void> revertToDefaultTimeWindow(int userId) async {
    final db = await database;

    // Get ANY admin's current time settings (since all admins should share the same default)
    final List<Map<String, dynamic>> adminTime = await db.query(
        'users',
        columns: ['start_window', 'end_window'],
        where: 'userType = "Admin"',
        orderBy: 'id ASC',
        limit: 1,
    );

    if (adminTime.isEmpty) {
        // print("DEBUG: No admin found. Cannot revert user ID $userId to default.");
        return;
    }

    int defaultStart = adminTime.first['start_window'];
    int defaultEnd = adminTime.first['end_window'];

    int result = await db.update(
        'users',
        {'start_window': defaultStart, 'end_window': defaultEnd, 'is_default': 1},
        where: 'id = ?',
        whereArgs: [userId],
    );

    // print("DEBUG: User ID $userId reverted to admin's default settings (Start: $defaultStart, End: $defaultEnd).");
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
      // print('Users table does not exist. Creating...');
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
      // print('Users table created.');
    } else {
      // print('Users table already exists.');
    }
  }


}
