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
  final double scaleFactor = 10.0; // 10 pixels per ft

  void connectRooms(Room mainRoom, Room targetRoom, String wall, String alignment) {
    setState(() {
      // Assign a common group ID if these rooms are being connected
      if (mainRoom.groupId == null && targetRoom.groupId == null) {
        mainRoom.groupId = nextGroupId;
        targetRoom.groupId = nextGroupId;
        nextGroupId++;
      } else if (mainRoom.groupId != null) {
        targetRoom.groupId = mainRoom.groupId;
      } else {
        mainRoom.groupId = targetRoom.groupId;
      }

      // Calculate new position based on the wall and corner alignment
      Offset newPosition;
      switch (wall) {
        case 'left':
          newPosition = Offset(
            targetRoom.position.dx - mainRoom.width * scaleFactor,  // Attach to left edge
            alignment == 'start'
                ? targetRoom.position.dy  // Align to top-left corner
                : targetRoom.position.dy + targetRoom.height * scaleFactor - mainRoom.height * scaleFactor  // Align to bottom-left corner
          );
          break;
        case 'right':
          newPosition = Offset(
            targetRoom.position.dx + targetRoom.width * scaleFactor, // Attach to right edge
            alignment == 'start'
                ? targetRoom.position.dy  // Align to top-right corner
                : targetRoom.position.dy + targetRoom.height * scaleFactor - mainRoom.height * scaleFactor  // Align to bottom-right corner
          );
          break;
        case 'top':
          newPosition = Offset(
            alignment == 'start'
                ? targetRoom.position.dx  // Align to top-left corner
                : targetRoom.position.dx + targetRoom.width * scaleFactor - mainRoom.width * scaleFactor, // Align to top-right corner
            targetRoom.position.dy - mainRoom.height * scaleFactor  // Attach to top edge
          );
          break;
        case 'bottom':
          newPosition = Offset(
            alignment == 'start'
                ? targetRoom.position.dx  // Align to bottom-left corner
                : targetRoom.position.dx + targetRoom.width * scaleFactor - mainRoom.width * scaleFactor, // Align to bottom-right corner
            targetRoom.position.dy + targetRoom.height * scaleFactor // Attach to bottom edge
          );
          break;
        default:
          return;
      }

      // Update mainRoom's position to connect it to targetRoom with specified alignment
      mainRoom.position = newPosition;
      mainRoom.connectedRoom = targetRoom;
      mainRoom.connectedWall = wall;
      mainRoom.isGrouped = true;
    });
  }



  void moveGroup(Room room, Offset delta) {
    // Move all rooms with the same non-null groupId as the dragged room
    if (room.groupId != null) {
      setState(() {
        for (Room groupedRoom in rooms.where((r) => r.groupId == room.groupId)) {
          groupedRoom.position += delta;
        }
      });
    } else {
      // Move only the individual room if it’s not grouped
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
              ),
            );
          }).toList(),
          Positioned(
            bottom: 20,
            right: 20,
            child: FloatingActionButton(
              onPressed: () {
                setState(() {
                  // Set the default room size closer to realistic dimensions in feet
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
