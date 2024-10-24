import 'package:flutter/material.dart';
import 'config.dart'; // Import config file
import 'add_user.dart'; // Import the AddUserPage file
import 'edit_user.dart';
import 'view_user.dart';
class ManageUsersPage extends StatefulWidget {
  const ManageUsersPage({super.key});

  @override
  _ManageUsersPageState createState() => _ManageUsersPageState();
}

class _ManageUsersPageState extends State<ManageUsersPage> {
  int? selectedUserIndex; // To hold the currently selected user

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
                  onPressed: () {
                    // Navigate to AddUserPage when add button is clicked
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AddUserPage(),
                      ),
                    );
                  },
                  tooltip: 'Add User',
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: selectedUserIndex != null
                      ? () {
                          // Handle Delete User functionality here
                        }
                      : null, // Disable if no user is selected
                  tooltip: 'Delete User',
                ),
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: selectedUserIndex != null
                      ? () {
                          // Navigate to EditUserPage with user details
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => EditUserPage(
                                name: 'User ${selectedUserIndex! + 1}', // Replace with actual user data
                                email: 'user${selectedUserIndex!}@gmail.com', // Example email
                                house: 'House 1', // Example house
                                userType: 'User', // Replace with actual user type
                              ),
                            ),
                          );
                        }
                      : null, // Disable if no user is selected
                  tooltip: 'Edit User',
                ),
                IconButton(
                  icon: const Icon(Icons.info),
                  onPressed: selectedUserIndex != null
                      ? () {
                          // Navigate to ViewUserPage with user details
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ViewUserPage(
                                name: 'User ${selectedUserIndex! + 1}', // Replace with actual user data
                                email: 'user${selectedUserIndex!}@gmail.com', // Example email
                                house: 'House 1', // Example house
                                userType: 'User', // Replace with actual user type
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
            child: ListView.builder(
              itemCount: 10, // Example count, replace with actual user count
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text('User ${index + 1}'), // Example user name
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
                      // Handle user options
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
