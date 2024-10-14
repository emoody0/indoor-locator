import 'package:flutter/material.dart';
import 'config.dart'; // Import the config file
import 'resident.dart'; // Import Resident portal
import 'admin.dart'; // Import Admin portal

void main() {
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
