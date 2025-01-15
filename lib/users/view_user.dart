import 'package:flutter/material.dart';
import '../config.dart'; // Import config file

class ViewUserPage extends StatelessWidget {
  final String name;
  final String email;
  final String house;
  final String userType; // Admin or User

  const ViewUserPage({
    super.key,
    required this.name,
    required this.email,
    required this.house,
    required this.userType,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('View User'),
        backgroundColor: AppColors.colorScheme.primary, // Use color from config
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context); // Back button functionality
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'User Type',
              style: TextStyle(fontSize: 18),
            ),
            Text(
              userType, // Display user type
              style: const TextStyle(fontSize: 16, color: Colors.black54),
            ),
            const SizedBox(height: 20),

            // Display Name
            const Text(
              'Name',
              style: TextStyle(fontSize: 18),
            ),
            Text(
              name, // Display user name
              style: const TextStyle(fontSize: 16, color: Colors.black54),
            ),
            const SizedBox(height: 20),

            // Display Email
            const Text(
              'Email',
              style: TextStyle(fontSize: 18),
            ),
            Text(
              email, // Display email
              style: const TextStyle(fontSize: 16, color: Colors.black54),
            ),
            const SizedBox(height: 20),

            // Display House
            const Text(
              'House',
              style: TextStyle(fontSize: 18),
            ),
            Text(
              house, // Display house
              style: const TextStyle(fontSize: 16, color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }
}
