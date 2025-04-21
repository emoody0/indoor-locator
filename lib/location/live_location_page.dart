import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'live_location_logic.dart';
import '../houses/house_map.dart';

class LiveLocationMapPage extends StatelessWidget {
  const LiveLocationMapPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => LiveLocationLogic(),
      child: const _LiveLocationView(),
    );
  }
}

class _LiveLocationView extends StatelessWidget {
  const _LiveLocationView();

  @override
  Widget build(BuildContext context) {
    final logic = context.watch<LiveLocationLogic>();
    for (final room in logic.rooms) {
      debugPrint('[LiveLocation] Room "${room.name}" at ${room.position.dx},${room.position.dy} → size ${room.width}x${room.height}');
    }
    debugPrint('[LiveLocation] Total rooms: ${logic.rooms.length}');
    debugPrint('[LiveLocation] Tag at: ${logic.tagPosition}');
        
    return Scaffold(
      appBar: AppBar(title: const Text('Live Location Map')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: DropdownButton<String>(
              value: logic.selectedHouseName,
              hint: const Text('Select House'),
              items: logic.houseOptions
                  .map((h) => DropdownMenuItem<String>(
                        value: h['name'],
                        child: Text(h['name']),
                      ))
                  .toList(),
              onChanged: logic.changeHouse,
            ),
          ),
          Text(
            logic.tagPosition == null
                ? 'Waiting for UWB data…'
                : 'Last fix: ${DateTime.now().toLocal().toIso8601String().substring(11, 19)}',
            style: const TextStyle(fontSize: 12, color: Colors.black54),
          ),
          Expanded(
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 3.0,
              child: HouseMap(
                rooms: logic.rooms,
                tagPosition: logic.tagPosition,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
