/*

Workmanager().registerPeriodicTask(
  "tagLocationCheck",
  "checkTagLocation",
  frequency: const Duration(minutes: 1), // Minimum interval (15 minutes on Android by default)
  inputData: {
    "key": "value", // Pass any data if needed
  },
);



import 'package:sqflite/sqflite.dart';
import 'database_helper.dart';
import 'sensor.dart';

Future<void> calculateTagLocation() async {
  final db = await DatabaseHelper.instance.database;

  // Fetch all sensors for a specific room
  final List<Map<String, dynamic>> sensorsData = await db.query(
    'sensors',
    where: 'roomName = ?',
    whereArgs: ['RoomNameHere'],
  );

  List<Sensor> sensors = sensorsData.map((e) => Sensor.fromJson(e)).toList();

  // Perform trilateration or other localization techniques to compute tag location
  final tagLocation = computeTagLocation(sensors);

  // Save or log the location
  print("Tag Location: $tagLocation");
}

Offset computeTagLocation(List<Sensor> sensors) {
  // Example Trilateration Logic
  // Use sensor positions and readings to determine the tag location
  // Replace with your algorithm
  if (sensors.length < 3) {
    throw Exception("At least 3 sensors are required for trilateration");
  }

  // Example: Assume sensor readings are distances to the tag
  final sensorA = sensors[0];
  final sensorB = sensors[1];
  final sensorC = sensors[2];

  // Trilateration formula (simplified example)
  final x = (sensorA.position.dx + sensorB.position.dx + sensorC.position.dx) / 3;
  final y = (sensorA.position.dy + sensorB.position.dy + sensorC.position.dy) / 3;

  return Offset(x, y);
}
*/