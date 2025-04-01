import 'package:flutter/material.dart';
import 'room_widget.dart';
import 'room.dart';
import 'sensor_configuration.dart';
import '../server/database_helper.dart';
import '../server/database_service.dart';

class NewHouseSetupPage extends StatefulWidget {
  final List<Room> rooms;
  final String? houseName;

  const NewHouseSetupPage({
    super.key,
    this.rooms = const [],
    this.houseName,
  });

  @override
  _NewHouseSetupPageState createState() => _NewHouseSetupPageState();
}

class _NewHouseSetupPageState extends State<NewHouseSetupPage> {
  late List<Room> rooms;
  late String title;
  int nextGroupId = 1;
  final double scaleFactor = 10.0;
  bool isSaved = false;
  bool hasChanges = false;

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

    double dx = 0;
    double dy = 0;
    double mainRight = mainRoom.position.dx + mainRoom.width * scaleFactor;
    double mainBottom = mainRoom.position.dy + mainRoom.height * scaleFactor;
    double targetWidth = targetRoom.width * scaleFactor;
    double targetHeight = targetRoom.height * scaleFactor;

    switch (wall) {
      case 'left':
        dx = mainRoom.position.dx - targetWidth;
        dy = alignment == 'start'
            ? mainRoom.position.dy
            : mainBottom - targetHeight;
        break;
      case 'right':
        dx = mainRight;
        dy = alignment == 'start'
            ? mainRoom.position.dy
            : mainBottom - targetHeight;
        break;
      case 'top':
        dx = alignment == 'start'
            ? mainRoom.position.dx
            : mainRight - targetWidth;
        dy = mainRoom.position.dy - targetHeight;
        break;
      case 'bottom':
        dx = alignment == 'start'
            ? mainRoom.position.dx
            : mainRight - targetWidth;
        dy = mainBottom;
        break;
    }

    targetRoom.position = Offset(dx, dy);
    hasChanges = true;
  });
}


  void deleteRoom(Room room) {
    setState(() {
      if (room.groupId != null) {
        room.groupId = null;
      }
      rooms.remove(room);
      hasChanges = true;
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
      hasChanges = true;
    });
  }

  Future<void> saveHouseToDatabase() async {
    final db = DatabaseHelper();
    String? existingHouseName = rooms.isNotEmpty ? rooms.first.houseName : null;

    if (existingHouseName != null) {
      for (var room in rooms) {
        room.houseName = existingHouseName;
        await db.insertRoom(room);
      }

      await DatabaseService.sendHouseData(
        nextGroupId,
        existingHouseName,
        rooms.map((r) => r.toJson()).toList(),
      );

      isSaved = true;
      hasChanges = false;
      _showSnackBar('House "$existingHouseName" updated successfully!');
    } else {
      TextEditingController nameController = TextEditingController();
      String? houseName = await showDialog(
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
                onPressed: () => Navigator.pop(context, null),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, nameController.text),
                child: const Text('Save'),
              ),
            ],
          );
        },
      );

      if (houseName != null && houseName.isNotEmpty) {
        setState(() {
          title = houseName;
        });

        for (var room in rooms) {
          room.houseName = houseName;
          await db.insertRoom(room);
        }

        await DatabaseService.sendHouseData(
          nextGroupId,
          houseName,
          rooms.map((r) => r.toJson()).toList(),
        );

        isSaved = true;
        hasChanges = false;
        _showSnackBar('House "$houseName" saved successfully!');
      } else {
        _showSnackBar('House name cannot be empty!');
      }
    }
  }

  Future<bool> _onWillPop() async {
    if (!isSaved && hasChanges) {
      await showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Unsaved Changes'),
            content: const Text('Do you want to save before exiting?'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                child: const Text('Discard'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  await saveHouseToDatabase();
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      );
      return false;
    }
    return true;
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
            iconOffsetY = room.position.dy + 2;
            break;
          case 'Bottom':
            iconOffsetX = room.position.dx + (sensor.distanceFromWall * scaleFactor);
            iconOffsetY = room.position.dy + (room.height * scaleFactor) - 18;
            break;
          case 'Left':
            iconOffsetX = room.position.dx + 2;
            iconOffsetY = room.position.dy + (sensor.distanceFromWall * scaleFactor);
            break;
          case 'Right':
            iconOffsetX = room.position.dx + (room.width * scaleFactor) - 18;
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
      onWillPop: _onWillPop,
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
                          hasChanges = true;
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
                            hasChanges = true;
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
            }),
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
                  hasChanges = true;
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
