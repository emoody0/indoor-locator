// ──────────────────────────────────────────────────────────────
//  live_location_page.dart  (presentation layer)
// ──────────────────────────────────────────────────────────────
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../houses/room.dart';
import '../houses/sensor.dart';
import 'live_location_logic.dart';

/// Entry widget – provide logic and build the map UI
class LiveLocationMapPage extends StatelessWidget {
  const LiveLocationMapPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => LiveLocationLogic(),
      child: const _LiveLocationView(),
    );
  }
}

// ──────────────────────────────────────────────────────────────
//  Internal view widget
// ──────────────────────────────────────────────────────────────
class _LiveLocationView extends StatelessWidget {
  const _LiveLocationView();

  static const double _scale = 10.0; // 1 ft == 10 px

  @override
  Widget build(BuildContext context) {
    final logic = context.watch<LiveLocationLogic>();
    final mapOffset = _calcOffset(logic.rooms, _scale);

    return Scaffold(
      appBar: AppBar(title: const Text('Live Location Map')),
      body: Column(
        children: [
          _houseDropdown(logic),
          Text(
              logic.tagPosition == null
                  ? 'Waiting for UWB data…'
                  : 'Last fix: ${DateTime.now().toLocal().toIso8601String().substring(11,19)}',
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
          Expanded(
            child: InteractiveViewer(
              maxScale: 3,
              minScale: 0.5,
              child: Stack(
                children: [
                  const _Grid(),
                  ...logic.rooms.expand((r) => _roomWidgets(r, mapOffset)),
                  if (logic.tagPosition != null)
                    Positioned(
                      left: logic.tagPosition!.dx * _scale + mapOffset.dx,
                      top: logic.tagPosition!.dy * _scale + mapOffset.dy,
                      child: const Icon(Icons.person_pin_circle,
                          size: 30, color: Colors.green),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────── helper UI builders ─────────────────
  Widget _houseDropdown(LiveLocationLogic logic) => Padding(
        padding: const EdgeInsets.all(8.0),
        child: DropdownButton<String>(
          value: logic.selectedHouseName,
          hint: const Text('Select House'),
          items: logic.houseOptions
              .map((h) => DropdownMenuItem<String>(
                    value: h['name'] as String?,
                    child: Text(h['name'] as String),
                  ))
              .toList(),
          onChanged: logic.changeHouse,
        ),
      );

  static Offset _calcOffset(List<Room> rooms, double scale) {
    if (rooms.isEmpty) return const Offset(20, 20);
    final minX = rooms.map((r) => r.position.dx).reduce((a, b) => a < b ? a : b);
    final minY = rooms.map((r) => r.position.dy).reduce((a, b) => a < b ? a : b);
    return Offset(20 - minX * scale, 20 - minY * scale);
  }

  Iterable<Widget> _roomWidgets(Room room, Offset mapOffset) {
    final roomRect = Positioned(
      left: room.position.dx * _scale + mapOffset.dx,
      top: room.position.dy * _scale + mapOffset.dy,
      child: Container(
        width: room.width * _scale,
        height: room.height * _scale,
        decoration: BoxDecoration(
          color: Colors.blueAccent.withOpacity(0.4),
          border: Border.all(color: Colors.black, width: 2),
        ),
        child: Center(
          child: Text(room.name, style: const TextStyle(color: Colors.white)),
        ),
      ),
    );

    final sensorIcons = room.sensors.map((s) {
      final pos = _sensorPixelPos(room, s, mapOffset);
      return Positioned(
        left: pos.dx,
        top: pos.dy,
        child: const Icon(Icons.sensors, size: 16, color: Colors.red),
      );
    });

    return [roomRect, ...sensorIcons];
  }

  Offset _sensorPixelPos(Room room, Sensor s, Offset mapOffset) {
    double dx, dy;
    switch (s.wall) {
      case 'Top':
        dx = room.position.dx * _scale + s.distanceFromWall * _scale + mapOffset.dx;
        dy = room.position.dy * _scale + mapOffset.dy;
        break;
      case 'Bottom':
        dx = room.position.dx * _scale + s.distanceFromWall * _scale + mapOffset.dx;
        dy = (room.position.dy + room.height) * _scale - 16 + mapOffset.dy;
        break;
      case 'Left':
        dx = room.position.dx * _scale + mapOffset.dx;
        dy = room.position.dy * _scale + s.distanceFromWall * _scale + mapOffset.dy;
        break;
      case 'Right':
        dx = (room.position.dx + room.width) * _scale - 16 + mapOffset.dx;
        dy = room.position.dy * _scale + s.distanceFromWall * _scale + mapOffset.dy;
        break;
      default:
        dx = room.position.dx * _scale + mapOffset.dx;
        dy = room.position.dy * _scale + mapOffset.dy;
    }
    return Offset(dx, dy);
  }
}

// ──────────────────────────────────────────────────────────────
//  Grid painter utility (light grey)  --------------------------
// ──────────────────────────────────────────────────────────────
class _Grid extends StatelessWidget {
  const _Grid();
  @override
  Widget build(BuildContext context) => CustomPaint(size: Size.infinite, painter: const _GridPainter());
}

class _GridPainter extends CustomPainter {
  const _GridPainter();
  static const double grid = 10.0;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.withOpacity(0.35)
      ..strokeWidth = 1.0;
    for (double x = 0; x <= size.width; x += grid) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y <= size.height; y += grid) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
