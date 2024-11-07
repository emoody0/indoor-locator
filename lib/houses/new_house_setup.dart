import 'package:flutter/material.dart';
import '../config.dart';
import 'room_widget.dart';

class NewHouseSetupPage extends StatefulWidget {
  const NewHouseSetupPage({super.key});

  @override
  _NewHouseSetupPageState createState() => _NewHouseSetupPageState();
}

class _NewHouseSetupPageState extends State<NewHouseSetupPage> {
  String houseName = 'New House';
  List<Map<String, dynamic>> roomData = []; // Stores position and size of each room
  final double snapThreshold = 5.0; // Reduced snap threshold for finer control

  // Function to handle snapping only if within threshold on drag end
  void handleRoomMoved(Offset movedPosition, int movedIndex, double newWidth, double newHeight) {
    final movedRoom = roomData[movedIndex];
    Offset newPosition = movedPosition;

    for (int i = 0; i < roomData.length; i++) {
      if (i != movedIndex) {
        final stationaryRoom = roomData[i];
        final roomPosition = stationaryRoom['position'];
        final roomWidth = stationaryRoom['width'];
        final roomHeight = stationaryRoom['height'];

        // Define corners of the moved room
        Offset movedTopLeft = movedPosition;
        Offset movedTopRight = Offset(movedPosition.dx + movedRoom['width'], movedPosition.dy);
        Offset movedBottomLeft = Offset(movedPosition.dx, movedPosition.dy + movedRoom['height']);
        Offset movedBottomRight = Offset(movedPosition.dx + movedRoom['width'], movedPosition.dy + movedRoom['height']);

        // Define corners of the stationary room
        Offset roomTopLeft = roomPosition;
        Offset roomTopRight = Offset(roomPosition.dx + roomWidth, roomPosition.dy);
        Offset roomBottomLeft = Offset(roomPosition.dx, roomPosition.dy + roomHeight);
        Offset roomBottomRight = Offset(roomPosition.dx + roomWidth, roomPosition.dy + roomHeight);

        // Check snapping proximity and update newPosition accordingly
        if ((movedTopLeft - roomTopRight).distance < snapThreshold) {
          newPosition = Offset(roomTopRight.dx, roomTopRight.dy);
        } else if ((movedTopRight - roomTopLeft).distance < snapThreshold) {
          newPosition = Offset(roomTopLeft.dx - movedRoom['width'], roomTopLeft.dy);
        } else if ((movedBottomLeft - roomBottomRight).distance < snapThreshold) {
          newPosition = Offset(roomBottomRight.dx, roomBottomRight.dy - movedRoom['height']);
        } else if ((movedBottomRight - roomBottomLeft).distance < snapThreshold) {
          newPosition = Offset(roomBottomLeft.dx - movedRoom['width'], roomBottomLeft.dy - movedRoom['height']);
        }
      }
    }

    // Only update position if snapping is applied
    if (newPosition != movedPosition) {
      setState(() {
        roomData[movedIndex]['position'] = newPosition;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(houseName),
        backgroundColor: AppColors.colorScheme.primary,
      ),
      body: Stack(
        children: [
          // Display each RoomWidget with updated position from roomData
          ...List.generate(roomData.length, (index) {
            final room = roomData[index];
            return Positioned(
              left: room['position'].dx,
              top: room['position'].dy,
              child: RoomWidget(
                key: UniqueKey(),
                initialWidth: room['width'],   // Pass initial width
                initialHeight: room['height'], // Pass initial height
                onDelete: (key) {
                  setState(() {
                    roomData.removeAt(index);
                  });
                },
                onRoomMoved: (position, width, height) { // Pass position, width, and height
                  setState(() {
                    roomData[index]['position'] = position;
                    roomData[index]['width'] = width;   // Store new width
                    roomData[index]['height'] = height; // Store new height
                  });
                  handleRoomMoved(position, index, width, height);
                },
              ),
            );
          }),
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Center(
              child: ElevatedButton(
                onPressed: () {
                  setState(() {
                    roomData.add({
                      'position': Offset(50, 100),
                      'width': 150.0,
                      'height': 150.0,
                    });
                  });
                },
                child: const Text('Add Room'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
