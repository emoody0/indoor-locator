import 'package:flutter/material.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'dart:convert'; // For JSON encoding

class MQTTPage extends StatefulWidget {
  const MQTTPage({super.key});

  @override
  _MQTTPageState createState() => _MQTTPageState();
}

class _MQTTPageState extends State<MQTTPage> {
  MqttServerClient? client;
  String status = 'Disconnected';
  bool isConnected = false; // To track connection status (for green/red light)

  // Controllers for sensor data input fields
  final TextEditingController _sensorIdController = TextEditingController();
  final TextEditingController _angleOfArrivalController = TextEditingController();

  @override
  void initState() {
    super.initState();
    connectToBroker();
  }

  Future<void> connectToBroker() async {
    setState(() {
      status = 'Connecting...';
      isConnected = false;
    });

    // Generate a unique client ID
    String clientId = 'flutter_client_${DateTime.now().millisecondsSinceEpoch}';
    client = MqttServerClient.withPort('192.168.96.63', clientId, 1883);
    client!.logging(on: true);
    client!.keepAlivePeriod = 60;
    client!.onConnected = onConnected;
    client!.onDisconnected = onDisconnected;
    client!.onUnsubscribed = onUnsubscribed;
    client!.onSubscribed = onSubscribed;
    client!.onSubscribeFail = onSubscribeFail;
    client!.pongCallback = pong;

    final connMess = MqttConnectMessage()
        .authenticateAs("flutter_client", "flutter_client!")
        .withWillTopic('willtopic')
        .withWillMessage('My Will message')
        .startClean()
        .withWillQos(MqttQos.atLeastOnce);
    client!.connectionMessage = connMess;

    try {
      await client!.connect();
    } catch (e) {
      print('Exception: $e');
      client!.disconnect();
      return;
    }
  }

  // Connected callback
  void onConnected() {
    setState(() {
      status = 'Connected';
      isConnected = true; // Show green light when connected
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Connected to broker')),
    );
    print('Connected');
  }

  // Disconnected callback
  void onDisconnected() {
    setState(() {
      status = 'Disconnected';
      isConnected = false; // Show red light when disconnected
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Disconnected from broker')),
    );
    print('Disconnected');
  }

  // Subscribed callback
  void onSubscribed(String topic) {
    print('Subscribed topic: $topic');
  }

  // Subscription failure callback
  void onSubscribeFail(String topic) {
    print('Failed to subscribe $topic');
  }

  // Unsubscribed callback
  void onUnsubscribed(String? topic) {
    print('Unsubscribed topic: $topic');
  }

  // Pong callback
  void pong() {
    print('Ping response client callback invoked');
  }

  // Method to publish a message to the MQTT broker as a JSON object
  void publishMessage(String topic, Map<String, dynamic> messageData) {
    final builder = MqttClientPayloadBuilder();
    builder.addString(jsonEncode(messageData)); // Encode message as JSON

    if (client?.connectionStatus?.state == MqttConnectionState.connected) {
      client!.publishMessage(topic, MqttQos.atLeastOnce, builder.payload!, retain: true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Message published')),
      );
      print('Message published to $topic: ${jsonEncode(messageData)}');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to publish, not connected')),
      );
      print('Not connected, unable to publish message');
    }
  }

  // Method to publish sensor data from input fields
  void publishSensorData() {
    Map<String, dynamic> sensorData = {
      "sensor_id": _sensorIdController.text,
      "time": DateTime.now().toIso8601String(),
      "data": {"Example of Sensor data": 23.5}, // Example static value; adjust as needed
      "angle_of_arrival": int.tryParse(_angleOfArrivalController.text) ?? 0
    };
    publishMessage('Sensors', sensorData);
  }

  // Build connection status indicator (red for disconnected, green for connected)
  Widget _buildConnectionIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'Status: ',
          style: TextStyle(fontSize: 24),
        ),
        Text(
          status,
          style: const TextStyle(fontSize: 24),
        ),
        const SizedBox(width: 10),
        Icon(
          Icons.circle,
          color: isConnected ? Colors.green : Colors.red,
          size: 24,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MQTT Sensor Data Manager'),
        backgroundColor: Colors.blue,
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                _buildConnectionIndicator(),
                const SizedBox(height: 20),
                // Input field for sensor ID
                TextField(
                  controller: _sensorIdController,
                  decoration: const InputDecoration(
                    labelText: 'Sensor ID',
                    border: OutlineInputBorder(),
                  ),
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 8),
                // Input field for angle of arrival
                TextField(
                  controller: _angleOfArrivalController,
                  decoration: const InputDecoration(
                    labelText: 'Angle of Arrival',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: publishSensorData,
                  child: const Text('Publish Sensor Data'),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () async {
                    if (status == 'Disconnected') {
                      connectToBroker(); // Attempt to reconnect if disconnected
                    }
                  },
                  child: const Text('Reconnect'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
