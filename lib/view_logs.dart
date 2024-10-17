import 'package:flutter/material.dart';
import 'config.dart';

class ViewLogsPage extends StatefulWidget {
  final bool isAdmin;

  const ViewLogsPage({Key? key, required this.isAdmin}) : super(key: key);

  @override
  _ViewLogsPageState createState() => _ViewLogsPageState();
}

class _ViewLogsPageState extends State<ViewLogsPage> {
  String? selectedUser;
  String? selectedHouse;
  String? selectedSensor;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('View Logs'),
        backgroundColor: AppColors.primaryColor,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            if (widget.isAdmin) ...[
              DropdownButtonFormField<String>(
                value: selectedUser,
                decoration: InputDecoration(labelText: 'Filter by User'),
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
              SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedHouse,
                decoration: InputDecoration(labelText: 'Filter by House'),
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
              SizedBox(height: 16),
            ],
            DropdownButtonFormField<String>(
              value: selectedSensor,
              decoration: InputDecoration(labelText: 'Filter by Space'),
              items: <String>['Bedroom', 'Kitchen', 'Bathroom']
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
            SizedBox(height: 16),
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
            SizedBox(height: 16),
            Expanded(
              child: ListView(
                children: [
                  // Here would be the code to display the filtered logs based on the selected criteria.
                  Text('Displaying logs...'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}