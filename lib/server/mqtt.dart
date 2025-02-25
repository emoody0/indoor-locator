import 'package:flutter/material.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

class MQTTPage extends StatefulWidget {
  const MQTTPage({super.key});

  @override
  _MQTTPageState createState() => _MQTTPageState();
}

class _MQTTPageState extends State<MQTTPage> {
  MqttServerClient? client;
  String status = 'Disconnected';
  bool isConnected = false; // To track connection status
  String _distanceValue = "N/A"; // Holds the received distance data

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
    }
  }

  // Called when the client connects successfully.
  void onConnected() {
    setState(() {
      status = 'Connected';
      isConnected = true;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Connected to broker')),
    );
    print('Connected');

    // Subscribe to the distance data topic
    client!.subscribe("homeassistant/esp32/distance", MqttQos.atLeastOnce);

    // Listen for incoming messages.
    client!.updates!.listen((List<MqttReceivedMessage<MqttMessage>> event) {
      final recMess = event[0].payload as MqttPublishMessage;
      final pt =
          MqttPublishPayload.bytesToStringAsString(recMess.payload.message);
      print('Received message: $pt from topic: ${event[0].topic}');
      setState(() {
        _distanceValue = pt;
      });
    });
  }

  // Called when the client disconnects.
  void onDisconnected() {
    setState(() {
      status = 'Disconnected';
      isConnected = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Disconnected from broker')),
    );
    print('Disconnected');
  }

  // Called when a topic is successfully subscribed.
  void onSubscribed(String topic) {
    print('Subscribed to topic: $topic');
  }

  // Called if subscription fails.
  void onSubscribeFail(String topic) {
    print('Failed to subscribe to topic: $topic');
  }

  // Called when unsubscribing from a topic.
  void onUnsubscribed(String? topic) {
    print('Unsubscribed from topic: $topic');
  }

  // Pong callback
  void pong() {
    print('Ping response client callback invoked');
  }

  @override
  void dispose() {
    client?.disconnect();
    super.dispose();
  }

  // Build connection status indicator (green if connected, red otherwise)
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
        title: const Text('Distance Data Viewer'),
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
                const Text(
                  'Distance Data:',
                  style: TextStyle(fontSize: 20),
                ),
                const SizedBox(height: 10),
                Text(
                  _distanceValue,
                  style: const TextStyle(
                      fontSize: 32, fontWeight: FontWeight.bold),
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
