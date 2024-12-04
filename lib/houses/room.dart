import 'dart:convert';
import 'dart:ui'; // Import for Offset class

class Room {
  int? id; // Add ID for database
  Offset position;
  double width;
  double height;
  bool isGrouped;
  Room? connectedRoom;
  String? connectedWall;
  String name;
  int? groupId;
  String? houseName; // Add houseName property

  Room({
    this.id,
    required this.position,
    required this.width,
    required this.height,
    this.name = 'Room',
    this.houseName, // Initialize houseName
  }) : isGrouped = false;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'position': jsonEncode({'x': position.dx, 'y': position.dy}),
      'width': width,
      'height': height,
      'isGrouped': isGrouped ? 1 : 0,
      'connectedRoom': connectedRoom?.name,
      'connectedWall': connectedWall,
      'name': name,
      'groupId': groupId,
      'houseName': houseName, // Add houseName to JSON
    };
  }

  static Room fromJson(Map<String, dynamic> json) {
    return Room(
      id: json['id'],
      position: Offset(
        jsonDecode(json['position'])['x'],
        jsonDecode(json['position'])['y'],
      ),
      width: json['width'],
      height: json['height'],
      name: json['name'],
      houseName: json['houseName'], // Parse houseName
    )
      ..isGrouped = json['isGrouped'] == 1
      ..groupId = json['groupId']
      ..connectedWall = json['connectedWall'];
  }
}
