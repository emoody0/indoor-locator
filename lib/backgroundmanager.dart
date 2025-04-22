import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'database_helper.dart';
import 'dart:isolate';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:awesome_notifications/awesome_notifications.dart';

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
    await checkWeeklyAlertSummary(); // new function
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

Future<void> checkWeeklyAlertSummary() async {
  final now = DateTime.now();
  
  // Change these for testing
  const testMode = true;
  final targetDay = DateTime.friday;
  final targetHour = 12;
  final targetMinute = 0;


  if (now.weekday != targetDay || now.hour != targetHour || now.minute != targetMinute) {
    return;
  }
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  final currentUserId = prefs.getInt('user_id');
  print("[DEBUG] Current userId: $currentUserId");
  final db = DatabaseHelper();

  final List<Map<String, dynamic>> allUsers = await db.getUsers();
  print("[DEBUG] All users: $allUsers");
  final oneWeekAgo = now.subtract(const Duration(days: 7));

  final alerts = await db.database.then((db) => db.query(
    'alert_logs',
    where: 'timestamp >= ?',
    whereArgs: [oneWeekAgo.toIso8601String()],
  ));

  // Map of userId -> alertCount
  final Map<int, int> alertCounts = {};

  for (var alert in alerts) {
    final int uid = alert['user_id'] as int;
    alertCounts[uid] = (alertCounts[uid] ?? 0) + 1;
  }


  for (var user in allUsers) {
    final uid = user['id'];
    final count = alertCounts[uid] ?? 0;

    if (uid == currentUserId && user['userType'] == 'User') {
      String msg = count <= 3
        ? "Good job, only $count alerts this week! You deserve some ice cream! 🍦"
        : "Summary: You generated $count alerts this week.";
      _sendNotification(msg);
    }

    if (user['userType'] == 'Admin' && uid == currentUserId) {
      final rewardUsers = allUsers
        .where((u) => u['userType'] == 'User' && (alertCounts[u['id']] ?? 0) <= 3)
        .map((u) => u['name'])
        .join(', ');
      if (rewardUsers.isNotEmpty) {
        _sendNotification("Weekly Reward Summary: $rewardUsers deserve a reward!");
      }
    }
  }

}

void _sendNotification(String message) {
  AwesomeNotifications().createNotification(
    content: NotificationContent(
      id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
      channelKey: 'weekly_alerts',
      title: 'Weekly Summary',
      body: message,
      notificationLayout: NotificationLayout.Default,
    ),
  );
}



// Required callback function for foreground task
@pragma('vm:entry-point')
void startCallback() {
  FlutterForegroundTask.setTaskHandler(MyTaskHandler());
}
