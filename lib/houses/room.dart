import 'package:flutter/material.dart';

class Room {
  Offset position;
  double width;
  double height;
  bool isGrouped;
  Room? connectedRoom;
  String? connectedWall;
  String name;
  int? groupId;

  Room({
    required this.position,
    required this.width,
    required this.height,
    this.name = 'Room',
  }) : isGrouped = false;

  Map<String, dynamic> toJson() {
    return {
      'position': {'x': position.dx, 'y': position.dy},
      'width': width,
      'height': height,
      'isGrouped': isGrouped,
      'connectedRoom': connectedRoom?.name,
      'connectedWall': connectedWall,
      'name': name,
      'groupId': groupId,
    };
  }

  static Room fromJson(Map<String, dynamic> json) {
    return Room(
      position: Offset(json['position']['x'], json['position']['y']),
      width: json['width'],
      height: json['height'],
      name: json['name'],
    )
      ..isGrouped = json['isGrouped']
      ..groupId = json['groupId']
      ..connectedWall = json['connectedWall'];
  }
}
