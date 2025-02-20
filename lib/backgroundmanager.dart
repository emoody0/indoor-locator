import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'database_helper.dart';
import 'dart:isolate';
import 'package:shared_preferences/shared_preferences.dart';

void initializeBackgroundManager() {
  FlutterForegroundTask.startService(
    notificationTitle: 'Indoor Locator',
    notificationText: 'Monitoring location in the background...',
    callback: startCallback,
  );
}

class MyTaskHandler extends TaskHandler {
  @override
  Future<void> onStart(DateTime timestamp, SendPort? sendPort) async {
    print("[DEBUG] Background service started at: $timestamp");
  }

  @override
  Future<void> onRepeatEvent(DateTime timestamp, SendPort? sendPort) async {
    await pingDatabase();
  }

  @override
  Future<void> onDestroy(DateTime timestamp, SendPort? sendPort) async {
    print("[DEBUG] Background service stopped at: $timestamp");
  }

  Future<void> pingDatabase() async {
    print("[DEBUG] Running Database Ping Service at: ${DateTime.now()}");

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    int? userId = prefs.getInt('user_id');
    if (userId == null) {
        print("[DEBUG] No logged-in user found. Skipping database ping.");
        return;
    }

    final db = DatabaseHelper();
    final user = await db.getUserById(userId);
    if (user == null) {
        print("[DEBUG] User ID $userId not found in database. Skipping database ping.");
        return;
    }

    if (user['userType'] != 'User') {
        print("[DEBUG] Logged-in user is an Admin. Skipping database ping.");
        return;
    }

    int startWindowFull = user['start_window'] ?? 28800000; // Stored as full timestamp
    int endWindowFull = user['end_window'] ?? 72000000;   // Stored as full timestamp

    // Convert the stored timestamps to the same daily time scale
    DateTime startDateTime = DateTime.fromMillisecondsSinceEpoch(startWindowFull);
    DateTime endDateTime = DateTime.fromMillisecondsSinceEpoch(endWindowFull);

    int startWindow = (startDateTime.hour * 3600000) + (startDateTime.minute * 60000);
    int endWindow = (endDateTime.hour * 3600000) + (endDateTime.minute * 60000);
    
    int currentTime = DateTime.now().hour * 3600000 + DateTime.now().minute * 60000 + DateTime.now().second * 1000;

    print("[DEBUG] Converted Allowed Window: $startWindow - $endWindow");
    print("[DEBUG] Converted Current Time: $currentTime");

    if (currentTime >= startWindow && currentTime <= endWindow) {
        print("[DEBUG] Within allowed time window. Pinging database...");
        // await db.logPing(DateTime.now()); // Uncomment to enable logging
    } else {
        print("[DEBUG] Outside of allowed time window. Skipping database ping.");
    }
  }

}

// Required callback function for foreground task
@pragma('vm:entry-point')
void startCallback() {
  FlutterForegroundTask.setTaskHandler(MyTaskHandler());
}
