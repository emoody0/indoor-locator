import 'dart:convert';
import 'dart:ui'; // Import for Offset class
import 'sensor.dart';

class Room {
  int? id;
  Offset position;
  double width;
  double height;
  bool isGrouped;
  Room? connectedRoom;
  String? connectedWall;
  String name;
  int? groupId;
  String? houseName;
  List<Sensor> sensors;

  Room({
    this.id,
    required this.position,
    required this.width,
    required this.height,
    this.isGrouped = false,
    this.connectedRoom,
    this.connectedWall,
    this.name = 'Room',
    this.groupId,
    this.houseName,
    this.sensors = const [],
  });

  /// Creates a copy of the room with updated properties
  Room copyWith({
    int? id,
    Offset? position,
    double? width,
    double? height,
    bool? isGrouped,
    Room? connectedRoom,
    String? connectedWall,
    String? name,
    int? groupId,
    String? houseName,
    List<Sensor>? sensors,
  }) {
    return Room(
      id: id ?? this.id,
      position: position ?? this.position,
      width: width ?? this.width,
      height: height ?? this.height,
      isGrouped: isGrouped ?? this.isGrouped,
      connectedRoom: connectedRoom ?? this.connectedRoom,
      connectedWall: connectedWall ?? this.connectedWall,
      name: name ?? this.name,
      groupId: groupId ?? this.groupId,
      houseName: houseName ?? this.houseName,
      sensors: sensors ?? this.sensors,
    );
  }

  /// Converts the Room instance to a JSON object for database storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'position': jsonEncode({'x': position.dx, 'y': position.dy}),
      'width': width,
      'height': height,
      'isGrouped': isGrouped ? 1 : 0,
      'connectedRoom': connectedRoom?.id,
      'connectedWall': connectedWall,
      'name': name,
      'groupId': groupId,
      'houseName': houseName,
      'sensors': jsonEncode(sensors.map((sensor) => sensor.toJson()).toList()), // Serialize sensors
    };
  }

  /// Creates a Room instance from a JSON object
  static Room fromJson(Map<String, dynamic> json) {
    Offset parsePosition(String value) {
      final Map<String, dynamic> parsed = jsonDecode(value);
      return Offset(
        (parsed['x'] as num?)?.toDouble() ?? 0.0, // Default to 0.0 if null
        (parsed['y'] as num?)?.toDouble() ?? 0.0, // Default to 0.0 if null
      );
    }

    List<Sensor> parseSensors(String? value) {
      if (value == null || value.isEmpty) return [];
      final List<dynamic> parsed = jsonDecode(value);
      return parsed.map((e) => Sensor.fromJson(e as Map<String, dynamic>)).toList();
    }

    return Room(
      id: json['id'] as int?,
      position: parsePosition(json['position'] as String),
      width: (json['width'] as num).toDouble(),
      height: (json['height'] as num).toDouble(),
      isGrouped: json['isGrouped'] == 1,
      connectedRoom: null, // This needs to be resolved separately
      connectedWall: json['connectedWall'] as String?,
      name: json['name'] as String,
      groupId: json['groupId'] as int?,
      houseName: json['houseName'] as String?,
      sensors: json['sensors'] != null
          ? parseSensors(json['sensors'] as String)
          : [],
    );
  }

}
