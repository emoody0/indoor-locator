import 'package:flutter/material.dart';
import 'package:g14_indoor_locator/server/database_service.dart';
import 'edit_user.dart';
import 'add_user.dart';
import 'view_user.dart';

class ManageUsersLogic {
  final BuildContext context;
  final Function(List<Map<String, dynamic>>) updateUsers;
  final Function(int?) updateSelectedIndex;

  ManageUsersLogic({
    required this.context,
    required this.updateUsers,
    required this.updateSelectedIndex,
  });

  final DatabaseService db = DatabaseService();

  /// Load users from the database
  Future<void> loadUsers() async {
    final fetchedUsers = await db.fetchUsers();
    updateUsers(fetchedUsers.map((user) {
      user['id'] = user['id'].toString(); // Ensure UUIDs are stored as Strings
      return user;
    }).toList());
    updateSelectedIndex(null);
  }

  /// Navigate to the add user page
  Future<void> addUser() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddUserPage()),
    );
    loadUsers(); // Reload users after adding a new user
  }

  /// Navigate to the edit user page
  Future<void> editUser(Map<String, dynamic> user) async {
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
    loadUsers(); // Reload users after editing
  }

  /// Navigate to the view user details page
  void viewUser(Map<String, dynamic> user) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ViewUserPage(
          id: user['id'],
          name: user['name'],
          email: user['email'],
          house: user['house'],
          userType: user['userType'],
          startWindow: user['start_window'],
          endWindow: user['end_window'],
        ),
      ),
    );
  }

  /// Show confirmation dialog and delete user if confirmed
  Future<void> confirmDeleteUser(String userName, String id) async {
    final confirm = await showDialog<bool>(
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
    );
    if (confirm == true) {
      deleteUser(id);
    }
  }

  /// Delete a user from the database
  Future<void> deleteUser(String id) async {
    try {
      await DatabaseService.deleteUser(id);
      await loadUsers();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User deleted successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete user: $e')),
      );
    }
  }

  /// Validate and update user details
  Future<void> validateAndUpdateUser({
    required String id,
    required String name,
    required String email,
    required String userType,
    required String? selectedHouseId,
    required Function() onSuccess,
  }) async {
    if (name.isEmpty || email.isEmpty || selectedHouseId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields.')),
      );
      return;
    }

    int? houseId = int.tryParse(selectedHouseId);
    if (houseId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid house selection.')),
      );
      return;
    }

    try {
      await DatabaseService.updateUser(id, {
        'name': name,
        'email': email,
        'userType': userType,
        'house_id': houseId,
      });

      onSuccess(); // Callback after successful update

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User updated successfully!')),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update user: $e')),
      );
    }
  }

  /// Load house options from the database
  Future<List<Map<String, String>>> loadHouseOptions() async {
    try {
      final houses = await DatabaseService.fetchHouses();
      return houses.map((house) => {
        'id': house['id'].toString(),
        'name': house['name'].toString(),
      }).toList();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load house options: $e')),
      );
      return [];
    }
  }
}
