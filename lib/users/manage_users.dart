import 'package:flutter/material.dart';
import '../config.dart'; // Import config file
import 'add_user.dart'; // Import the AddUserPage file
import 'edit_user.dart';
import 'view_user.dart';
import '../database_helper.dart'; // Import DatabaseHelper for user data handling

class ManageUsersPage extends StatefulWidget {
  const ManageUsersPage({super.key});

  @override
  _ManageUsersPageState createState() => _ManageUsersPageState();
}

class _ManageUsersPageState extends State<ManageUsersPage> {
  int? selectedUserIndex; // To hold the currently selected user
  List<Map<String, dynamic>> users = []; // List to store user data
  final DatabaseHelper dbHelper = DatabaseHelper(); // Database helper instance

  @override
  void initState() {
    super.initState();
    _initializeDatabase(); // Ensure the database is ready
  }

  Future<void> _initializeDatabase() async {
    await dbHelper.ensureUsersTableExists(); // Ensure the users table exists
    _loadUsers(); // Load users after ensuring the table exists
  }


  Future<void> _loadUsers() async {
    final fetchedUsers = await dbHelper.getUsers();
    setState(() {
      users = fetchedUsers;
      selectedUserIndex = null; // Reset selection
    });
  }

  Future<void> _deleteUser(int id) async {
    await dbHelper.deleteUser(id);
    _loadUsers(); // Reload the user list after deletion
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('User deleted successfully!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Users'),
        backgroundColor: AppColors.colorScheme.primary, // Use color from config
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context); // Back button functionality
          },
        ),
      ),
      body: Column(
        children: <Widget>[
          // Action buttons row
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AddUserPage(),
                      ),
                    );
                    _loadUsers(); // Reload the user list after adding a new user
                  },
                  tooltip: 'Add User',
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: selectedUserIndex != null
                      ? () async {
                          final user = users[selectedUserIndex!];
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: const Text('Confirm Delete'),
                                content: Text('Are you sure you want to delete "${user['name']}"?'),
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
                          );
                          if (confirm == true) {
                            _deleteUser(user['id']);
                          }
                        }
                      : null, // Disable if no user is selected
                  tooltip: 'Delete User',
                ),
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: selectedUserIndex != null
                      ? () async {
                          final user = users[selectedUserIndex!];
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => EditUserPage(
                                id: user['id'], // Pass the user ID
                                name: user['name'],
                                email: user['email'],
                                house: user['house'],
                                userType: user['userType'],
                              ),
                            ),
                          );
                          _loadUsers(); // Reload the users after editing
                        }
                      : null, // Disable if no user is selected
                  tooltip: 'Edit User',
                ),
                IconButton(
                  icon: const Icon(Icons.info),
                  onPressed: selectedUserIndex != null
                      ? () {
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
                      : null, // Disable if no user is selected
                  tooltip: 'View Details',
                ),
              ],
            ),
          ),
          const Divider(), // Divider for visual separation

          // List of Users
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
                              selectedUserIndex = value; // Update selected user index
                            });
                          },
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.more_vert),
                          onPressed: () {
                            // Additional options can be handled here
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
}

