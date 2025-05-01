import 'package:flutter/material.dart';
import '../config.dart';
import 'manage_users_logic.dart';
import 'package:provider/provider.dart';
import '../theme_color_notifier.dart';

class ManageUsersPage extends StatefulWidget {
  const ManageUsersPage({super.key});

  @override
  _ManageUsersPageState createState() => _ManageUsersPageState();
}

class _ManageUsersPageState extends State<ManageUsersPage> {
  int? selectedUserIndex;
  List<Map<String, dynamic>> users = [];
  late ManageUsersLogic logic;

  @override
  void initState() {
    super.initState();
    logic = ManageUsersLogic(
      context: context,
      updateUsers: (newUsers) => setState(() => users = newUsers),
      updateSelectedIndex: (index) => setState(() => selectedUserIndex = index),
    );
    logic.loadUsers();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Users'),
        backgroundColor: Provider.of<ThemeColorNotifier>(context).primaryColor,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: <Widget>[
          _buildActionButtons(),
          const Divider(),
          _buildUserList(),
        ],
      ),
    );
  }

  /// Builds the row of action buttons (Add, Delete, Edit, View)
  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildActionButton(Icons.add, 'Add User', logic.addUser),
          _buildActionButton(
            Icons.delete,
            'Delete User',
            selectedUserIndex != null
                ? () => logic.confirmDeleteUser(
                      users[selectedUserIndex!]['name'],
                      users[selectedUserIndex!]['id'],
                    )
                : null,
          ),
          _buildActionButton(
            Icons.edit,
            'Edit User',
            selectedUserIndex != null
                ? () => logic.editUser(users[selectedUserIndex!])
                : null,
          ),
          _buildActionButton(
            Icons.info,
            'View Details',
            selectedUserIndex != null
                ? () => logic.viewUser(users[selectedUserIndex!])
                : null,
          ),
        ],
      ),
    );
  }

  /// Builds the list of users
  Widget _buildUserList() {
    return Expanded(
      child: users.isEmpty
          ? const Center(child: Text('No users available.'))
          : ListView.builder(
              itemCount: users.length,
              itemBuilder: (context, index) {
                final user = users[index];
                return ListTile(
                  title: Text(user['name']),
                  subtitle: Text(
                   '${user['email']} (${user['userType']}${user['house'] != null && user['house'].isNotEmpty ? ', ${user['house']}' : ''})',
                  ),
                  leading: Radio<int>(
                    value: index,
                    groupValue: selectedUserIndex,
                    onChanged: (value) {
                      setState(() => selectedUserIndex = value);
                    },
                  ),
                );
              },
            ),
    );
  }

  /// Helper function for action buttons
  Widget _buildActionButton(IconData icon, String tooltip, VoidCallback? onPressed) {
    return IconButton(
      icon: Icon(icon),
      tooltip: tooltip,
      onPressed: onPressed,
    );
  }
}
