import 'package:flutter/material.dart';
import 'room.dart';
import 'sensor.dart';

class SensorConfigurationPage extends StatefulWidget {
  final List<Room> rooms;

  const SensorConfigurationPage({super.key, required this.rooms});

  @override
  _SensorConfigurationPageState createState() => _SensorConfigurationPageState();
}

class _SensorConfigurationPageState extends State<SensorConfigurationPage>
    with SingleTickerProviderStateMixin {
  Room? selectedRoom;
  Sensor? selectedSensor;
  final TextEditingController nameController = TextEditingController();
  final TextEditingController distanceFeetController = TextEditingController();
  final TextEditingController distanceInchesController = TextEditingController();
  String? selectedWall;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  void _resetInputs() {
    nameController.clear();
    distanceFeetController.clear();
    distanceInchesController.clear();
    selectedWall = null;
  }

  void _navigateToEditSensorPage(Sensor sensor, Room room) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditSensorPage(
          sensor: sensor,
          room: room,
          onUpdate: (updatedSensor) {
            setState(() {
              final index = room.sensors.indexOf(sensor);
              if (index != -1) {
                room.sensors[index] = updatedSensor;
              }
            });
          },
          onDelete: () {
            setState(() {
              room.sensors.remove(sensor);
            });
            Navigator.pop(context);
          },
        ),
      ),
    );
  }

  List<Widget> _buildSensorIcons(Room room) {
    return room.sensors.map((sensor) {
      double iconOffsetX;
      double iconOffsetY;

      // Adjust scaling factors for consistent placement
      final maxHorizontalDistance = room.width * 10.0;
      final maxVerticalDistance = room.height * 10.0;

      switch (sensor.wall) {
        case 'Top':
          iconOffsetX = room.position.dx + (sensor.distanceFromWall / room.width) * maxHorizontalDistance;
          iconOffsetY = room.position.dy + 2;
          break;
        case 'Bottom':
          iconOffsetX = room.position.dx + (sensor.distanceFromWall / room.width) * maxHorizontalDistance;
          iconOffsetY = room.position.dy + maxVerticalDistance - 18;
          break;
        case 'Left':
          iconOffsetX = room.position.dx + 2;
          iconOffsetY = room.position.dy + (sensor.distanceFromWall / room.height) * maxVerticalDistance;
          break;
        case 'Right':
          iconOffsetX = room.position.dx + maxHorizontalDistance - 18;
          iconOffsetY = room.position.dy + (sensor.distanceFromWall / room.height) * maxVerticalDistance;
          break;
        default:
          iconOffsetX = room.position.dx;
          iconOffsetY = room.position.dy;
      }

      // Clamp the offsets to ensure they stay within room boundaries
      return Positioned(
        left: iconOffsetX.clamp(room.position.dx, room.position.dx + maxHorizontalDistance - 16),
        top: iconOffsetY.clamp(room.position.dy, room.position.dy + maxVerticalDistance - 16),
        child: GestureDetector(
          onTap: () {
            setState(() {
              selectedSensor = sensor;
              selectedRoom = room;
              _navigateToEditSensorPage(sensor, room);
            });
          },
          child: Icon(
            Icons.sensors,
            size: 16,
            color: selectedSensor == sensor ? Colors.blue : Colors.red,
          ),
        ),
      );
    }).toList();
  }

  Widget _buildAddSensorTab() {
    return Column(
      children: [
        if (selectedRoom != null) ...[
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Sensor Name'),
            ),
          ),
          DropdownButton<String>(
            value: selectedWall,
            hint: const Text('Select Wall'),
            items: ['Top', 'Bottom', 'Left', 'Right']
                .map((wall) => DropdownMenuItem(
                      value: wall,
                      child: Text(wall),
                    ))
                .toList(),
            onChanged: (value) {
              setState(() {
                selectedWall = value;
              });
            },
          ),
          Row(
            children: [
              Flexible(
                child: TextField(
                  controller: distanceFeetController,
                  decoration: const InputDecoration(labelText: 'Distance (ft)'),
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 10),
              Flexible(
                child: TextField(
                  controller: distanceInchesController,
                  decoration: const InputDecoration(labelText: 'Distance (in)'),
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          ElevatedButton(
            onPressed: () {
              if (selectedRoom != null &&
                  selectedWall != null &&
                  nameController.text.isNotEmpty) {
                setState(() {
                  selectedRoom!.sensors.add(Sensor(
                    name: nameController.text,
                    wall: selectedWall!,
                    distanceFromWall: (int.tryParse(distanceFeetController.text) ?? 0) +
                        ((int.tryParse(distanceInchesController.text) ?? 0) / 12),
                  ));
                  _resetInputs();
                });
              }
            },
            child: const Text('Add Sensor'),
          ),
        ] else ...[
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text('Please select a room to add sensors.',
                style: TextStyle(fontSize: 16, color: Colors.grey)),
          ),
        ],
      ],
    );
  }

  Widget _buildManageSensorsTab() {
    return ListView(
      children: widget.rooms.expand((room) {
        return room.sensors.map((sensor) {
          return ListTile(
            title: Text(sensor.name),
            subtitle: Text('${sensor.wall} wall, ${sensor.distanceFromWall.toStringAsFixed(2)} ft in room: ${room.name}'),
            tileColor: selectedSensor == sensor ? Colors.blue.withOpacity(0.2) : null,
            onTap: () {
              setState(() {
                selectedSensor = sensor;
                selectedRoom = room;
                _navigateToEditSensorPage(sensor, room);
              });
            },
          );
        }).toList();
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configure Sensors'),
      ),
      body: Column(
        children: [
          Expanded(
            flex: 2,
            child: Stack(
              children: [
                ...widget.rooms.map((room) {
                  return Positioned(
                    left: room.position.dx,
                    top: room.position.dy,
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedRoom = room;
                        });
                      },
                      child: Container(
                        width: room.width * 10.0,
                        height: room.height * 10.0,
                        decoration: BoxDecoration(
                          color: selectedRoom == room
                              ? Colors.blueAccent.withOpacity(0.5)
                              : Colors.grey.withOpacity(0.5),
                          border: Border.all(color: Colors.black, width: 2),
                        ),
                        child: Center(
                          child: Text(
                            room.name,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.black),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
                ...widget.rooms.expand((room) => _buildSensorIcons(room)),
              ],
            ),
          ),
          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Add Sensor'),
              Tab(text: 'Manage Sensors'),
            ],
          ),
          Expanded(
            flex: 3,
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildAddSensorTab(),
                _buildManageSensorsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class EditSensorPage extends StatelessWidget {
  final Sensor sensor;
  final Room room;
  final Function(Sensor) onUpdate;
  final VoidCallback onDelete;

  const EditSensorPage({
    super.key,
    required this.sensor,
    required this.room,
    required this.onUpdate,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final nameController = TextEditingController(text: sensor.name);
    final distanceFeetController = TextEditingController(
        text: sensor.distanceFromWall.floor().toString());
    final distanceInchesController = TextEditingController(
        text: ((sensor.distanceFromWall - sensor.distanceFromWall.floor()) * 12)
            .round()
            .toString());
    String selectedWall = sensor.wall;

    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Sensor in ${room.name}'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Sensor Name'),
            ),
            DropdownButton<String>(
              value: selectedWall,
              hint: const Text('Select Wall'),
              items: ['Top', 'Bottom', 'Left', 'Right']
                  .map((wall) => DropdownMenuItem(
                        value: wall,
                        child: Text(wall),
                      ))
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  selectedWall = value;
                }
              },
            ),
            Row(
              children: [
                Flexible(
                  child: TextField(
                    controller: distanceFeetController,
                    decoration:
                        const InputDecoration(labelText: 'Distance (ft)'),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 10),
                Flexible(
                  child: TextField(
                    controller: distanceInchesController,
                    decoration:
                        const InputDecoration(labelText: 'Distance (in)'),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () {
                    final updatedSensor = Sensor(
                      name: nameController.text,
                      wall: selectedWall,
                      distanceFromWall: double.parse(distanceFeetController.text) +
                          (double.parse(distanceInchesController.text) / 12),
                    );
                    onUpdate(updatedSensor);
                    Navigator.pop(context);
                  },
                  child: const Text('Update Sensor'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  onPressed: onDelete,
                  child: const Text('Delete Sensor'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
