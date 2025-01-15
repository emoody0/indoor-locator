import 'package:flutter/material.dart';
import 'room.dart';

class ViewHousePage extends StatelessWidget {
  final List<Room> rooms;

  const ViewHousePage({super.key, required this.rooms});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('View House'),
      ),
      body: Stack(
        children: [
          // Add the grid background
          CustomPaint(
            size: Size.infinite,
            painter: GridPainter(), // Grid painter for feet grid
          ),
          // Add the rooms with an outline
          ...rooms.map((room) {
            return Positioned(
              left: room.position.dx,
              top: room.position.dy,
              child: Container(
                width: room.width * 10.0, // Scale width to pixels
                height: room.height * 10.0, // Scale height to pixels
                decoration: BoxDecoration(
                  color: Colors.blueAccent,
                  border: Border.all(color: Colors.black, width: 2.0), // Add black outline
                ),
                child: Center(
                  child: Text(
                    '${room.name}\n${room.width.toStringAsFixed(1)} ft x ${room.height.toStringAsFixed(1)} ft',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class GridPainter extends CustomPainter {
  final double gridSize = 10.0; // Scale factor for 1 foot (10 pixels)

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.withOpacity(0.5) // Light grey grid lines
      ..strokeWidth = 1.0;

    // Draw vertical lines
    for (double x = 0; x < size.width; x += gridSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    // Draw horizontal lines
    for (double y = 0; y < size.height; y += gridSize) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false; // No need to repaint the grid
  }
}
