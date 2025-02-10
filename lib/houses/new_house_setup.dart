import 'package:flutter/material.dart';
import 'room_widget.dart';
import 'room.dart';
import 'sensor.dart';
import 'sensor_configuration.dart';
import '../database_helper.dart';
import 'dart:convert'; // For JSON encoding/decoding

class NewHouseSetupPage extends StatefulWidget {
  final List<Room> rooms;
  final String? houseName; // Optional house name for dynamic title

  const NewHouseSetupPage({
    Key? key,
    this.rooms = const [], // Default to an empty list
    this.houseName, // Pass house name if editing an existing house
  }) : super(key: key);

  @override
  _NewHouseSetupPageState createState() => _NewHouseSetupPageState();
}

class _NewHouseSetupPageState extends State<NewHouseSetupPage> {
  late List<Room> rooms;
  late String title; // Dynamic title for AppBar
  int nextGroupId = 1;
  final double scaleFactor = 10.0;

  @override
  void initState() {
    super.initState();
    rooms = List<Room>.from(widget.rooms);
    title = widget.houseName ?? 'New House Setup';
  }

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
          return;
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
    setState(() {
      if (room.groupId != null) {
        for (Room groupedRoom in rooms.where((r) => r.groupId == room.groupId)) {
          groupedRoom.position += delta;
        }
      } else {
        room.position += delta;
      }
    });
  }

  Future<void> saveHouseToDatabase() async {
    final db = DatabaseHelper();
    String? existingHouseName = rooms.isNotEmpty ? rooms.first.houseName : null;

    if (existingHouseName != null) {
      for (var room in rooms) {
        room.houseName = existingHouseName;

        if (room.id == null) {
          room.id = await db.insertRoom(room);
        } else {
          await db.updateRoom(room);
        }
      }
      _showSnackBar('House "$existingHouseName" updated successfully!');
    } else {
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
                onPressed: () => Navigator.pop(context),
                child: const Text('Save'),
              ),
            ],
          );
        },
      );

      if (nameController.text.isNotEmpty) {
        setState(() {
          title = nameController.text;
        });

        for (var room in rooms) {
          room.houseName = nameController.text;
          room.id = await db.insertRoom(room);
        }
        _showSnackBar('House "${nameController.text}" saved successfully!');
      } else {
        _showSnackBar('House name cannot be empty!');
      }
    }
  }

  Future<bool> _onWillPop() async {
    try {
      await saveHouseToDatabase();
      return true; // Allow navigation after saving
    } catch (e) {
      _showSnackBar('Failed to save the house. Please try again.');
      return false; // Prevent navigation if saving fails
    }
  }







  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Widget _buildSensorIcons(Room room) {
    return Stack(
      children: room.sensors.map((sensor) {
        double iconOffsetX;
        double iconOffsetY;
        switch (sensor.wall) {
          case 'Top':
            iconOffsetX = room.position.dx + (sensor.distanceFromWall * scaleFactor);
            iconOffsetY = room.position.dy + 2; // Close to top boundary
            break;
          case 'Bottom':
            iconOffsetX = room.position.dx + (sensor.distanceFromWall * scaleFactor);
            iconOffsetY = room.position.dy + (room.height * scaleFactor) - 18; // Close to bottom boundary
            break;
          case 'Left':
            iconOffsetX = room.position.dx + 2; // Close to left boundary
            iconOffsetY = room.position.dy + (sensor.distanceFromWall * scaleFactor);
            break;
          case 'Right':
            iconOffsetX = room.position.dx + (room.width * scaleFactor) - 18; // Close to right boundary
            iconOffsetY = room.position.dy + (sensor.distanceFromWall * scaleFactor);
            break;
          default:
            iconOffsetX = room.position.dx;
            iconOffsetY = room.position.dy;
        }
        return Positioned(
          left: iconOffsetX,
          top: iconOffsetY,
          child: const Icon(
            Icons.sensors,
            size: 16,
            color: Colors.red,
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop, // Auto-save when navigating away
      child: Scaffold(
        appBar: AppBar(
          title: Text(title),
          actions: [
            IconButton(
              icon: const Icon(Icons.sensors_rounded),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SensorConfigurationPage(rooms: rooms),
                  ),
                );
              },
              tooltip: 'Configure Sensors',
            ),
          ],
        ),
        body: Stack(
          children: [
            ...rooms.map((room) {
              return Stack(
                children: [
                  Positioned(
                    left: room.position.dx,
                    top: room.position.dy,
                    child: GestureDetector(
                      onPanUpdate: (details) {
                        setState(() {
                          room.position += details.delta;
                        });
                      },
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
                    ),
                  ),
                  _buildSensorIcons(room),
                ],
              );
            }).toList(),
          ],
        ),
        floatingActionButton: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            FloatingActionButton(
              heroTag: 'addRoomButton',
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
            const SizedBox(height: 10),
            FloatingActionButton(
              heroTag: 'saveHouseButton',
              onPressed: saveHouseToDatabase,
              tooltip: 'Save House',
              child: const Icon(Icons.save),
            ),
          ],
        ),
      ),
    );
  }


}
