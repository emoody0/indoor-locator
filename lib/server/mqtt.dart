import 'package:flutter/material.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

class ManageClientServerPage extends StatefulWidget {
  const ManageClientServerPage({super.key});

  @override
  _ManageClientServerPageState createState() => _ManageClientServerPageState();
}

class _ManageClientServerPageState extends State<ManageClientServerPage> {
  MqttServerClient? client;
  String status = 'Disconnected'; // Track connection status
  final String topic = 'test/topic'; // MQTT topic for publishing
  final TextEditingController _messageController = TextEditingController(); // Controller for the input field

  @override
  void initState() {
    super.initState();
    connectToBroker();
  }

  Future<void> connectToBroker() async {
    setState(() {
      status = 'Connecting...'; // Indicate that connection is in progress
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
      status = 'Connected'; // Update status on successful connection
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Connected to broker')),
    );
    print('Connected');
  }

  // Disconnected callback
  void onDisconnected() {
    setState(() {
      status = 'Disconnected'; // Update status on disconnection
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

  // Method to publish a retained message to the MQTT broker
  void publishMessage(String message) {
    final builder = MqttClientPayloadBuilder();
    builder.addString(message);

    if (client?.connectionStatus?.state == MqttConnectionState.connected) {
      client!.publishMessage(topic, MqttQos.atLeastOnce, builder.payload!, retain: true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Message published')),
      );
      print('Message published: $message');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to publish, not connected')),
      );
      print('Not connected, unable to publish message');
    }
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
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              _buildConnectionIndicator(), // Show connection indicator with red/green light
              const SizedBox(height: 20),
              TextField(
                controller: _messageController,
                decoration: const InputDecoration(
                  labelText: 'Enter message',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  if (_messageController.text.isNotEmpty) {
                    publishMessage(_messageController.text); // Publish message from text box
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please enter a message')),
                    );
                  }
                },
                child: const Text('Publish Message'),
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
    );
  }
}
