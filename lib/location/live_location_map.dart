import 'dart:async';
import 'dart:math';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../houses/room.dart';
import '../houses/sensor.dart';
import '../server/database_service.dart';
import '../server/mqtt.dart';

class LiveLocationMapPage extends StatefulWidget {
  const LiveLocationMapPage({super.key});
  @override
  State<LiveLocationMapPage> createState() => _LiveLocationMapPageState();
}

class _LiveLocationMapPageState extends State<LiveLocationMapPage> {
  final List<Map<String, dynamic>> houseOptions = [];
  String? selectedHouseName;
  List<Room> rooms = [];
  Offset tag = Offset.zero; // Placeholder for the tag position
  double scale = 10.0;
  Offset offset = Offset.zero;
  StreamSubscription? _tagStream;
  Timer? _refreshTimer;
  Offset? _lastValidTagPosition;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await startMqttConnection();
    await _loadHouseList();
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _loadRooms();
    });
     _tagStream = uwbPayload$.stream.listen(_handleTagPayload);
  }

  void _handleTagPayload(String payload) {
  try {
    final Map<String, dynamic> data = jsonDecode(payload);
    final links = List<dynamic>.from(data['links'] ?? []);

    final Map<String, Offset> anchors = {
      '1786': Offset(107.6, 308.7),
      '1789': Offset(107.6, 328.7),
      '1783': Offset(127.6, 308.7),
    };

    final validLinks = links.where((e) {
      final anchorId = e['A'].toString();
      final distance = double.tryParse(e['R'].toString());
      return anchors.containsKey(anchorId) && distance != null && distance > 0;
    }).toList();

    if (validLinks.isEmpty) return;

    // Always use weighted average of all valid anchors
    double totalWeight = 0;
    Offset weightedSum = Offset.zero;
    
    for (final link in validLinks) {
      final anchor = anchors[link['A']]!;
      final distance = double.parse(link['R'].toString());
      final weight = 1 / (distance + 0.1);  // Add small epsilon to avoid div/0
      
      weightedSum += Offset(
        anchor.dx * weight,
        anchor.dy * weight,
      );
      totalWeight += weight;
    }

    final calculated = Offset(
      weightedSum.dx / totalWeight,
      weightedSum.dy / totalWeight,
    );

    debugPrint('Calculated position: $calculated');

    setState(() {
      tag = _clampTagToBounds(calculated);
      _lastValidTagPosition = tag;
    });
  } catch (e) {
    debugPrint('Error processing payload: $e');
  }
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
    //debugPrint('[LiveLocation] Houses: $houseOptions');
    await _loadRooms();
  }

  Offset _clampTagToBounds(Offset input) {
  if (rooms.isEmpty) return input;
  final minX = rooms.map((r) => r.position.dx).reduce(min);
  final minY = rooms.map((r) => r.position.dy).reduce(min);
  final maxX = rooms.map((r) => r.position.dx + r.width).reduce(max);
  final maxY = rooms.map((r) => r.position.dy + r.height).reduce(max);

  return Offset(
    input.dx.clamp(minX, maxX),
    input.dy.clamp(minY, maxY),
  );
}

  Future<void> _loadRooms() async {
    if (selectedHouseName == null) return;
    final rows = await DatabaseService.getRoomsByHouseName(selectedHouseName!);
    rooms = rows.map(_roomFromDb).toList();
    double minX = rooms.map((room) => room.position.dx).reduce((a, b) => a < b ? a : b);
    double minY = rooms.map((room) => room.position.dy).reduce((a, b) => a < b ? a : b);
    //debugPrint('[LiveLocation] Room Bounds: minX=$minX, minY=$minY, maxX=$maxX, maxY=$maxY');
    //debugPrint('[LiveLocation] Map size: ${maxX - minX} x ${maxY - minY}');
      
    setState(() {
      offset = Offset(-minX * scale + 20, -minY * scale + 20); // Center initial view
      // Confine the tag position within the room bounds
      //debugPrint('[LiveLocation] Map offset: $offset');
      //debugPrint('[LiveLocation] Confined tag: $tag');
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
    _tagStream?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tagScreenPosition = Offset(
      tag.dx * scale + offset.dx,
      tag.dy * scale + offset.dy,
    );
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
               setState(() => selectedHouseName = v);
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
                      left: room.position.dx * scale + offset.dx,
                      top: room.position.dy *  scale + offset.dy,
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
                    Positioned(
                      left: tagScreenPosition.dx,
                      top: tagScreenPosition.dy,
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
