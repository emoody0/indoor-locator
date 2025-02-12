
import 'package:flutter/material.dart';
import 'package:workmanager/workmanager.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'config.dart'; // Import the config file
import 'resident.dart'; // Import Resident portal
import 'admin.dart'; // Import Admin portal

void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    print("Background Task Started");

    // Ensure notifications are allowed
    bool isAllowed = await AwesomeNotifications().isNotificationAllowed();
    if (!isAllowed) {
      print("Notifications are disabled. Exiting task.");
      return Future.value(false);
    }

    // Show a notification using Awesome Notifications
    AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: DateTime.now().millisecondsSinceEpoch.remainder(100000), // Unique ID
        channelKey: 'background_channel',
        title: 'Background Task',
        body: 'This is a background notification.',
        notificationLayout: NotificationLayout.Default,
        icon: 'resource://mipmap/ic_launcher', // Set the icon here
      ),
    );


    print("Background Task Running");
    return Future.value(true);
  });
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Awesome Notifications
  AwesomeNotifications().initialize(
    'resource://mipmap/ic_launcher', // Use generated small icon
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

  // Send a test notification on app start
  AwesomeNotifications().createNotification(
    content: NotificationContent(
      id: DateTime.now().millisecondsSinceEpoch.remainder(100000), // Unique ID
      channelKey: 'background_channel',
      title: 'Background Task',
      body: 'This is a background notification.',
      notificationLayout: NotificationLayout.Default,
      icon: 'resource://mipmap/ic_launcher', // Set the icon here
    ),
  );


  // Initialize WorkManager
  Workmanager().initialize(callbackDispatcher, isInDebugMode: true);

  // Register periodic task (Android requires a minimum of 15 minutes)
  Workmanager().registerPeriodicTask(
    "backgroundNotificationTask",
    "sendBackgroundNotification",
    frequency: const Duration(minutes: 15), // Min interval for background tasks
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Login Screen Demo',
      theme: ThemeData(
        colorScheme: AppColors.colorScheme, // Use color scheme from config
        useMaterial3: true,
      ),
      home: const LoginScreen(),
    );
  }
}

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login Screen'),
        backgroundColor: AppColors.colorScheme.primary, // Primary color from config
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

            // Admin Portal button
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          const AdminPortal()), // Navigate to AdminPortal screen
                );
              },
              child: const Text('Admin Portal'),
            ),
            const SizedBox(height: 10),

            // Resident Portal button
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          const ResidentPortal()), // Navigate to ResidentPortal screen
                );
              },
              child: const Text('Resident Portal'),
            ),
          ],
        ),
      ),
    );
  }
}
