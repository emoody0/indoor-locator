// room_widget.dart
import 'package:flutter/material.dart';
import 'dart:math' as math;

enum RoomShape { rectangle, lShape }

class RoomWidget extends StatefulWidget {
  final Function(Key) onDelete;

  const RoomWidget({super.key, required this.onDelete});

  @override
  _RoomWidgetState createState() => _RoomWidgetState();
}

class _RoomWidgetState extends State<RoomWidget> {
  double width = 150; // Width of the main section
  double height = 150; // Height of the main section
  RoomShape shape = RoomShape.rectangle;
  double lSectionWidth = 75; // Width of the L-section
  double lSectionHeight = 50; // Height of the L-section
  double rotationAngle = 0.0; // In radians
  Offset position = const Offset(50, 100);
  bool isLocked = false;
  String roomName = 'Room';

  void _showResizeDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        double newWidthFeet = width / 10;
        double newHeightFeet = height / 10;
        double newLSectionWidthFeet = lSectionWidth / 10;
        double newLSectionHeightFeet = lSectionHeight / 10;
        return AlertDialog(
          title: const Text('Resize Room'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Width (ft)',
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  newWidthFeet = double.tryParse(value) ?? newWidthFeet;
                },
              ),
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Height (ft)',
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  newHeightFeet = double.tryParse(value) ?? newHeightFeet;
                },
              ),
              if (shape == RoomShape.lShape) ...[
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'L-Section Width (ft)',
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    newLSectionWidthFeet = double.tryParse(value) ?? newLSectionWidthFeet;
                  },
                ),
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'L-Section Height (ft)',
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    newLSectionHeightFeet = double.tryParse(value) ?? newLSectionHeightFeet;
                  },
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  width = newWidthFeet * 10;
                  height = newHeightFeet * 10;
                  if (shape == RoomShape.lShape) {
                    lSectionWidth = newLSectionWidthFeet * 10;
                    lSectionHeight = newLSectionHeightFeet * 10;
                  }
                });
                Navigator.pop(context);
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _showRotationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        double newRotationDegrees = rotationAngle * (180 / math.pi); // Convert to degrees
        return AlertDialog(
          title: const Text('Rotate Room'),
          content: TextField(
            decoration: const InputDecoration(
              labelText: 'Rotation (degrees)',
            ),
            keyboardType: TextInputType.number,
            onChanged: (value) {
              newRotationDegrees = double.tryParse(value) ?? newRotationDegrees;
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  rotationAngle = newRotationDegrees * (math.pi / 180); // Convert back to radians
                });
                Navigator.pop(context);
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: position.dx,
      top: position.dy,
      child: GestureDetector(
        onPanUpdate: !isLocked
            ? (details) {
                setState(() {
                  position = Offset(
                    position.dx + details.delta.dx,
                    position.dy + details.delta.dy,
                  );
                });
              }
            : null,
        onLongPress: () {
          showModalBottomSheet(
            context: context,
            builder: (BuildContext context) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    leading: const Icon(Icons.edit),
                    title: const Text('Change Room Shape'),
                    onTap: () {
                      setState(() {
                        shape = shape == RoomShape.rectangle
                            ? RoomShape.lShape
                            : RoomShape.rectangle;
                        // Adjust default dimensions to create an L-shape when switching
                        if (shape == RoomShape.lShape) {
                          width = 120;
                          height = 100;
                          lSectionWidth = 60;
                          lSectionHeight = 40;
                        }
                      });
                      Navigator.pop(context);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.aspect_ratio),
                    title: const Text('Resize Room'),
                    onTap: () {
                      Navigator.pop(context);
                      _showResizeDialog();
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.rotate_right),
                    title: const Text('Rotate Room'),
                    onTap: () {
                      Navigator.pop(context);
                      _showRotationDialog();
                    },
                  ),
                  ListTile(
                    leading: Icon(isLocked ? Icons.lock_open : Icons.lock),
                    title: Text(isLocked ? 'Unlock' : 'Lock in Place'),
                    onTap: () {
                      setState(() {
                        isLocked = !isLocked;
                      });
                      Navigator.pop(context);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.delete),
                    title: const Text('Delete Room'),
                    onTap: () {
                      Navigator.pop(context);
                      widget.onDelete(widget.key!);
                    },
                  ),
                ],
              );
            },
          );
        },
        child: Transform.rotate(
          angle: rotationAngle,
          child: _buildRoomShape(),
        ),
      ),
    );
  }

  Widget _buildRoomShape() {
    if (shape == RoomShape.rectangle) {
      return Container(
        width: width,
        height: height,
        color: Colors.blueAccent,
        child: Center(
          child: Text(
            '$roomName\n${(width / 10).toStringAsFixed(1)} ft x ${(height / 10).toStringAsFixed(1)} ft',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      );
    } else if (shape == RoomShape.lShape) {
      return Stack(
        children: [
          Container(
            width: width,
            height: height,
            color: Colors.blueAccent,
          ),
          Positioned(
            left: width - lSectionWidth, // Position L-section to the right of main
            top: height - lSectionHeight, // Position L-section to the bottom of main
            child: Container(
              width: lSectionWidth,
              height: lSectionHeight,
              color: Colors.blue[700],
            ),
          ),
          Center(
            child: Text(
              '$roomName\n${(width / 10).toStringAsFixed(1)} ft x ${(height / 10).toStringAsFixed(1)} ft',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      );
    }
    return Container();
  }
}
