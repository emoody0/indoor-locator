import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import '../houses/room.dart';
import '../houses/sensor.dart';
import '../server/database_service.dart';

// ──────────────────────────────────────────────────────────────
//  GLOBAL MQTT STREAM
// ──────────────────────────────────────────────────────────────
final StreamController<String> uwbPayload$ = StreamController<String>.broadcast();

// ──────────────────────────────────────────────────────────────
//  LIVE LOCATION PAGE WITH LOGIC + UI
// ──────────────────────────────────────────────────────────────
class LiveLocationMapPage extends StatefulWidget {
  const LiveLocationMapPage({super.key});

  @override
  State<LiveLocationMapPage> createState() => _LiveLocationMapPageState();
}

class _LiveLocationMapPageState extends State<LiveLocationMapPage> {
  final List<Map<String, dynamic>> houseOptions = [];
  String? selectedHouseName;
  List<Room> rooms = [];
  Offset? tagPosition;
  Offset? lastKnownPosition;
  static const double _scale = 2.0;


  StreamSubscription? _mqttSub;
  Timer? _refreshTimer;
  MqttServerClient? client;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await _connectToMQTT();
    await _loadHouseList();
    _subscribeToUwb();
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _loadRooms();
    });
  }

  Future<void> _connectToMQTT() async {
  client = MqttServerClient.withPort("192.168.119.63", "flutter_client", 1883);
  client!
    ..logging(on: true)
    ..keepAlivePeriod = 60
    ..onConnected = _onConnected
    ..onDisconnected = _onDisconnected
    ..onSubscribed = _onSubscribed;

  final connMess = MqttConnectMessage()
      .authenticateAs("flutter_client", "flutter_client!")
      .withWillTopic("homeassistant/esp32/location")
      .withWillMessage("UWB client disconnected")
      .startClean()
      .withWillQos(MqttQos.atLeastOnce);

  client!.connectionMessage = connMess;

  try {
    await client!.connect();
    client!.subscribe("homeassistant/esp32/location", MqttQos.atLeastOnce);
    client!.updates!.listen((List<MqttReceivedMessage<MqttMessage>> events) {
      final rec = events.first.payload as MqttPublishMessage;
      final json = MqttPublishPayload.bytesToStringAsString(rec.payload.message);
      debugPrint('[MQTT] payload: $json');
      uwbPayload$.add(json);
    });
  } catch (e) {
    debugPrint('[MQTT] connect error: $e');
    client!.disconnect();
  }
}

void _onConnected() => debugPrint('[MQTT] connected');
void _onDisconnected() => debugPrint('[MQTT] disconnected');
void _onSubscribed(String topic) => debugPrint('[MQTT] subscribed: $topic');

  void _subscribeToUwb() {
    _mqttSub = uwbPayload$.stream.listen((json) {
      final pos = _parsePosition(json);
      if (pos != null) {
        tagPosition = pos;
        lastKnownPosition = pos;
        debugPrint('[LiveLocation] Tag position: $pos');
      } else {
        debugPrint('[LiveLocation] Could not parse position');
      }
      setState(() {});
    });
  }

  Offset? _parsePosition(String jsonStr) {
    try {
      final decoded = jsonDecode(jsonStr);
      final links = decoded['links'] as List<dynamic>;
      if (links.length < 2) return null;

      const anchorMap = {
        '1786': Offset(107.6, 308.7), // Update to your actual anchor positions
        '1783': Offset(127.6, 308.7),
        '1789': Offset(107.6, 328.7),
      };

      final validLinks = links.where((e) {
        final id = e['A'].toString().toUpperCase();
        final r = double.tryParse(e['R'].toString());
        return anchorMap.containsKey(id) && r != null;
      }).toList();

      if (validLinks.length < 2) return null;

      if (validLinks.length == 2) {
        final id1 = validLinks[0]['A'].toString().toUpperCase();
        final id2 = validLinks[1]['A'].toString().toUpperCase();
        final a1 = anchorMap[id1]!;
        final a2 = anchorMap[id2]!;
        final d1 = double.parse(validLinks[0]['R'].toString()).abs();
        final d2 = double.parse(validLinks[1]['R'].toString()).abs();

        return _trilaterateTwo(a1, d1, a2, d2);
      }

      double sx = 0, sy = 0, sw = 0;
      for (final e in validLinks) {
        final id = e['A'].toString().toUpperCase();
        final d = double.tryParse(e['R'].toString())?.abs();
        if (d == null || d == 0) continue;

        final anchor = anchorMap[id]!;
        final w = 1 / d;
        sx += anchor.dx * w;
        sy += anchor.dy * w;
        sw += w;
      }
      if (sw == 0) return null;

      return Offset(sx / sw, sy / sw);
    } catch (_) {
      return null;
    }
  }

  Offset _trilaterateTwo(Offset a, double da, Offset b, double db) {
    final dx = b.dx - a.dx;
    final dy = b.dy - a.dy;
    final dist = sqrt(dx * dx + dy * dy);
    final cosA = (db * db + dist * dist - da * da) / (2 * db * dist);

    if (cosA.abs() > 1.0) return a;

    final px = db * cosA;
    final py = db * sqrt(1 - cosA * cosA);
    final angle = atan2(dy, dx);
    final rx = px * cos(angle) - py * sin(angle);
    final ry = px * sin(angle) + py * cos(angle);

    return Offset(a.dx + rx, a.dy + ry);
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
    setState(() {});
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
    _mqttSub?.cancel();
    client?.disconnect();
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
                    painter: GridPainter(),
                  ),
                  for (final room in rooms)
                    Positioned(
                      left: room.position.dx *  _scale,
                      top: room.position.dy *  _scale,
                      child: Container(
                        width: room.width *  _scale,
                        height: room.height *  _scale,
                        decoration: BoxDecoration(
                          color: Colors.blueAccent.withOpacity(0.4),
                          border: Border.all(color: Colors.black, width: 2),
                        ),
                        child: Center(
                          child: Text(
                            '${room.name}\n${room.width}x${room.height}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                  if (lastKnownPosition != null)
                    Positioned(
                      left: lastKnownPosition!.dx *  _scale,
                      top: lastKnownPosition!.dy *  _scale,
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

// ──────────────────────────────────────────────────────────────
//  Grid background
// ──────────────────────────────────────────────────────────────
class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.withOpacity(0.3)
      ..strokeWidth = 1;
    for (double x = 0; x < size.width; x += 10) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += 10) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
