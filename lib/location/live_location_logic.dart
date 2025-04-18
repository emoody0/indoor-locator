import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../houses/room.dart';
import '../houses/sensor.dart';
import '../server/database_service.dart';
import '../server/uwb_mqtt_service.dart';

/// Live 2‑D location page that shows the stored floor‑plan plus the tag
/// position streamed over MQTT.
class LiveLocationMapPage extends StatefulWidget {
  const LiveLocationMapPage({super.key});

  @override
  State<LiveLocationMapPage> createState() => _LiveLocationMapPageState();
}

class _LiveLocationMapPageState extends State<LiveLocationMapPage> {
  // -------------------- runtime data --------------------
  List<Room> rooms = [];
  Offset? tagPosition;

  // grid helpers
  double scale = 10.0; // 1 ft → 10 px
  Offset mapOffset = const Offset(20, 20); // left / top padding

  // infrastructure
  late final UwbMqttService uwbMqttService;
  List<Map<String, dynamic>> houseOptions = [];
  String? selectedHouseName;

  // -------------------- lifecycle ----------------------
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _loadHouseList();
      _initMqtt();
    });
  }

  // -------------------- DB helpers ---------------------
  Future<void> _loadHouseList() async {
    try {
      final raw = await DatabaseService.fetchHouses();
      final decoded = raw.map((h) => {'id': h['id'], 'name': _safeStr(h['name'])}).toList();
      debugPrint('[LiveLocation] Houses → $decoded');

      setState(() {
        houseOptions = decoded;
        if (decoded.isNotEmpty) selectedHouseName = decoded.first['name'];
      });
      await _loadRoomsForSelected();
    } catch (e) {
      debugPrint('[LiveLocation] House load error: $e');
    }
  }

  Future<void> _loadRoomsForSelected() async {
    if (selectedHouseName == null) return;
    debugPrint('[LiveLocation] Fetching rooms for "$selectedHouseName"');

    try {
      final rows = await DatabaseService.getRoomsByHouseName(selectedHouseName!);
      debugPrint('[LiveLocation] Room rows → $rows');

      final parsed = rows.map(_roomFromDb).toList();
      _recenter(parsed);
      setState(() => rooms = parsed);
    } catch (e) {
      debugPrint('[LiveLocation] Room fetch error: $e');
      setState(() => rooms = []);
    }
  }

  // convert DB row → Room (handles NULL/Blob)
  Room _roomFromDb(Map<String, dynamic> r) {
    // sensors
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

  // shift so smallest x/y sits at 20 px margin
  void _recenter(List<Room> rs) {
    if (rs.isEmpty) return;
    final minX = rs.map((r) => r.position.dx).reduce((a, b) => a < b ? a : b);
    final minY = rs.map((r) => r.position.dy).reduce((a, b) => a < b ? a : b);
    setState(() => mapOffset = Offset(20 - minX * scale, 20 - minY * scale));
    debugPrint('[LiveLocation] mapOffset → $mapOffset');
  }

  // -------------------- MQTT ---------------------------
  void _initMqtt() {
    uwbMqttService = UwbMqttService(
      brokerIp: '192.168.119.63',
      topic: 'homeassistant/esp32/location',
      onTagPositionUpdate: (p) => setState(() => tagPosition = p),
    );
    uwbMqttService.connect();
  }

  // -------------------- UI -----------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Live Location Map')),
      body: Column(
        children: [
          _houseDropdown(),
          Expanded(
            child: InteractiveViewer(
              maxScale: 3,
              minScale: 0.5,
              child: _mapCanvas(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _houseDropdown() => Padding(
        padding: const EdgeInsets.all(8.0),
        child: DropdownButton<String>(
          value: selectedHouseName,
          hint: const Text('Select House'),
          items: houseOptions
              .map((h) => DropdownMenuItem<String>(
                    value: h['name'] as String,
                    child: Text(h['name'] as String),
                  ))
              .toList(),
          onChanged: (val) async {
            setState(() => selectedHouseName = val);
            await _loadRoomsForSelected();
          },
        ),
      );

  Widget _mapCanvas() => Stack(
        children: [
          CustomPaint(size: Size.infinite, painter: const GridPainter()),
          ...rooms.expand(_roomWidgets),
          if (tagPosition != null)
            Positioned(
              left: tagPosition!.dx * scale + mapOffset.dx,
              top: tagPosition!.dy * scale + mapOffset.dy,
              child: const Icon(Icons.person_pin_circle, size: 30, color: Colors.green),
            ),
        ],
      );

  Iterable<Widget> _roomWidgets(Room room) {
    final roomRect = Positioned(
      left: room.position.dx * scale + mapOffset.dx,
      top: room.position.dy * scale + mapOffset.dy,
      child: Container(
        width: room.width * scale,
        height: room.height * scale,
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
      final pos = _sensorPixelPos(room, s);
      return Positioned(
        left: pos.dx,
        top: pos.dy,
        child: const Icon(Icons.sensors, size: 16, color: Colors.red),
      );
    });

    return [roomRect, ...sensorIcons];
  }

  Offset _sensorPixelPos(Room room, Sensor s) {
    double dx, dy;
    switch (s.wall) {
      case 'Top':
        dx = room.position.dx * scale + s.distanceFromWall * scale + mapOffset.dx;
        dy = room.position.dy * scale + mapOffset.dy;
        break;
      case 'Bottom':
        dx = room.position.dx * scale + s.distanceFromWall * scale + mapOffset.dx;
        dy = (room.position.dy + room.height) * scale - 16 + mapOffset.dy;
        break;
      case 'Left':
        dx = room.position.dx * scale + mapOffset.dx;
        dy = room.position.dy * scale + s.distanceFromWall * scale + mapOffset.dy;
        break;
      case 'Right':
        dx = (room.position.dx + room.width) * scale - 16 + mapOffset.dx;
        dy = room.position.dy * scale + s.distanceFromWall * scale + mapOffset.dy;
        break;
      default:
        dx = room.position.dx * scale + mapOffset.dx;
        dy = room.position.dy * scale + mapOffset.dy;
    }
    return Offset(dx, dy);
  }

  // -------------------- utils ---------------------------
  String _safeStr(dynamic v) {
    if (v == null) return '';
    if (v is Uint8List) return utf8.decode(v);
    return v.toString();
  }
}

/// simple light‑grey grid painter
/// simple light‑grey grid painter
class GridPainter extends CustomPainter {
  const GridPainter();
  static const double grid = 10.0;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.withOpacity(0.35)
      ..strokeWidth = 1.0;

    // vertical grid lines
    for (double x = 0; x <= size.width; x += grid) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    // horizontal grid lines
    for (double y = 0; y <= size.height; y += grid) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}