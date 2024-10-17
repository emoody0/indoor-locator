import 'package:flutter/material.dart';
import 'config.dart'; // Import config file

class ManageHousesPage extends StatefulWidget {
  const ManageHousesPage({super.key});

  @override
  _ManageHousesPageState createState() => _ManageHousesPageState();
}

class _ManageHousesPageState extends State<ManageHousesPage> {
  int? selectedHouseIndex; // To hold the currently selected house

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Houses'),
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
                    // Handle Add User functionality here
                  },
                  tooltip: 'Add House',
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: selectedHouseIndex != null
                      ? () {
                          // Handle Delete House functionality here
                        }
                      : null, // Disable if no house is selected
                  tooltip: 'Delete House',
                ),
                IconButton(
                  icon: const Icon(Icons.info), // For viewing details
                  onPressed: selectedHouseIndex != null
                      ? () {
                          // Handle View House Details functionality here
                        }
                      : null, // Disable if no house is selected
                  tooltip: 'View Details',
                ),
              ],
            ),
          ),
          const Divider(), // Divider for visual separation

          // List of Houses
          Expanded(
            child: ListView.builder(
              itemCount: 10, // Example count, replace with actual house count
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text('House ${index + 1}'), // Example house name
                  leading: Radio<int>(
                    value: index,
                    groupValue: selectedHouseIndex,
                    onChanged: (value) {
                      setState(() {
                        selectedHouseIndex = value; // Update selected house index
                      });
                    },
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.more_vert),
                    onPressed: () {
                      // Handle house options
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
