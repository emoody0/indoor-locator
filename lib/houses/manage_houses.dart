import 'package:flutter/material.dart';
import '../config.dart'; // Import config file
import '../houses/database_helper.dart'; // Import database helper
import '../houses/new_house_setup.dart'; // Import house setup page
import 'view_house_page.dart';
import 'room.dart';

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
          // Add the "+" button to create a new house
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Create New House',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => NewHouseSetupPage(
                    rooms: [], // Start with an empty list of rooms
                  ),
                ),
              ).then((_) => _loadHouses()); // Reload house list after returning
            },
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
                                houseName: selectedHouseName,
                              ),
                            ),
                          ).then((_) => _loadHouses()); // Reload house list
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
                            await _deleteHouse(selectedHouseName); // Call delete function
                          }
                        }
                      : null, // Disable if no house is selected
                  tooltip: 'Delete House',
                ),
                IconButton(
                  icon: const Icon(Icons.info), // Info icon
                  onPressed: selectedHouseIndex != null
                      ? () {
                          final selectedHouseName = houseNames[selectedHouseIndex!];
                          _showHouseDetails(selectedHouseName); // Display house details
                        }
                      : null, // Disable if no house is selected
                  tooltip: 'View Details',
                ),
                IconButton(
                  icon: const Icon(Icons.visibility),
                  onPressed: selectedHouseIndex != null
                      ? () async {
                          final db = DatabaseHelper(); // Initialize the database helper
                          final selectedHouseName = houseNames[selectedHouseIndex!]; // Get the selected house name
                          // Fetch rooms from the database
                          final List<Room> rooms = await db.getRoomsByHouseName(selectedHouseName); 
                          // Navigate to the ViewHousePage
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ViewHousePage(rooms: rooms),
                            ),
                          );
                        }
                      : null, // Disable if no house is selected
                  tooltip: 'View House',
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
    ) ?? false;
  }

  Future<void> _deleteHouse(String houseName) async {
    final db = DatabaseHelper();
    await db.deleteHouseByName(houseName); // Delete the house from the database
    print('Deleted house: $houseName'); // Debug log
    await _loadHouses(); // Refresh the list of houses
    _showSnackBar('House "$houseName" deleted successfully!');
  }

  Future<void> _loadHouses() async {
    final db = DatabaseHelper();
    final names = await db.getDistinctHouseNames();
    setState(() {
      houseNames = names; // Refresh the list of house names
      selectedHouseIndex = null; // Clear the selection
    });
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2), // Customize duration as needed
      ),
    );
  }

  void _showHouseDetails(String houseName) async {
    final db = DatabaseHelper();
    final rooms = await db.getRoomsByHouseName(houseName); // Fetch rooms

    // Prepare the room details in a tidy format
    String roomDetails = rooms.map((room) {
      return 'Room: ${room.name}\nDimensions: ${room.width.toStringAsFixed(1)} ft x ${room.height.toStringAsFixed(1)} ft\n';
    }).join('\n');

    // Show the details in a dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Details for "$houseName"'),
          content: Text(roomDetails.isNotEmpty ? roomDetails : 'No rooms found.'),
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
