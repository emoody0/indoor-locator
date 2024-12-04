import 'package:flutter/material.dart';
import '../config.dart'; // Import config file
import '../houses/database_helper.dart'; // Import database helper
import '../houses/new_house_setup.dart'; // Import house setup page

class ManageHousesPage extends StatefulWidget {
  const ManageHousesPage({Key? key}) : super(key: key);

  @override
  _ManageHousesPageState createState() => _ManageHousesPageState();
}

class _ManageHousesPageState extends State<ManageHousesPage> {
  int? selectedHouseIndex; // To hold the currently selected house
  List<String> houseNames = []; // Store house names

  @override
  void initState() {
    super.initState();
    _loadHouses();
  }

  Future<void> _loadHouses() async {
    final db = DatabaseHelper();
    final names = await db.getDistinctHouseNames();
    print('Loaded house names: $names'); // Debug log
    setState(() {
      houseNames = names; // Ensure houseNames is updated
    });
  }



  void _viewHouse(String houseName) async {
    final db = DatabaseHelper();
    final houseRooms = await db.getRoomsByHouseName(houseName);
    print('Loaded rooms for house "$houseName": $houseRooms'); // Debug log
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NewHouseSetupPage(
          rooms: houseRooms,
        ),
      ),
    );
  }



  Future<void> _deleteHouse(String houseName) async {
    final db = DatabaseHelper();
    await db.deleteHouseByName(houseName); // Add this function in DatabaseHelper
    await _loadHouses(); // Refresh the list after deletion
  }

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
        actions: [
          IconButton(
            icon: const Icon(Icons.visibility),
            onPressed: selectedHouseIndex != null
                ? () {
                    final selectedHouseName = houseNames[selectedHouseIndex!];
                    _viewHouse(selectedHouseName);
                  }
                : null, // Disable if no house is selected
            tooltip: 'View Selected House',
          ),
        ],
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
                  icon: const Icon(Icons.edit),
                  onPressed: selectedHouseIndex != null
                      ? () async {
                          final selectedHouseName = houseNames[selectedHouseIndex!];
                          final db = DatabaseHelper();
                          final rooms = await db.getRoomsByHouseName(selectedHouseName);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => NewHouseSetupPage(
                                rooms: rooms,
                              ),
                            ),
                          );
                        }
                      : null,
                  tooltip: 'Edit House',
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: selectedHouseIndex != null
                      ? () async {
                          final selectedHouseName = houseNames[selectedHouseIndex!];
                          final confirm = await _showDeleteConfirmation(selectedHouseName);
                          if (confirm) {
                            await _deleteHouse(selectedHouseName);
                          }
                        }
                      : null, // Disable if no house is selected
                  tooltip: 'Delete House',
                ),
                IconButton(
                  icon: const Icon(Icons.info), // For viewing details
                  onPressed: selectedHouseIndex != null
                      ? () {
                          final selectedHouseName = houseNames[selectedHouseIndex!];
                          _showHouseDetails(selectedHouseName);
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
              itemCount: houseNames.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(houseNames[index]),
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

  Future<bool> _showDeleteConfirmation(String houseName) async {
    return await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Delete'),
          content: Text('Are you sure you want to delete "$houseName"?'),
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
    ) ??
        false;
  }

  void _showHouseDetails(String houseName) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('House Details: $houseName'),
          content: Text('This is where house details would be displayed.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }
}
