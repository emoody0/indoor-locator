
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'server/database_helper.dart';
import 'admin.dart';
import 'resident.dart';
import 'backgroundmanager.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:permission_handler/permission_handler.dart';

Future<void> requestPermissions() async {
  Map<Permission, PermissionStatus> statuses = await [
    Permission.location,
    Permission.locationWhenInUse,
    Permission.locationAlways,
  ].request();

  if (statuses[Permission.location]!.isDenied ||
      statuses[Permission.locationWhenInUse]!.isDenied ||
      statuses[Permission.locationAlways]!.isDenied) {
    print("⚠️ Location permissions denied!");
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await requestPermissions(); // 🔥 Ensure location permissions are granted

  FlutterForegroundTask.init(
    androidNotificationOptions: AndroidNotificationOptions(
      channelId: 'foreground_service',
      channelName: 'Foreground Service',
      channelDescription: 'Background sensor pings',
      iconData: NotificationIconData(
        resType: ResourceType.mipmap,
        resPrefix: ResourcePrefix.ic,
        name: 'launcher',
      ),
      priority: NotificationPriority.LOW,
      isSticky: true,
    ),
    iosNotificationOptions: const IOSNotificationOptions(
      showNotification: true,
      playSound: false,
    ),
    foregroundTaskOptions: const ForegroundTaskOptions(
      interval: 30000, // Runs every 30 seconds
      autoRunOnBoot: true,
      allowWakeLock: true,
      allowWifiLock: true,
    ),
  );

  // Initialize Foreground Task for Background Execution
  FlutterForegroundTask.init(
    androidNotificationOptions: AndroidNotificationOptions(
      channelId: 'foreground_service',
      channelName: 'Foreground Service',
      channelDescription: 'Background location monitoring',
      iconData: NotificationIconData(
        resType: ResourceType.mipmap,
        resPrefix: ResourcePrefix.ic,
        name: 'launcher',
      ),
      priority: NotificationPriority.LOW,
      isSticky: true,
    ),
    iosNotificationOptions: const IOSNotificationOptions(
      showNotification: true,
      playSound: false,
    ),
    foregroundTaskOptions: const ForegroundTaskOptions(
      interval: 30000, // Runs every 30 seconds
      autoRunOnBoot: true,
      allowWakeLock: true,
      allowWifiLock: true,
    ),
  );

  initializeBackgroundManager(); // Start the background task
  
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  Future<String> autoLogin() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    String lastUser = prefs.getString('logged_in_user') ?? '';
    int? userId = prefs.getInt('user_id');

    final db = DatabaseHelper();
    if (lastUser.isEmpty || userId == null || userId == -1) {
      List<Map<String, dynamic>> users = await db.getUsers();
      for (var user in users) {
        if (user['userType'].toLowerCase() == lastUser.toLowerCase()) {
          await prefs.setInt('user_id', user['id']);
          return lastUser;
        }
      }
    }
    return lastUser;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: autoLogin(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const MaterialApp(
              home: Scaffold(
                  body: Center(child: CircularProgressIndicator())));
        }

        if (snapshot.data == 'admin') {
          return MaterialApp(
              home: AdminPortal(onLogout: () async {
            final SharedPreferences prefs =
                await SharedPreferences.getInstance();
            await prefs.remove('logged_in_user');
            await prefs.remove('user_id');
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const LoginScreen()),
              (Route<dynamic> route) => false,
            );
          }));
        } else if (snapshot.data == 'user') {
          return const MaterialApp(home: ResidentPortal());
        }

        return const MaterialApp(home: LoginScreen());
      },
    );
  }
}

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  Future<void> _manualLogin(String userType, BuildContext context) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final db = DatabaseHelper();

    List<Map<String, dynamic>> users = await db.getUsers();
    Map<String, dynamic>? matchedUser;

    for (var user in users) {
      if (user['userType'].toLowerCase() == userType.toLowerCase()) {
        matchedUser = user;
        break;
      }
    }

    if (matchedUser == null) {
      return;
    }

    await prefs.setString('logged_in_user', userType);
    await prefs.setInt('user_id', matchedUser['id']);

    if (userType.toLowerCase() == 'admin') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (context) => AdminPortal(onLogout: () async {
                  await prefs.remove('logged_in_user');
                  await prefs.remove('user_id');
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const LoginScreen()),
                  );
                })),
      );
    } else if (userType.toLowerCase() == 'user') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const ResidentPortal()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login Screen'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'Select your portal:',
              style: TextStyle(fontSize: 24),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _manualLogin('admin', context),
              child: const Text('Admin Portal'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () => _manualLogin('user', context),
              child: const Text('Resident Portal'),
            ),
          ],
        ),
      ),
    );
  }
}
