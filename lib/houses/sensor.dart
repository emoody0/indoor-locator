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

  /// Converts the Sensor instance to a JSON object for database storage
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'wall': wall,
      'distanceFromWall': distanceFromWall,
      'position': {'x': position.dx, 'y': position.dy}, // Store as Map instead of JSON string
    };
  }

  /// Creates a Sensor instance from a JSON object
  static Sensor fromJson(Map<String, dynamic> json) {
    Offset parsePosition(dynamic value) {
      if (value is String) {
        try {
          final parsed = jsonDecode(value);
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

    return Sensor(
      name: json['name'] ?? 'Unnamed Sensor', // Provide default value if null
      wall: json['wall'] ?? 'Unknown', // Provide default value if null
      distanceFromWall: (json['distanceFromWall'] as num?)?.toDouble() ?? 0.0, // Default to 0.0
      position: parsePosition(json['position']),
    );
  }
}
