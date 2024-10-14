import 'package:flutter/material.dart';
import 'config.dart'; // Import the config file

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile/Details'),
        backgroundColor: AppColors.colorScheme.primary, // Use color scheme from config
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text(
              'Resident Profile',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            // Display resident's profile details (Placeholder for now)
            const Text('Name: John Doe', style: TextStyle(fontSize: 18)),
            const SizedBox(height: 10),
            const Text('Email: johndoe@example.com', style: TextStyle(fontSize: 18)),
            const SizedBox(height: 10),
            const Text('Phone: (123) 456-7890', style: TextStyle(fontSize: 18)),
            const SizedBox(height: 10),
            const Text('Address: 123 Main Street, Cityville', style: TextStyle(fontSize: 18)),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Add functionality for editing profile in the future
              },
              child: const Text('Edit Profile'),
            ),
          ],
        ),
      ),
    );
  }
}
