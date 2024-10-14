import 'package:flutter/material.dart';
import 'config.dart'; // Import config file

class ManageSensorsPage extends StatefulWidget {
  const ManageSensorsPage({super.key});

  @override
  _ManageSensorsPageState createState() => _ManageSensorsPageState();
}

class _ManageSensorsPageState extends State<ManageSensorsPage> {
  int? selectedSensorIndex; // To hold the currently selected sensor

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Sensors'),
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
                  tooltip: 'Add Sensor',
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: selectedSensorIndex != null
                      ? () {
                          // Handle Delete Sensor functionality here
                        }
                      : null, // Disable if no sensor is selected
                  tooltip: 'Delete Sensor',
                ),
                IconButton(
                  icon: const Icon(Icons.swap_horiz), // For moving sensors
                  onPressed: selectedSensorIndex != null
                      ? () {
                          // Handle Move Sensor functionality here
                        }
                      : null, // Disable if no sensor is selected
                  tooltip: 'Move Sensor',
                ),
                IconButton(
                  icon: const Icon(Icons.info), // For viewing details
                  onPressed: selectedSensorIndex != null
                      ? () {
                          // Handle View Sensor Details functionality here
                        }
                      : null, // Disable if no sensor is selected
                  tooltip: 'View Details',
                ),
              ],
            ),
          ),
          const Divider(), // Divider for visual separation

          // List of Sensors
          Expanded(
            child: ListView.builder(
              itemCount: 10, // Example count, replace with actual sensor count
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text('Sensor ${index + 1}'), // Example sensor name
                  leading: Radio<int>(
                    value: index,
                    groupValue: selectedSensorIndex,
                    onChanged: (value) {
                      setState(() {
                        selectedSensorIndex = value; // Update selected sensor index
                      });
                    },
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.more_vert),
                    onPressed: () {
                      // Handle sensor options
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
