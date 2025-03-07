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
    List<Sensor>? sensors, // Allow null as input
  }) : sensors = sensors ?? []; // Initialize with an empty modifiable list if null

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
      sensors: sensors != null ? List<Sensor>.from(sensors) : List<Sensor>.from(this.sensors),
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
      'connectedRoom': connectedRoom != null ? jsonEncode(connectedRoom!.toJson()) : null,
      'connectedWall': connectedWall,
      'name': name,
      'groupId': groupId,
      'houseName': houseName,
      'sensors': jsonEncode(sensors.map((sensor) => sensor.toJson()).toList()),
    };
  }


  /// Creates a Room instance from a JSON object
  static Room fromJson(Map<String, dynamic> json) {
    Offset parsePosition(dynamic value) {
      if (value is String) {
        try {
          final Map<String, dynamic> parsed = jsonDecode(value);
          return Offset(
            (parsed['x'] as num?)?.toDouble() ?? 0.0,
            (parsed['y'] as num?)?.toDouble() ?? 0.0,
          );
        } catch (e) {
          print("Error parsing position: $e");
          return const Offset(0.0, 0.0);
        }
      } else if (value is Map<String, dynamic>) {
        return Offset(
          (value['x'] as num?)?.toDouble() ?? 0.0,
          (value['y'] as num?)?.toDouble() ?? 0.0,
        );
      }
      return const Offset(0.0, 0.0);
    }



    List<Sensor> parseSensors(String? value) {
      if (value == null || value.isEmpty || value == '[]') return [];
      try {
        final List<dynamic> parsed = jsonDecode(value);
        return parsed.map((e) => Sensor.fromJson(e as Map<String, dynamic>)).toList();
      } catch (e) {
        print("Error parsing sensors: $e");
        return [];
      }
    }


    return Room(
      id: json['id'] as int?,
      position: parsePosition(json['position'] as String),
      width: (json['width'] as num).toDouble(),
      height: (json['height'] as num).toDouble(),
      isGrouped: json['isGrouped'] == 1,
      connectedRoom: json['connectedRoom'] != null
        ? (json['connectedRoom'] is String
            ? Room.fromJson(jsonDecode(json['connectedRoom']))
            : Room.fromJson(json['connectedRoom'] as Map<String, dynamic>))
        : null,

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
