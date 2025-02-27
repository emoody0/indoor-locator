import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Import for DateFormat
import '../config.dart'; // Import config file
import '../database_helper.dart';

class ViewUserPage extends StatelessWidget {
  final int id; // User ID
  final String name;
  final String email;
  final String house;
  final String userType; // Admin or User
  final int startWindow;
  final int endWindow;

  const ViewUserPage({
    super.key,
    required this.id,
    required this.name,
    required this.email,
    required this.house,
    required this.userType,
    required this.startWindow,
    required this.endWindow,
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
              'User Details',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            _buildDetailRow('User ID', id.toString()),
            _buildDetailRow('User Type', userType),
            _buildDetailRow('Name', name),
            _buildDetailRow('Email', email),
            _buildDetailRow('House', house),
            _buildDetailRow('Start Window', _epochToTime(startWindow)),
            _buildDetailRow('End Window', _epochToTime(endWindow)),
          ],
        ),
      ),
    );
  }

  // Helper method to display user details
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          Text(value, style: const TextStyle(fontSize: 16, color: Colors.black54)),
        ],
      ),
    );
  }

  // Convert epoch time to human-readable format
  String _epochToTime(int epoch) {
    DateTime date = DateTime.fromMillisecondsSinceEpoch(epoch, isUtc: true).toLocal();
    return DateFormat.Hm().format(date);
  }


}
