import 'package:flutter/material.dart';
import 'room_widget.dart';
import 'room.dart';
import 'database_helper.dart';
import 'dart:convert'; // For JSON encoding/decoding

class NewHouseSetupPage extends StatefulWidget {
  final List<Room> rooms;

  const NewHouseSetupPage({
    Key? key,
    this.rooms = const [], // Default to an empty list
  }) : super(key: key);

  @override
  _NewHouseSetupPageState createState() => _NewHouseSetupPageState();
}



class _NewHouseSetupPageState extends State<NewHouseSetupPage> {
  late List<Room> rooms;

  @override
  void initState() {
    super.initState();
    // Create a modifiable copy of the provided rooms list
    rooms = List<Room>.from(widget.rooms);
  }
  int nextGroupId = 1;
  final double scaleFactor = 10.0;

  void connectRooms(Room mainRoom, Room targetRoom, String wall, String alignment) {
    setState(() {
      if (mainRoom.groupId == null && targetRoom.groupId == null) {
        mainRoom.groupId = nextGroupId;
        targetRoom.groupId = nextGroupId;
        nextGroupId++;
      } else if (mainRoom.groupId != null) {
        targetRoom.groupId = mainRoom.groupId;
      } else {
        mainRoom.groupId = targetRoom.groupId;
      }

      Offset newPosition;

      switch (wall) {
        case 'left':
          newPosition = Offset(
            targetRoom.position.dx - mainRoom.width * scaleFactor,
            alignment == 'start'
                ? targetRoom.position.dy
                : targetRoom.position.dy + targetRoom.height * scaleFactor - mainRoom.height * scaleFactor,
          );
          break;

        case 'right':
          newPosition = Offset(
            targetRoom.position.dx + targetRoom.width * scaleFactor,
            alignment == 'start'
                ? targetRoom.position.dy
                : targetRoom.position.dy + targetRoom.height * scaleFactor - mainRoom.height * scaleFactor,
          );
          break;

        case 'top':
          newPosition = Offset(
            alignment == 'start'
                ? targetRoom.position.dx
                : targetRoom.position.dx + targetRoom.width * scaleFactor - mainRoom.width * scaleFactor,
            targetRoom.position.dy - mainRoom.height * scaleFactor,
          );
          break;

        case 'bottom':
          newPosition = Offset(
            alignment == 'start'
                ? targetRoom.position.dx
                : targetRoom.position.dx + targetRoom.width * scaleFactor - mainRoom.width * scaleFactor,
            targetRoom.position.dy + targetRoom.height * scaleFactor,
          );
          break;

        default:
          return; // No snapping if wall is invalid
      }

      mainRoom.position = newPosition;
      mainRoom.connectedRoom = targetRoom;
      mainRoom.connectedWall = wall;
      mainRoom.isGrouped = true;
    });
  }

  void deleteRoom(Room room) {
    setState(() {
      if (room.groupId != null) {
        room.groupId = null;
      }
      rooms.remove(room);
    });
  }

  void moveGroup(Room room, Offset delta) {
    if (room.groupId != null) {
      setState(() {
        for (Room groupedRoom in rooms.where((r) => r.groupId == room.groupId)) {
          groupedRoom.position += delta;
        }
      });
    } else {
      setState(() {
        room.position += delta;
      });
    }
  }

  void saveHouseToDatabase() async {
    final db = DatabaseHelper();

    String? existingHouseName = rooms.isNotEmpty ? rooms.first.houseName : null;

    if (existingHouseName != null && existingHouseName.isNotEmpty) {
      print('Updating existing house: $existingHouseName');
      for (var room in rooms) {
        room.houseName = existingHouseName; // Ensure houseName is consistent
        if (room.id == null) {
          room.id = await db.insertRoom(room);
          print('Inserted new room with ID: ${room.id}');
        } else {
          print('Updating room with ID: ${room.id}');
          await db.updateRoom(room);
        }
      }
      _showOtherSnackBar('House "$existingHouseName" updated successfully!');
    } else {
      // New house logic remains unchanged
      TextEditingController nameController = TextEditingController();

      await showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Save House'),
            content: TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'House Name'),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      );

      if (nameController.text.isNotEmpty) {
        for (var room in rooms) {
          room.houseName = nameController.text; // Assign house name
          room.id = await db.insertRoom(room); // Insert and save ID
          print('Inserted new room with ID: ${room.id}'); // Debug log
        }
        _showOtherSnackBar('House "${nameController.text}" saved successfully!');
      } else {
        _showOtherSnackBar('House name cannot be empty!');
      }
    }
  }




  
  // Show confirmation message using Snackbar
  void _showOtherSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
      ),
    );
  }


  void loadHouseFromDatabase() async {
    final db = DatabaseHelper();
    List<String> houseNames = await db.getDistinctHouseNames();

    // Show dialog to select a house
    String? selectedHouse = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return SimpleDialog(
          title: const Text('Select a House to Load'),
          children: houseNames
              .map((houseName) => SimpleDialogOption(
                    onPressed: () {
                      Navigator.pop(context, houseName);
                    },
                    child: Text(houseName),
                  ))
              .toList(),
        );
      },
    );

    // Load rooms for the selected house
    if (selectedHouse != null) {
      List<Room> loadedRooms = await db.getRoomsByHouseName(selectedHouse);
      setState(() {
        rooms = loadedRooms;
      });
      print('Loaded house: $selectedHouse');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New House Setup'),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: loadHouseFromDatabase,
            tooltip: 'Load House',
          ),
        ],
      ),
      body: Stack(
        children: [
          ...rooms.map((room) {
            return Positioned(
              left: room.position.dx,
              top: room.position.dy,
              child: RoomWidget(
                room: room,
                rooms: rooms,
                onConnect: (targetRoom, wall, alignment) {
                  connectRooms(room, targetRoom, wall, alignment);
                },
                onUngroup: () {
                  setState(() {
                    room.isGrouped = false;
                    room.connectedRoom = null;
                    room.groupId = null;
                  });
                },
                onMove: (delta) {
                  moveGroup(room, delta);
                },
                onDelete: () => deleteRoom(room),
              ),
            );
          }).toList(),
          Positioned(
            bottom: 20,
            right: 20,
            child: FloatingActionButton(
              heroTag: null,
              onPressed: () {
                setState(() {
                  rooms.add(Room(
                    position: const Offset(50, 50),
                    width: 20.0,
                    height: 20.0,
                  ));
                });
              },
              tooltip: 'Add Room',
              child: const Icon(Icons.add),
            ),
          ),
          Positioned(
            bottom: 80,
            right: 20,
            child: FloatingActionButton(
              heroTag: null,
              onPressed: saveHouseToDatabase,
              tooltip: 'Save House',
              child: const Icon(Icons.save),
            ),
          ),
        ],
      ),
    );
  }
}
