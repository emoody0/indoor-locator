import 'package:flutter/material.dart';
import 'package:workmanager/workmanager.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'config.dart'; // Import the config file
import 'resident.dart'; // Import Resident portal
import 'admin.dart'; // Import Admin portal
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'firebase_options.dart';
import 'package:sqflite/sqflite.dart';
import 'database_helper.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/scheduler.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_api_availability/google_api_availability.dart';

class PlatformHelper {
  static bool get isMobile => !kIsWeb && (Platform.isAndroid || Platform.isIOS);
}

void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    print("Background Task Started");

    bool isAllowed = await AwesomeNotifications().isNotificationAllowed();
    if (!isAllowed) {
      print("❌ Notifications are disabled. Requesting permission...");
      await AwesomeNotifications().requestPermissionToSendNotifications();
      return true; // Prevents app crash if user denies permissions.
    }

    await AwesomeNotifications().createNotification(
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
    return Future.value(true); // Explicitly return true
  });
}

Future<void> checkGooglePlayServices() async {
  GooglePlayServicesAvailability availability =
      await GoogleApiAvailability.instance.checkGooglePlayServicesAvailability();

  if (availability != GooglePlayServicesAvailability.success) {
    await GoogleApiAvailability.instance.makeGooglePlayServicesAvailable();
    print("Google Play Services updated.");
  } else {
    print("Google Play Services is up-to-date.");
  }
}


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform, // Works on Web & Mobile
  );
  checkGooglePlayServices();
  //await FirebaseAuth.instance.setPersistence(Persistence.LOCAL);
  // Initialize Awesome Notifications
  User? user = FirebaseAuth.instance.currentUser;

  if (user != null) {
    FirebaseFirestore.instance.collection("users")
      .doc(user.uid)
      .get()
      .then((doc) {
        if (doc.exists) {
          print("Document data: ${doc.data()}");
        } else {
          print("No such document!");
        }
      }).catchError((error) {
        print("Firestore error: $error");
      });
  } else {
    print("No user is signed in. Cannot fetch Firestore data.");
  }

  FirebaseAuth.instance.setLanguageCode('en');
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

  if (!kIsWeb) { // Only run on Android/iOS
    Workmanager().initialize(callbackDispatcher, isInDebugMode: true);
    Workmanager().registerPeriodicTask(
      "backgroundNotificationTask",
      "sendBackgroundNotification",
      frequency: const Duration(minutes: 15),
    );
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Login Screen Demo',
      theme: ThemeData(
        colorScheme: AppColors.colorScheme, 
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const LoginScreen(),
        '/login': (context) => const LoginScreen(),
        '/admin': (context) => const AdminPortal(),
        '/resident': (context) => const ResidentPortal(),
      },
      onUnknownRoute: (settings) {
        return MaterialPageRoute(
          builder: (context) => const LoginScreen(),
        );
      },
    );
  }
}

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  Future<void> _handleNavigationAfterLogin(BuildContext context, User user) async {
    print("🔍 Checking user type for: ${user.email}");

    String? userType;

    try {
      // Hardcode Admin role for your email
      if (user.email == "emily.moody2017@gmail.com") {
        userType = "Admin";
      } else {
        // Check Firestore for user type
        DocumentSnapshot docSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (docSnapshot.exists && docSnapshot.data() != null) {
          userType = docSnapshot.get('userType');
        } else {
          print("❌ User document missing 'userType' field.");
        }
      }
    } catch (e) {
      print("🔥 Error checking Firestore: $e");
    }

    if (!context.mounted) return; // Prevent navigation if widget is disposed

    if (userType == 'Admin') {
      print("✅ Navigating to AdminPortal");
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const AdminPortal()),
      );
    } else {
      print("✅ Navigating to ResidentPortal");
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const ResidentPortal()),
      );
    }
  }



  Future<UserCredential?> signInWithGoogle(BuildContext context) async {
    try {
      print("Attempting Google Sign-In...");
        
      final GoogleSignIn googleSignIn = GoogleSignIn(
        clientId: kIsWeb ? "YOUR_WEB_CLIENT_ID.apps.googleusercontent.com" : null,
      );

      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        print("Google Sign-In cancelled.");
        return null;
      }

      print("Google Sign-In successful: ${googleUser.email}");

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      FirebaseAuth.instance.setLanguageCode('en');

      UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      
      // Ensure FirebaseAuth updates before accessing currentUser
      await Future.delayed(Duration(seconds: 1));

      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print("❌ Firebase Auth: User is null even after sign-in.");
        return null;
      }

      print("✅ Firebase Sign-In successful: ${user.email}");

      _handleNavigationAfterLogin(context, user);

      return userCredential;
    } catch (e) {
      print("❌ Error signing in with Google: $e");
      return null;
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login Screen')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text('Login using Google:', style: TextStyle(fontSize: 20)),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.login),
              label: const Text('Sign in with Google'),
              onPressed: () async {
                UserCredential? userCredential = await signInWithGoogle(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}