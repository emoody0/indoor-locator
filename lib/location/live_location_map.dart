import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../houses/room.dart';
import '../houses/sensor.dart';
import '../server/database_service.dart';

final StreamController<String> uwbPayload$ = StreamController<String>.broadcast();

class LiveLocationMapPage extends StatefulWidget {
  const LiveLocationMapPage({super.key});
  @override
  State<LiveLocationMapPage> createState() => _LiveLocationMapPageState();
}

class _LiveLocationMapPageState extends State<LiveLocationMapPage> {
  final List<Map<String, dynamic>> houseOptions = [];
  String? selectedHouseName;
  List<Room> rooms = [];
  Offset? lastKnownPosition = const Offset(197.3, 219.4); // example default
  double scale = 10.0;
  Offset offset = Offset.zero;

  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await _loadHouseList();
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _loadRooms();
    });
  }

  Future<void> _loadHouseList() async {
    final raw = await DatabaseService.fetchHouses();
    houseOptions.clear();
    houseOptions.addAll(raw.map((h) => {
          'id': h['id'],
          'name': _safeStr(h['name']),
        }));
    if (houseOptions.isNotEmpty) {
      selectedHouseName = houseOptions.first['name'] as String;
    }
    debugPrint('[LiveLocation] Houses: $houseOptions');
    await _loadRooms();
  }

  Future<void> _loadRooms() async {
    if (selectedHouseName == null) return;
    final rows = await DatabaseService.getRoomsByHouseName(selectedHouseName!);
    rooms = rows.map(_roomFromDb).toList();
    for (final room in rooms) {
      debugPrint('[LiveLocation] Room "${room.name}" at ${room.position} → ${room.width}x${room.height}');
    }
    double minX = rooms.map((room) => room.position.dx).reduce((a, b) => a < b ? a : b);
    double minY = rooms.map((room) => room.position.dy).reduce((a, b) => a < b ? a : b);
    double maxX = rooms.map((room) => room.position.dx + room.width).reduce((a, b) => a > b ? a : b);
    double maxY = rooms.map((room) => room.position.dy + room.height).reduce((a, b) => a > b ? a : b);
    debugPrint('[LiveLocation] Room Bounds: minX=$minX, minY=$minY, maxX=$maxX, maxY=$maxY');
    debugPrint('[LiveLocation] Map size: ${maxX - minX} x ${maxY - minY}');
    setState(() {
      offset = Offset(-minX * scale + 20, -minY * scale + 20); // Center initial view
      debugPrint('[LiveLocation] Map offset: $offset');
      });
  }

  Room _roomFromDb(Map<String, dynamic> r) {
    List<Sensor> sensors = [];
    final sJson = r['sensors'];
    if (sJson != null && sJson.toString().isNotEmpty) {
      try {
        final list = jsonDecode(_safeStr(sJson)) as List<dynamic>;
        sensors = list.map((e) => Sensor.fromJson(e)).toList();
      } catch (_) {}
    }

    return Room(
      id: r['id'] as int?,
      name: _safeStr(r['name']),
      width: (r['width'] as num).toDouble(),
      height: (r['height'] as num).toDouble(),
      position: Offset(
        (r['position_x'] as num).toDouble(),
        (r['position_y'] as num).toDouble(),
      ),
      sensors: sensors,
      houseName: _safeStr(r['house_name']),
    );
  }

  String _safeStr(dynamic v) {
    if (v == null) return '';
    if (v is Uint8List) return utf8.decode(v);
    return v.toString();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(title: const Text('Live Location Map')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: DropdownButton<String>(
              value: selectedHouseName,
              hint: const Text('Select House'),
              items: houseOptions
                  .map((h) => DropdownMenuItem<String>(
                        value: h['name'],
                        child: Text(h['name']),
                      ))
                  .toList(),
              onChanged: (v) async {
                selectedHouseName = v;
                await _loadRooms();
              },
            ),
          ),
          Expanded(
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 3,
              child: Stack(
                children: [
                  CustomPaint(
                    size: Size.infinite,
                    painter: GridPainter(scale, offset),
                  ),
                  for (final room in rooms)
                    Positioned(
                      left: room.position.dx,
                      top: room.position.dy,
                      child: Container(
                        width: room.width * scale,
                        height: room.height * scale,
                        decoration: BoxDecoration(
                          color: Colors.blueAccent,
                          border: Border.all(color: Colors.black, width: 2),
                        ),
                        child: Center(
                          child: Text(
                            '${room.name}\n${room.width.toStringAsFixed(1)} ft x ${room.height.toStringAsFixed(1)} ft',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                  if (lastKnownPosition != null)
                    Positioned(
                      left: lastKnownPosition!.dx,
                      top: lastKnownPosition!.dy,
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
}

class GridPainter extends CustomPainter {
  final double scale;
  final Offset offset;
  GridPainter(this.scale, this.offset);
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.withOpacity((0.3))
      ..strokeWidth = 1;
    for (double x = 0; x < size.width; x += scale) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += scale) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
