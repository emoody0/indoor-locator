import 'package:flutter/material.dart';
import '../houses/room.dart';

class HouseMap extends StatelessWidget {
  final List<Room> rooms;
  final Offset? tagPosition;

  const HouseMap({
    super.key,
    required this.rooms,
    this.tagPosition,
  });

  static const double _scale = 10.0;

  @override
  Widget build(BuildContext context) {
    final bounds = _calculateCanvasBounds(rooms);

    return SizedBox(
      width: bounds.width,
      height: bounds.height,
      child: Stack(
        children: [
          const _GridBackground(),
          ...rooms.expand((room) => [
                Positioned(
                  left: room.position.dx * _scale + bounds.offset.dx,
                  top: room.position.dy * _scale + bounds.offset.dy,
                  child: Container(
                    width: room.width * _scale,
                    height: room.height * _scale,
                    decoration: BoxDecoration(
                      color: Colors.blueAccent.withOpacity(0.4),
                      border: Border.all(color: Colors.black, width: 2),
                    ),
                    child: Center(
                      child: Text(
                        room.name,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ),
                ..._buildSensors(room, bounds.offset),
              ]),
          if (tagPosition != null)
            Positioned(
              left: tagPosition!.dx * _scale + bounds.offset.dx,
              top: tagPosition!.dy * _scale + bounds.offset.dy,
              child: const Icon(Icons.person_pin_circle,
                  color: Colors.green, size: 30),
            ),
        ],
      ),
    );
  }

  static List<Widget> _buildSensors(Room room, Offset mapOffset) {
    return room.sensors.map((sensor) {
      double dx, dy;
      const double iconSize = 16.0;

      switch (sensor.wall) {
        case 'Top':
          dx = room.position.dx + sensor.distanceFromWall;
          dy = room.position.dy;
          break;
        case 'Bottom':
          dx = room.position.dx + sensor.distanceFromWall;
          dy = room.position.dy + room.height;
          break;
        case 'Left':
          dx = room.position.dx;
          dy = room.position.dy + sensor.distanceFromWall;
          break;
        case 'Right':
          dx = room.position.dx + room.width;
          dy = room.position.dy + sensor.distanceFromWall;
          break;
        default:
          dx = room.position.dx;
          dy = room.position.dy;
      }

      return Positioned(
        left: dx * _scale + mapOffset.dx - iconSize / 2,
        top: dy * _scale + mapOffset.dy - iconSize / 2,
        child: Tooltip(
          message: sensor.name,
          child: const Icon(Icons.sensors, size: iconSize, color: Colors.red),
        ),
      );
    }).toList();
  }

  static _CanvasBounds _calculateCanvasBounds(List<Room> rooms) {
    if (rooms.isEmpty) return const _CanvasBounds(Offset.zero, 500, 500);

    final minX = rooms.map((r) => r.position.dx).reduce((a, b) => a < b ? a : b);
    final minY = rooms.map((r) => r.position.dy).reduce((a, b) => a < b ? a : b);
    final maxX = rooms.map((r) => r.position.dx + r.width).reduce((a, b) => a > b ? a : b);
    final maxY = rooms.map((r) => r.position.dy + r.height).reduce((a, b) => a > b ? a : b);

    final dx = 20 - minX * _scale;
    final dy = 20 - minY * _scale;
    final width = (maxX - minX) * _scale + 40;
    final height = (maxY - minY) * _scale + 40;

    return _CanvasBounds(Offset(dx, dy), width, height);
  }
}

class _CanvasBounds {
  final Offset offset;
  final double width;
  final double height;

  const _CanvasBounds(this.offset, this.width, this.height);
}

class _GridBackground extends StatelessWidget {
  const _GridBackground();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.infinite,
      painter: _GridPainter(),
    );
  }
}

class _GridPainter extends CustomPainter {
  static const double gridSize = 10.0;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.withOpacity(0.3)
      ..strokeWidth = 1.0;

    for (double x = 0; x < size.width; x += gridSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    for (double y = 0; y < size.height; y += gridSize) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
