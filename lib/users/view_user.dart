import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../config.dart';
import '../server/database_service.dart';

class ViewUserPage extends StatefulWidget {
  final String id;

  const ViewUserPage({super.key, required this.id});

  @override
  State<ViewUserPage> createState() => _ViewUserPageState();
}

class _ViewUserPageState extends State<ViewUserPage> {
  Map<String, dynamic>? user;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    try {
      final allUsers = await DatabaseService().fetchUsers();
      final matched = allUsers.firstWhere(
        (u) => u['id'].toString() == widget.id,
        orElse: () => {},
      );

      if (matched.isNotEmpty) {
        setState(() => user = matched);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User not found')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading user: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('View User'),
        backgroundColor: AppColors.colorScheme.primary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: user == null
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'User Details',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  _buildDetailRow('User ID', user!['id']),
                  _buildDetailRow('User Type', user!['userType']),
                  _buildDetailRow('Name', user!['name']),
                  _buildDetailRow('Email', user!['email']),
                  _buildDetailRow('House', user!['house']),
                  _buildDetailRow('Start Window', _epochToTime(user!['start_window'])),
                  _buildDetailRow('End Window', _epochToTime(user!['end_window'])),
                ],
              ),
            ),
    );
  }

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

  String _epochToTime(int epoch) {
    final date = DateTime.fromMillisecondsSinceEpoch(epoch, isUtc: true).toLocal();
    return DateFormat.Hm().format(date);
  }
}
