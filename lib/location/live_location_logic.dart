// ──────────────────────────────────────────────────────────────
//  live_location_logic.dart  (state‑management / data layer)
//  reverted to call static DatabaseService helpers directly
// ──────────────────────────────────────────────────────────────
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../houses/room.dart';
import '../houses/sensor.dart';
import '../server/database_service.dart';
import '../server/uwb_mqtt_service.dart';

/// Central ChangeNotifier that keeps MQTT tag‑position, house/room list
/// and refreshes rooms every 30 seconds.
class LiveLocationLogic extends ChangeNotifier {
  // ───────── public reactive state ──────────
  List<Map<String, dynamic>> houseOptions = [];
  String? selectedHouseName;
  List<Room> rooms = [];
  Offset? tagPosition;

  // ───────── private ──────────
  late final UwbMqttService _mqtt;
  Timer? _refreshTimer;

  LiveLocationLogic() {
    _initialise();
  }

  // initialise: load houses, setup mqtt, periodic refresh
  Future<void> _initialise() async {
    await _loadHouseList();
    _initMqtt();

    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _loadRoomsForSelected();
    });
  }

  // ───────── DB helpers ──────────
  Future<void> _loadHouseList() async {
    try {
      final raw = await DatabaseService.fetchHouses();
      houseOptions = raw
          .map((h) => {
                'id': h['id'],
                'name': _safeStr(h['name']),
              })
          .toList();

      if (houseOptions.isNotEmpty) {
        selectedHouseName = houseOptions.first['name'] as String;
      }
      notifyListeners();
      await _loadRoomsForSelected();
    } catch (e) {
      debugPrint('[LiveLocation] House load error: $e');
    }
  }

  Future<void> _loadRoomsForSelected() async {
    if (selectedHouseName == null) return;
    try {
      final rows = await DatabaseService.getRoomsByHouseName(selectedHouseName!);
      rooms = rows.map(_roomFromDb).toList();
      notifyListeners();
    } catch (e) {
      debugPrint('[LiveLocation] Room load error: $e');
    }
  }

  // ───────── MQTT ──────────
  void _initMqtt() {
    _mqtt = UwbMqttService(
      brokerIp: '192.168.119.63',
      topic: 'homeassistant/esp32/location',
      onTagPositionUpdate: (p) {
        tagPosition = p;
        notifyListeners();
      },
    );
    _mqtt.connect();
  }

  // ───────── utilities ──────────
  Room _roomFromDb(Map<String, dynamic> r) {
    // Sensors JSON can be NULL / BLOB so guard aggressively
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

  // Public API -------------------------------------------------------------
  Future<void> changeHouse(String? newName) async {
    selectedHouseName = newName;
    notifyListeners();
    await _loadRoomsForSelected();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }
}
