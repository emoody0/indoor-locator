import 'package:flutter/material.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'dart:convert'; // For JSON encoding

class ManageClientServerPage extends StatefulWidget {
  const ManageClientServerPage({super.key});

  @override
  _ManageClientServerPageState createState() => _ManageClientServerPageState();
}

class _ManageClientServerPageState extends State<ManageClientServerPage> {
  MqttServerClient? client;
  String status = 'Disconnected';
  String selectedTopic = 'users'; // Default topic
  bool isConnected = false; // To track connection status (for green/red light)

  // Controllers for input fields
  final TextEditingController _topicController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _houseController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _permissionsController = TextEditingController();
  final TextEditingController _monitoringWindowController = TextEditingController();
  final TextEditingController _sensorIdController = TextEditingController();
  final TextEditingController _angleOfArrivalController = TextEditingController();
  final TextEditingController _alertMessageController = TextEditingController();
  String _selectedDataType = 'User Data'; // Data type selector

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

    client = MqttServerClient.withPort('192.168.56.105', 'flutter_client', 1883);
    client!.logging(on: true);
    client!.keepAlivePeriod = 60;
    client!.onConnected = onConnected;
    client!.onDisconnected = onDisconnected;
    client!.onUnsubscribed = onUnsubscribed;
    client!.onSubscribed = onSubscribed;
    client!.onSubscribeFail = onSubscribeFail;
    client!.pongCallback = pong;

    final connMess = MqttConnectMessage()
        .authenticateAs("username", "password")
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


  // Method to publish user data from input fields
  void publishUserData() {
      Map<String, dynamic> userData = {
      "name": _nameController.text,
      "house": _houseController.text,
      "email": _emailController.text,
      "permissions": _permissionsController.text,
      "monitoring_window": _monitoringWindowController.text
    };
    publishMessage('Users', userData);
  }

  // Method to publish sensor data from input fields
  void publishSensorData() {
    Map<String, dynamic> sensorData = {
      "sensor_id": _sensorIdController.text,
      "time": DateTime.now().toIso8601String(),
      "data": {"Example of Sensor data": 23.5}, // Example static value; can be changed if needed
      "angle_of_arrival": int.tryParse(_angleOfArrivalController.text) ?? 0
    };
    publishMessage('Sensors', sensorData);
  }

  // Method to publish an alert from input fields
  void publishAlert() {
    Map<String, dynamic> alertData = {
      "severity": "high", // This can be made dynamic too if needed
      "message": _alertMessageController.text,
      "timestamp": DateTime.now().toIso8601String()
    };
     publishMessage('Alerts', alertData);
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
          status, // Display connection status text
          style: const TextStyle(fontSize: 24),
        ),
        const SizedBox(width: 10),
        Icon(
          Icons.circle,
          color: status == 'Connected' ? Colors.green : Colors.red, // Green if connected, red if not
          size: 24,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Client/Server'),
        backgroundColor: Colors.blue,
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text(
                  'Connection Status: $status',
                  style: const TextStyle(fontSize: 20),
                ),
                const SizedBox(height: 10),
                // Green/Red light indicator for connection status
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isConnected ? Colors.green : Colors.red,
                  ),
                ),
                const SizedBox(height: 20),
                DropdownButton<String>(
                  value: _selectedDataType,
                  items: <String>['User Data', 'Sensor Data', 'Alert']
                      .map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedDataType = newValue!;
                    });
                  },
                ),
                const SizedBox(height: 20),
                // Input fields for user data
                if (_selectedDataType == 'User Data') ...[
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Name',
                      border: OutlineInputBorder(),
                    ),
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _houseController,
                    decoration: const InputDecoration(
                      labelText: 'House',
                      border: OutlineInputBorder(),
                    ),
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                    ),
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _permissionsController,
                    decoration: const InputDecoration(
                      labelText: 'Permissions',
                      border: OutlineInputBorder(),
                    ),
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _monitoringWindowController,
                    decoration: const InputDecoration(
                      labelText: 'Monitoring Window',
                      border: OutlineInputBorder(),
                    ),
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
                // Input fields for sensor data
                if (_selectedDataType == 'Sensor Data') ...[
                  TextField(
                    controller: _sensorIdController,
                    decoration: const InputDecoration(
                      labelText: 'Sensor ID',
                      border: OutlineInputBorder(),
                    ),
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _angleOfArrivalController,
                    decoration: const InputDecoration(
                      labelText: 'Angle of Arrival',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
                // Input field for alerts
                if (_selectedDataType == 'Alert') ...[
                  TextField(
                    controller: _alertMessageController,
                    decoration: const InputDecoration(
                      labelText: 'Alert Message',
                      border: OutlineInputBorder(),
                    ),
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    if (_selectedDataType == 'User Data') {
                      publishUserData();
                    } else if (_selectedDataType == 'Sensor Data') {
                      publishSensorData();
                    } else if (_selectedDataType == 'Alert') {
                      publishAlert();
                    }
                  },
                  child: const Text('Publish Data'),
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
