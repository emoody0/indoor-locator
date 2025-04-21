// ──────────────────────────────────────────────────────────────
//  live_location_logic.dart  (uses mqtt.dart + trilateration)
// ──────────────────────────────────────────────────────────────
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../houses/room.dart';
import '../houses/sensor.dart';
import '../server/database_service.dart';
import '../server/mqtt.dart' show uwbPayload$;


class LiveLocationLogic extends ChangeNotifier {
  List<Map<String, dynamic>> houseOptions = [];
  String? selectedHouseName;
  List<Room> rooms = [];
  Offset? tagPosition;

  StreamSubscription? _mqttSub;
  Timer? _refreshTimer;

  LiveLocationLogic() {
    _initialise();
  }

  Future<void> _initialise() async {
    await _loadHouseList();
    _subscribeToUwbStream();

    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _loadRoomsForSelected();
    });
  }

  void _subscribeToUwbStream() {
    _mqttSub = uwbPayload$.stream.listen((json) {
      if (json.isEmpty) return;
      if (json == 'N/A') {
        debugPrint('[LiveLocation] No UWB data received');
        return;
      }
      final pos = _parsePosition(json);
      if (pos != null) {
        debugPrint('[LiveLocation] Position received: $pos');
        tagPosition = pos;
        notifyListeners();
      }
    });
  }

  Offset? _parsePosition(String jsonStr) {
    try {
      final decoded = jsonDecode(jsonStr);
      final links = decoded['links'] as List<dynamic>;
      if (links.length < 3) return null;

      const m2ft = 3.28084;
      final anchors = {
        '1786': const Offset(0, 0),
        '1783': const Offset(20, 0),
        '1790': const Offset(0, 20),
      };

      double sx = 0, sy = 0, sw = 0;
      for (final e in links) {
        final id = e['A'].toString().toUpperCase();
        if (!anchors.containsKey(id)) continue;
        final d = double.parse(e['R'].toString()) * m2ft;
        final w = d <= 0 ? 1 : 1 / d;
        final pos = anchors[id]!;
        sx += pos.dx * w;
        sy += pos.dy * w;
        sw += w;
      }
      if (sw == 0) return null;
      return Offset(sx / sw, sy / sw);
    } catch (_) {
      return null;
    }
  }

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

  Future<void> changeHouse(String? newName) async {
    selectedHouseName = newName;
    notifyListeners();
    await _loadRoomsForSelected();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _mqttSub?.cancel();
    super.dispose();
  }
}
