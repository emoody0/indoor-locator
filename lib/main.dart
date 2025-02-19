import 'package:flutter/material.dart';
import 'package:workmanager/workmanager.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'database_helper.dart';
import 'admin.dart';
import 'resident.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize notifications
  AwesomeNotifications().initialize(
    'resource://mipmap/ic_launcher',
    [
      NotificationChannel(
        channelKey: 'background_channel',
        channelName: 'Background Notifications',
        channelDescription: 'Notifications for background tasks',
        defaultColor: const Color(0xFF9D50DD),
        ledColor: Colors.white,
        importance: NotificationImportance.High,
      ),
    ],
  );

  // Request notification permissions
  bool isAllowed = await AwesomeNotifications().isNotificationAllowed();
  if (!isAllowed) {
    AwesomeNotifications().requestPermissionToSendNotifications();
  }

  // Initialize WorkManager
  Workmanager().initialize(callbackDispatcher, isInDebugMode: true);
  Workmanager().registerPeriodicTask(
    "backgroundNotificationTask",
    "sendBackgroundNotification",
    frequency: const Duration(minutes: 15),
  );

  runApp(MyApp());
}

void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    print("Background Task Started");
    bool isAllowed = await AwesomeNotifications().isNotificationAllowed();
    if (!isAllowed) {
      print("Notifications are disabled. Exiting task.");
      return Future.value(false);
    }
    AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
        channelKey: 'background_channel',
        title: 'Background Task',
        body: 'This is a background notification.',
        notificationLayout: NotificationLayout.Default,
        icon: 'resource://mipmap/ic_launcher',
      ),
    );
    print("Background Task Running");
    return Future.value(true);
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  Future<String> autoLogin() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    String lastUser = prefs.getString('logged_in_user') ?? ''; // Default to empty string
    int? userId = prefs.getInt('user_id');

    print("DEBUG: Last user from SharedPreferences: $lastUser");
    print("DEBUG: Retrieved user_id from SharedPreferences: $userId");

    final db = DatabaseHelper();

    if (lastUser.isEmpty || userId == null || userId == -1) {
        print("DEBUG: User data is missing, attempting to fetch from DB");

        List<Map<String, dynamic>> users = await db.getUsers();
        for (var user in users) {
            if (user['userType'].toLowerCase() == lastUser.toLowerCase()) {  
                await prefs.setInt('user_id', user['id']); // ✅ Correctly setting user ID
                print("DEBUG: Matched user '${user['name']}' (ID: ${user['id']}) from DB with userType: $lastUser");
                return lastUser;
            }
        }
    }

    print("DEBUG: Returning userType from SharedPreferences: $lastUser");
    return lastUser;  // Ensures non-null return
  }







  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: autoLogin(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const MaterialApp(home: Scaffold(body: Center(child: CircularProgressIndicator())));
        }

        if (snapshot.data == 'admin') {
          return MaterialApp(home: AdminPortal(onLogout: () async {
            final SharedPreferences prefs = await SharedPreferences.getInstance();
            await prefs.remove('logged_in_user');
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
        if (user['userType'].toLowerCase() == userType.toLowerCase()) { // ✅ Ensure proper user type matching
            matchedUser = user;
            break;
        }
    }

    if (matchedUser == null) {
        print("DEBUG: No user found for userType: $userType");
        return;
    }

    await prefs.setString('logged_in_user', userType);
    await prefs.setInt('user_id', matchedUser['id']);

    print("DEBUG: Manually logging in as: ${matchedUser['name']} (ID: ${matchedUser['id']})");

    if (userType.toLowerCase() == 'admin') {
        Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => AdminPortal(onLogout: () async {
                await prefs.remove('logged_in_user');
                await prefs.remove('user_id');
                print("DEBUG: Manual logout executed.");
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
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
