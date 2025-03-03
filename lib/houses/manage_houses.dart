import 'package:flutter/material.dart';
import '../config.dart'; // Import config file
import '../server/database_helper.dart'; // Import database helper
import 'new_house_setup.dart'; // Import house setup page
import '../server/database_service.dart';
import 'view_house_page.dart';
import 'room.dart';
import 'dart:typed_data';


class ManageHousesPage extends StatefulWidget {
  const ManageHousesPage({super.key});

  @override
  _ManageHousesPageState createState() => _ManageHousesPageState();
}

class _ManageHousesPageState extends State<ManageHousesPage> {
  int? selectedHouseIndex; // To hold the currently selected house
  List<String> houseNames = []; // Store house names
  final db = DatabaseHelper();

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
                  builder: (context) => const NewHouseSetupPage(
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

                          // Fetch rooms associated with the house
                          final rooms = await db.getRoomsByHouseName(selectedHouseName);

                          // Navigate to the edit screen
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => NewHouseSetupPage(
                                rooms: rooms,
                                houseName: selectedHouseName,
                              ),
                            ),
                          );

                          // Sync the rooms to the server after editing
                          await _updateHouseRooms(selectedHouseName);
                          
                          await _loadHouses(); // Reload house list after editing
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
                          // final db = DatabaseHelper(); // Initialize the database helper
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
      await db.deleteHouseByName(houseName); // Delete from local DB
      
      // Retrieve house ID from MariaDB before deleting
      int? houseId = await DatabaseService.getHouseIdByName(houseName);
      if (houseId != null) {
        await DatabaseService.deleteHouse(houseId); // Delete from MariaDB using house ID
        // print('[MariaDB] Deleted house: $houseName with ID: $houseId'); // Debug log
        await _loadHouses(); // Refresh the list of houses
        _showSnackBar('House "$houseName" deleted successfully!');
      } else {
        // print('[DEBUG] Failed to retrieve house ID for: $houseName');
        _showSnackBar('Failed to delete house "$houseName".');
      }
    }

  Future<void> _loadHouses() async {
    // final db = DatabaseHelper();
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

  Future<void> _updateHouseRooms(String houseName) async {
    try {
      print('[DEBUG] Syncing rooms for house: $houseName');

      // Fetch rooms from local DB
      final localRooms = await db.getRoomsByHouseName(houseName);

      // Fetch rooms from server
      final serverRooms = await DatabaseService.getRoomsByHouseName(houseName);

      // Convert server rooms to a Set for easy comparison
      final serverRoomNames = serverRooms.map((room) => room['name']).toSet();
      final localRoomNames = localRooms.map((room) => room.name).toSet();

      // Determine which rooms to delete from the server
      final roomsToDelete = serverRooms.where((room) => !localRoomNames.contains(room['name'])).toList();

      // Determine which rooms to update or add
      final roomsToUpdate = localRooms.where((room) => serverRoomNames.contains(room.name)).toList();
      final roomsToAdd = localRooms.where((room) => !serverRoomNames.contains(room.name)).toList();

      // Delete removed rooms from server
      for (var room in roomsToDelete) {
        await DatabaseService.deleteRoomByName(houseName, room['name']);
        print('[SUCCESS] Deleted room "${room['name']}" from server.');
      }

      // Update existing rooms on server
      for (var room in roomsToUpdate) {
        await DatabaseService.updateRoom(room);
        print('[SUCCESS] Updated room "${room.name}" on server.');
      }

      // Add new rooms to server
      for (var room in roomsToAdd) {
        await DatabaseService.insertRoom(room);
        print('[SUCCESS] Added room "${room.name}" to server.');
      }

      print('[SUCCESS] Room sync completed for house: $houseName');
    } catch (e) {
      print('[ERROR] Failed to sync rooms for house: $houseName - $e');
    }
  }

  void _showHouseDetails(String houseName) async {
    // Fetch rooms and remove duplicates
    final rooms = (await db.getRoomsByHouseName(houseName)).toSet().toList();

    // Ensure each room is only listed once
    final uniqueRooms = <String, Room>{};
    for (var room in rooms) {
      uniqueRooms[room.name] = room; // Uses the room name as a unique key
    }

    // Format the room details
    String roomDetails = uniqueRooms.values.map((room) {
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