/*
    THIS FILE IS CURRENTLY UNUSED!!!
*/
import 'package:flutter/material.dart';
import '../config.dart'; // Import config file

class ManageSpacesPage extends StatefulWidget {
  const ManageSpacesPage({super.key});

  @override
  _ManageSpacesPageState createState() => _ManageSpacesPageState();
}

class _ManageSpacesPageState extends State<ManageSpacesPage> {
  int? selectedSensorIndex; // To hold the currently selected Space

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Spaces'),
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
                  tooltip: 'Add Space',
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: selectedSensorIndex != null
                      ? () {
                          // Handle Delete Space functionality here
                        }
                      : null, // Disable if no Space is selected
                  tooltip: 'Delete Space',
                ),
                IconButton(
                  icon: const Icon(Icons.swap_horiz), // For moving spaces
                  onPressed: selectedSensorIndex != null
                      ? () {
                          // Handle Move Space functionality here
                        }
                      : null, // Disable if no Space is selected
                  tooltip: 'Move Space',
                ),
                IconButton(
                  icon: const Icon(Icons.info), // For viewing details
                  onPressed: selectedSensorIndex != null
                      ? () {
                          // Handle View Space Details functionality here
                        }
                      : null, // Disable if no Space is selected
                  tooltip: 'View Details',
                ),
              ],
            ),
          ),
          const Divider(), // Divider for visual separation

          // List of Spaces
          Expanded(
            child: ListView.builder(
              itemCount: 10, // Example count, replace with actual Space count
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text('Space ${index + 1}'), // Example Space name
                  leading: Radio<int>(
                    value: index,
                    groupValue: selectedSensorIndex,
                    onChanged: (value) {
                      setState(() {
                        selectedSensorIndex = value; // Update selected Space index
                      });
                    },
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.more_vert),
                    onPressed: () {
                      // Handle Space options
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
