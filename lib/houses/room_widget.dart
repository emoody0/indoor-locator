import 'package:flutter/material.dart';
import 'room.dart';

class RoomWidget extends StatefulWidget {
  final Room room;
  final List<Room> rooms;
  final Function(Room, String, String) onConnect;
  final VoidCallback onUngroup;
  final Function(Offset) onMove;
  final VoidCallback onDelete; // New delete callback

  const RoomWidget({
    Key? key,
    required this.room,
    required this.rooms,
    required this.onConnect,
    required this.onUngroup,
    required this.onMove,
    required this.onDelete, // Pass delete callback
  }) : super(key: key);

  @override
  _RoomWidgetState createState() => _RoomWidgetState();
}

class _RoomWidgetState extends State<RoomWidget> {
  Offset? dragStartOffset;
  final double scaleFactor = 10.0;

  @override
  Widget build(BuildContext context) {
    // Assign a border color based on the room's group ID
    Color borderColor = widget.room.groupId != null
        ? Colors.primaries[(widget.room.groupId! % Colors.primaries.length)]
        : Colors.black;

    return GestureDetector(
      onPanStart: (details) {
        dragStartOffset = details.globalPosition - widget.room.position;
      },
      onPanUpdate: (details) {
        setState(() {
          widget.room.position = details.globalPosition - dragStartOffset!;
          widget.onMove(details.delta);
        });
      },
      onLongPress: _showContextMenu,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: borderColor, width: 2.0), // Add a border
        ),
        child: Container(
          width: widget.room.width * scaleFactor,
          height: widget.room.height * scaleFactor,
          color: Colors.blueAccent,
          child: Center(
            child: Text(
              '${widget.room.name}\n${widget.room.width.toStringAsFixed(1)} ft x ${widget.room.height.toStringAsFixed(1)} ft',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }

  void _showContextMenu() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.link),
              title: const Text('Connect to Room'),
              onTap: () async {
                Room? targetRoom = await _selectTargetRoom(context);
                if (targetRoom != null) {
                  _showWallSelectionOptions(targetRoom);
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.aspect_ratio),
              title: const Text('Resize Room'),
              onTap: () {
                Navigator.pop(context);
                _showResizeDialog();
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit Room Name'),
              onTap: () {
                Navigator.pop(context);
                _showEditNameDialog();
              },
            ),
            ListTile(
              leading: const Icon(Icons.remove_circle_outline),
              title: const Text('Ungroup'),
              onTap: () {
                widget.onUngroup();
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete),
              title: const Text('Delete Room'),
              onTap: () {
                Navigator.pop(context);
                widget.onDelete(); // Trigger deletion
              },
            ),
          ],
        );
      },
    );
  }

  // Existing _showEditNameDialog, _showResizeDialog, _showWallSelectionOptions, _showAlignmentOptions, and _selectTargetRoom methods remain unchanged.

  void _showEditNameDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final TextEditingController nameController = TextEditingController(text: widget.room.name);
        return AlertDialog(
          title: const Text('Edit Room Name'),
          content: TextField(
            controller: nameController,
            decoration: const InputDecoration(labelText: 'Room Name'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  widget.room.name = nameController.text;
                });
                Navigator.pop(context);
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _showResizeDialog() {
    final TextEditingController widthController = TextEditingController(text: widget.room.width.toString());
    final TextEditingController heightController = TextEditingController(text: widget.room.height.toString());

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Resize Room'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: widthController,
                decoration: const InputDecoration(labelText: 'Width (ft)'),
                keyboardType: TextInputType.numberWithOptions(decimal: true), // Allows decimal input
              ),
              TextField(
                controller: heightController,
                decoration: const InputDecoration(labelText: 'Height (ft)'),
                keyboardType: TextInputType.numberWithOptions(decimal: true), // Allows decimal input
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  // Parse as double to retain decimal places
                  widget.room.width = double.tryParse(widthController.text) ?? widget.room.width;
                  widget.room.height = double.tryParse(heightController.text) ?? widget.room.height;
                });
                Navigator.pop(context);
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _showWallSelectionOptions(Room targetRoom) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Attach to Left Wall'),
              onTap: () {
                Navigator.pop(context);
                _showAlignmentOptions(targetRoom, 'left');
              },
            ),
            ListTile(
              title: const Text('Attach to Right Wall'),
              onTap: () {
                Navigator.pop(context);
                _showAlignmentOptions(targetRoom, 'right');
              },
            ),
            ListTile(
              title: const Text('Attach to Top Wall'),
              onTap: () {
                Navigator.pop(context);
                _showAlignmentOptions(targetRoom, 'top');
              },
            ),
            ListTile(
              title: const Text('Attach to Bottom Wall'),
              onTap: () {
                Navigator.pop(context);
                _showAlignmentOptions(targetRoom, 'bottom');
              },
            ),
          ],
        );
      },
    );
  }

  void _showAlignmentOptions(Room targetRoom, String wall) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (wall == 'left' || wall == 'right') ...[
              ListTile(
                title: Text('Align Top of $wall Wall'),
                onTap: () {
                  widget.onConnect(targetRoom, wall, 'start'); // Align top
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: Text('Align Bottom of $wall Wall'),
                onTap: () {
                  widget.onConnect(targetRoom, wall, 'end'); // Align bottom
                  Navigator.pop(context);
                },
              ),
            ] else if (wall == 'top' || wall == 'bottom') ...[
              ListTile(
                title: Text('Align Left of $wall Wall'),
                onTap: () {
                  widget.onConnect(targetRoom, wall, 'start'); // Align left
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: Text('Align Right of $wall Wall'),
                onTap: () {
                  widget.onConnect(targetRoom, wall, 'end'); // Align right
                  Navigator.pop(context);
                },
              ),
            ],
          ],
        );
      },
    );
  }

  Future<Room?> _selectTargetRoom(BuildContext context) async {
    return await showDialog<Room>(
      context: context,
      builder: (BuildContext context) {
        return SimpleDialog(
          title: const Text('Select Room to Connect'),
          children: widget.rooms
              .where((room) => room != widget.room) // Exclude the current room
              .map((room) => SimpleDialogOption(
                    onPressed: () => Navigator.pop(context, room),
                    child: Text(room.name), // Display room name for identification
                  ))
              .toList(),
        );
      },
    );
  }
}
