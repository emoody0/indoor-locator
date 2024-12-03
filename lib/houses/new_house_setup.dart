import 'package:flutter/material.dart';
import 'room_widget.dart';
import 'room.dart';
import 'dart:convert'; // For JSON encoding/decoding

class NewHouseSetupPage extends StatefulWidget {
  const NewHouseSetupPage({Key? key}) : super(key: key);

  @override
  _NewHouseSetupPageState createState() => _NewHouseSetupPageState();
}

class _NewHouseSetupPageState extends State<NewHouseSetupPage> {
  List<Room> rooms = [];
  int nextGroupId = 1;
  final double scaleFactor = 10.0;
  String simulatedDatabase = ""; // Simulated database

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

  void saveHouseToDatabase() {
    String houseData = jsonEncode(rooms.map((room) => room.toJson()).toList());
    simulatedDatabase = houseData;
    print('House saved: $houseData');
  }

  void loadHouseFromDatabase() {
    if (simulatedDatabase.isNotEmpty) {
      List<dynamic> houseData = jsonDecode(simulatedDatabase);
      setState(() {
        rooms = houseData.map((data) => Room.fromJson(data)).toList();
      });
      print('House loaded: $simulatedDatabase');
    } else {
      print('No saved house data found.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New House Setup')),
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
              onPressed: () {
                setState(() {
                  rooms.add(Room(
                    position: const Offset(50, 50),
                    width: 20.0,
                    height: 20.0,
                  ));
                });
              },
              child: const Icon(Icons.add),
            ),
          ),
          Positioned(
            bottom: 80,
            right: 20,
            child: FloatingActionButton(
              onPressed: saveHouseToDatabase,
              child: const Icon(Icons.save),
            ),
          ),
          Positioned(
            bottom: 140,
            right: 20,
            child: FloatingActionButton(
              onPressed: loadHouseFromDatabase,
              child: const Icon(Icons.download),
            ),
          ),
        ],
      ),
    );
  }
}
