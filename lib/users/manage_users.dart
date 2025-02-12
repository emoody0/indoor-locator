import 'package:flutter/material.dart';
import '../config.dart'; // Import config file
import 'add_user.dart';
import 'edit_user.dart';
import 'view_user.dart';
import 'package:g14_indoor_locator/server/database_service.dart';

class ManageUsersPage extends StatefulWidget {
  const ManageUsersPage({super.key});

  @override
  _ManageUsersPageState createState() => _ManageUsersPageState();
}

class _ManageUsersPageState extends State<ManageUsersPage> {
  int? selectedUserIndex;
  List<Map<String, dynamic>> users = [];
  final db = DatabaseService();

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    final fetchedUsers = await DatabaseService.fetchUsers();
    setState(() {
      users = fetchedUsers.map((user) {
        user['id'] = user['id'].toString(); // Ensure UUIDs are stored as Strings
        return user;
      }).toList();
      selectedUserIndex = null; // Reset selection
    });
  }


  Future<void> _deleteUser(String id) async {
    await DatabaseService.deleteUser(id);
    _loadUsers();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('User deleted successfully!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Users'),
        backgroundColor: AppColors.colorScheme.primary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildActionButton(Icons.add, 'Add User', _addUser),
                _buildActionButton(Icons.delete, 'Delete User', () {
  final user = users[selectedUserIndex!];
  _confirmDeleteUser(user['id'].toString()); // Ensure UUID is passed as String
}),

                _buildActionButton(Icons.edit, 'Edit User', _editUser),
                _buildActionButton(Icons.info, 'View Details', _viewUser),
              ],
            ),
          ),
          const Divider(),

          Expanded(
            child: users.isEmpty
                ? const Center(child: Text('No users available.'))
                : ListView.builder(
                    itemCount: users.length,
                    itemBuilder: (context, index) {
                      final user = users[index];
                      return ListTile(
                        title: Text(user['name']),
                        subtitle: Text('${user['email']} (${user['userType']}, ${user['house']})'),
                        leading: Radio<int>(
                          value: index,
                          groupValue: selectedUserIndex,
                          onChanged: (value) {
                            setState(() {
                              selectedUserIndex = value;
                            });
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  /// Helper function for action buttons
  Widget _buildActionButton(IconData icon, String tooltip, VoidCallback onPressed) {
    return IconButton(
      icon: Icon(icon),
      tooltip: tooltip,
      onPressed: selectedUserIndex != null ? onPressed : null,
    );
  }

  /// User Actions
  Future<void> _addUser() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddUserPage()),
    );
    _loadUsers();
  }

  Future<void> _editUser() async {
    final user = users[selectedUserIndex!];
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditUserPage(
          id: user['id'],
          name: user['name'],
          email: user['email'],
          house: user['house'],
          userType: user['userType'],
        ),
      ),
    );
    _loadUsers();
  }

  Future<void> _confirmDeleteUser(String id) async {
    print('Attempting to delete user with UUID: $id'); // Debugging

    try {
      await DatabaseService.deleteUser(id);
      await _loadUsers(); // Reload user list after deletion
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User deleted successfully!')),
      );
    } catch (e) {
      print('[ERROR] Failed to delete user: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete user: $e')),
      );
    }
  }


  Future<void> _viewUser() async {
    final user = users[selectedUserIndex!];
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ViewUserPage(
          id: user['id'],
          name: user['name'],
          email: user['email'],
          house: user['house'],
          userType: user['userType'],
        ),
      ),
    );
  }

  /// Confirm deletion dialog
  Future<bool> _showDeleteConfirmation(String userName) async {
    return await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Delete'),
          content: Text('Are you sure you want to delete "$userName"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    ) ?? false;
  }
}
