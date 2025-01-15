import 'package:flutter/material.dart';
import '../config.dart';

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
                value: selectedUser,
                decoration: const InputDecoration(labelText: 'Filter by User'),
                items: <String>['User1', 'User2', 'User3']
                    .map((user) => DropdownMenuItem(
                          value: user,
                          child: Text(user),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    selectedUser = value;
                  });
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedHouse,
                decoration: const InputDecoration(labelText: 'Filter by House'),
                items: <String>['House1', 'House2', 'House3']
                    .map((house) => DropdownMenuItem(
                          value: house,
                          child: Text(house),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    selectedHouse = value;
                  });
                },
              ),
              const SizedBox(height: 16),
            ],
            DropdownButtonFormField<String>(
              value: selectedSensor,
              decoration: const InputDecoration(labelText: 'Filter by Space'),
              items: <String>['Bedroom', 'Living Room', 'Kitchen']
                  .map((space) => DropdownMenuItem(
                        value: space,
                        child: Text(space),
                      ))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  selectedSensor = value;
                });
              },
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                // Clear the filter selections
                setState(() {
                  selectedUser = null;
                  selectedHouse = null;
                  selectedSensor = null;
                });
              },
              child: const Text('Clear Filters'),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                children: const [
                  // Here would be the code to display the filtered alerts based on the selected criteria.
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