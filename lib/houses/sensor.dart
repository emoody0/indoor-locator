import 'dart:convert';
import 'dart:ui'; // Import for Offset class

class Sensor {
  final String name;
  final String wall;
  final double distanceFromWall;
  final Offset position;

  Sensor({
    required this.name,
    required this.wall,
    required this.distanceFromWall,
    required this.position,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'wall': wall,
      'distanceFromWall': distanceFromWall,
      'position': jsonEncode({'x': position.dx, 'y': position.dy}),
    };
  }

  static Sensor fromJson(Map<String, dynamic> json) {
    final positionData = json['position'] != null ? jsonDecode(json['position']) : {'x': 0.0, 'y': 0.0};
    return Sensor(
      name: json['name'] ?? 'Unnamed Sensor', // Provide a default value if name is null
      wall: json['wall'] ?? 'Unknown', // Provide a default value if wall is null
      distanceFromWall: (json['distanceFromWall'] as num?)?.toDouble() ?? 0.0, // Default to 0.0 if null
      position: Offset(
        (positionData['x'] as num?)?.toDouble() ?? 0.0, // Default to 0.0 if null
        (positionData['y'] as num?)?.toDouble() ?? 0.0, // Default to 0.0 if null
      ),
    );
  }
}
