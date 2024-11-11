import 'package:flutter/material.dart';
import 'room_widget.dart';
import 'room.dart';

class NewHouseSetupPage extends StatefulWidget {
  const NewHouseSetupPage({Key? key}) : super(key: key);

  @override
  _NewHouseSetupPageState createState() => _NewHouseSetupPageState();
}

class _NewHouseSetupPageState extends State<NewHouseSetupPage> {
  List<Room> rooms = [];
  int nextGroupId = 1;
  final double scaleFactor = 10.0;

  void connectRooms(Room mainRoom, Room targetRoom, String wall, String alignment) {
    setState(() {
      // Maintain group ID assignment
      if (mainRoom.groupId == null && targetRoom.groupId == null) {
        mainRoom.groupId = nextGroupId;
        targetRoom.groupId = nextGroupId;
        nextGroupId++;
      } else if (mainRoom.groupId != null) {
        targetRoom.groupId = mainRoom.groupId;
      } else {
        mainRoom.groupId = targetRoom.groupId;
      }

      // Calculate new position based on wall and alignment
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
      // Handle grouped rooms on deletion
      if (room.groupId != null) {
        // Remove room from the group, preserving group IDs for other rooms
        room.groupId = null;
      }
      rooms.remove(room); // Remove the room from the list
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
                    room.groupId = null; // Reset group ID on ungrouping
                  });
                },
                onMove: (delta) {
                  moveGroup(room, delta);
                },
                onDelete: () => deleteRoom(room), // Pass deleteRoom callback
              ),
            );
          }).toList(),
          Positioned(
            bottom: 20,
            right: 20,
            child: FloatingActionButton(
              onPressed: () {
                setState(() {
                  rooms.add(Room(position: Offset(50, 50), width: 20.0, height: 20.0));
                });
              },
              child: const Icon(Icons.add),
            ),
          ),
        ],
      ),
    );
  }
}
