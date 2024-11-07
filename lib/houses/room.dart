import 'package:flutter/material.dart';

class Room {
  Offset position;
  double width;
  double height;
  bool isGrouped;
  Room? connectedRoom;
  String? connectedWall; // 'left', 'right', 'top', 'bottom'
  String name; // Room name property
  int? groupId; // `null` indicates the room is not grouped

  Room({
    required this.position,
    required this.width,
    required this.height,
    this.name = 'Room',
  }) : isGrouped = false;
}
