import 'package:flutter/material.dart';
import 'room.dart';
import 'sensor.dart';
import 'new_house_setup.dart';

class SensorConfigurationPage extends StatefulWidget {
  final List<Room> rooms;

  const SensorConfigurationPage({super.key, required this.rooms});

  @override
  _SensorConfigurationPageState createState() => _SensorConfigurationPageState();
}

class _SensorConfigurationPageState extends State<SensorConfigurationPage> {
  Room? selectedRoom;
  final TextEditingController nameController = TextEditingController();
  String? selectedWall;
  int distanceFeet = 0;
  int distanceInches = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configure Sensors'),
      ),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: widget.rooms.map((room) {
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
                      width: room.width * 10.0, // Scale to fit the screen
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
              }).toList(),
            ),
          ),
          if (selectedRoom != null) ...[
            const Divider(),
            const Text('Add Sensor', style: TextStyle(fontSize: 20)),
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
                    decoration: const InputDecoration(labelText: 'Distance (ft)'),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      setState(() {
                        distanceFeet = int.tryParse(value) ?? 0;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Flexible(
                  child: TextField(
                    decoration: const InputDecoration(labelText: 'Distance (in)'),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      setState(() {
                        distanceInches = int.tryParse(value) ?? 0;
                      });
                    },
                  ),
                ),
              ],
            ),
            ElevatedButton(
              onPressed: () {
                if (selectedRoom != null &&
                    selectedWall != null &&
                    nameController.text.isNotEmpty) {
                  if (selectedRoom!.sensors.length < 4) {
                    setState(() {
                      selectedRoom!.sensors.add(Sensor(
                        name: nameController.text,
                        wall: selectedWall!,
                        distanceFromWall: distanceFeet + (distanceInches / 12),
                      ));
                      nameController.clear();
                      selectedWall = null;
                      distanceFeet = 0;
                      distanceInches = 0;
                    });
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Each room can have up to 4 sensors.')),
                    );
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Fill in all fields.')),
                  );
                }
              },
              child: const Text('Add Sensor'),
            ),
          ],
        ],
      ),
    );
  }
}
