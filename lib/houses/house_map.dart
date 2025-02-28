import 'package:flutter/material.dart';
import '../server/database_helper.dart';
import 'room.dart';
import 'sensor.dart';
//import 'house_map_page.dart';

class HouseMapPage extends StatefulWidget {
  final String houseName;
  const HouseMapPage({super.key, required this.houseName});

  @override
  _HouseMapPageState createState() => _HouseMapPageState();
}

class _HouseMapPageState extends State<HouseMapPage> {
  late List<Room> rooms = [];
  final DatabaseHelper db = DatabaseHelper();
  double scale = 10.0; // 1ft = 10 pixels
  Offset offset = Offset.zero;

  @override
  void initState() {
    super.initState();
    _loadRooms();
  }

  Future<void> _loadRooms() async {
    List<Room> loadedRooms = await db.getRoomsByHouseName(widget.houseName);

    if (loadedRooms.isNotEmpty) {
      double minX = loadedRooms.map((room) => room.position.dx).reduce((a, b) => a < b ? a : b);
      double minY = loadedRooms.map((room) => room.position.dy).reduce((a, b) => a < b ? a : b);
      double maxX = loadedRooms.map((room) => room.position.dx + room.width).reduce((a, b) => a > b ? a : b);
      double maxY = loadedRooms.map((room) => room.position.dy + room.height).reduce((a, b) => a > b ? a : b);

      print("Loaded Rooms: ${loadedRooms.map((r) => r.name).toList()}");
      print("Room Bounds: minX=$minX, minY=$minY, maxX=$maxX, maxY=$maxY");

      setState(() {
        rooms = loadedRooms;
        offset = Offset(-minX * scale + 20, -minY * scale + 20); // Center initial view
      });
    } else {
      print("No rooms found for house: ${widget.houseName}");
      setState(() {
        rooms = loadedRooms;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('House Map: ${widget.houseName}')),
      body: GestureDetector(
        onScaleUpdate: (details) {
          setState(() {
            scale = (scale * details.scale).clamp(5.0, 50.0);
          });
        },
        child: Stack(
          children: [
            CustomPaint(
              size: Size.infinite,
              painter: GridPainter(scale, offset),
            ),
            ...rooms.map((room) => _buildRoomAndSensors(room)),
          ],
        ),
      ),
    );
  }

  Widget _buildRoomAndSensors(Room room) {
    print("Rendering Room: ${room.name}, Position: ${room.position}, Size: ${room.width}x${room.height}");
    return Stack(
      children: [
        Positioned(
          left: room.position.dx * scale + offset.dx,
          top: room.position.dy * scale + offset.dy,
          child: Container(
            width: room.width * scale,
            height: room.height * scale,
            decoration: BoxDecoration(
              color: Colors.blueAccent.withOpacity(0.5),
              border: Border.all(color: Colors.black, width: 2.0),
            ),
            child: Center(
              child: Text(
                '${room.name}\n${room.width.toStringAsFixed(1)}ft x ${room.height.toStringAsFixed(1)}ft',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          ),
        ),
        ...room.sensors.map((sensor) => _buildSensorWidget(room, sensor)),
      ],
    );
  }

  Widget _buildSensorWidget(Room room, Sensor sensor) {
    double sensorX;
    double sensorY;

    switch (sensor.wall) {
      case 'Top':
        sensorX = room.position.dx * scale + sensor.distanceFromWall * scale + offset.dx;
        sensorY = room.position.dy * scale + offset.dy;
        break;
      case 'Bottom':
        sensorX = room.position.dx * scale + sensor.distanceFromWall * scale + offset.dx;
        sensorY = (room.position.dy + room.height) * scale + offset.dy - 16;
        break;
      case 'Left':
        sensorX = room.position.dx * scale + offset.dx;
        sensorY = room.position.dy * scale + sensor.distanceFromWall * scale + offset.dy;
        break;
      case 'Right':
        sensorX = (room.position.dx + room.width) * scale + offset.dx - 16;
        sensorY = room.position.dy * scale + sensor.distanceFromWall * scale + offset.dy;
        break;
      default:
        sensorX = room.position.dx * scale + offset.dx;
        sensorY = room.position.dy * scale + offset.dy;
    }

    return Positioned(
      left: sensorX,
      top: sensorY,
      child: const Icon(Icons.sensors, size: 16, color: Colors.red),
    );
  }
}



class GridPainter extends CustomPainter {
  final double scale;
  final Offset offset;

  GridPainter(this.scale, this.offset);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.withOpacity(0.3)
      ..strokeWidth = 1.0;

    for (double x = offset.dx % scale; x < size.width; x += scale) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = offset.dy % scale; y < size.height; y += scale) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
