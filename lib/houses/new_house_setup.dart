import 'package:flutter/material.dart';
import '../config.dart';
import 'database_helper.dart';

class NewHouseSetupPage extends StatefulWidget {
  const NewHouseSetupPage({super.key});

  @override
  _NewHouseSetupPageState createState() => _NewHouseSetupPageState();
}

class _NewHouseSetupPageState extends State<NewHouseSetupPage> {
  String houseName = 'New House';
  List<Map<String, dynamic>> roomData = [];

  @override
  void initState() {
    super.initState();
    _loadRooms();
  }

  Future<void> _loadRooms() async {
    final rooms = await DatabaseHelper().getRooms();
    setState(() {
      roomData = rooms;
    });
  }

  Future<void> _addRoom() async {
    final newRoom = {
      'name': 'Room',
      'width': 100.0,
      'height': 100.0,
      'posX': 50.0,
      'posY': 100.0,
    };
    final id = await DatabaseHelper().insertRoom(newRoom);
    setState(() {
      roomData.add({'id': id, ...newRoom});
    });
  }

  Future<void> _deleteRoom(int id) async {
    await DatabaseHelper().deleteRoom(id);
    setState(() {
      roomData.removeWhere((room) => room['id'] == id);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(houseName),
        backgroundColor: AppColors.colorScheme.primary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: const Text('Leave Setup'),
                  content: const Text('Any unsaved changes will be lost.'),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.pop(context);
                      },
                      child: const Text('Yes'),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
      body: Stack(
        children: [
          ...roomData.map((room) => RoomWidget(
                key: UniqueKey(),
                roomName: room['name'],
                width: room['width'],
                height: room['height'],
                position: Offset(room['posX'], room['posY']),
                onDelete: (key) => _deleteRoom(room['id']),
              )),
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: _addRoom,
                  child: const Text('Add Room'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class RoomWidget extends StatelessWidget {
  final String roomName;
  final double width;
  final double height;
  final Offset position;
  final Function(Key) onDelete;

  const RoomWidget({
    super.key,
    required this.roomName,
    required this.width,
    required this.height,
    required this.position,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: position.dx,
      top: position.dy,
      child: GestureDetector(
        onLongPress: () {
          onDelete(key!);
        },
        child: Container(
          width: width,
          height: height,
          color: Colors.blueAccent,
          child: Center(
            child: Text(
              roomName,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }
}
