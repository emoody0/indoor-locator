import 'package:flutter/material.dart';
import '../config.dart';
import '../server/database_helper.dart';

class ViewAlertsPage extends StatefulWidget {
  final bool isAdmin;

  const ViewAlertsPage({super.key, required this.isAdmin});

  @override
  _ViewAlertsPageState createState() => _ViewAlertsPageState();
}

class _ViewAlertsPageState extends State<ViewAlertsPage> {
  String? selectedUser;
  String? selectedHouse;
  String? selectedSensor;

  List<Map<String, dynamic>> users = [];
  List<Map<String, dynamic>> filteredUsers = [];
  List<String> houses = [];
  List<String> sensors = ['Bedroom', 'Living Room', 'Kitchen'];

  @override
  void initState() {
    super.initState();
    fetchUsersAndHouses();
  }

  Future<void> fetchUsersAndHouses() async {
    final db = DatabaseHelper();
    final userList = await db.getUsers();
    final houseList = await db.getDistinctHouseNames();

    setState(() {
      users = userList;
      houses = houseList;
      filteredUsers = users; // Initially, all users are shown
    });
  }

  void onUserSelected(String? userName) {
    setState(() {
      selectedUser = userName;

      if (userName != null) {
        final user = users.firstWhere((user) => user['name'] == userName, orElse: () => {});
        selectedHouse = user['house']; // Autofill house based on user
      }
    });
  }

  void onHouseSelected(String? houseName) {
    setState(() {
      selectedHouse = houseName;

      if (houseName != null) {
        filteredUsers = users.where((user) => user['house'] == houseName).toList();
      } else {
        filteredUsers = users; // Reset to all users if no house is selected
      }

      selectedUser = null; // Reset user selection when house changes
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('View Alerts'),
        backgroundColor: AppColors.primaryColor,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            if (widget.isAdmin) ...[
              DropdownButtonFormField<String>(
                value: selectedHouse,
                decoration: const InputDecoration(labelText: 'Filter by House'),
                items: houses.map((house) {
                  return DropdownMenuItem<String>(
                    value: house,
                    child: Text(house),
                  );
                }).toList(),
                onChanged: onHouseSelected,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedUser,
                decoration: const InputDecoration(labelText: 'Filter by User'),
                items: filteredUsers.map((user) {
                  return DropdownMenuItem<String>(
                    value: user['name'],
                    child: Text(user['name']),
                  );
                }).toList(),
                onChanged: onUserSelected,
              ),
              const SizedBox(height: 16),
            ],
            DropdownButtonFormField<String>(
              value: selectedSensor,
              decoration: const InputDecoration(labelText: 'Filter by Space'),
              items: sensors.map((space) {
                return DropdownMenuItem<String>(
                  value: space,
                  child: Text(space),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedSensor = value;
                });
              },
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  selectedUser = null;
                  selectedHouse = null;
                  selectedSensor = null;
                  filteredUsers = users; // Reset filtered users
                });
              },
              child: const Text('Clear Filters'),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                children: const [
                  Text('Displaying alerts...'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
