import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

final StreamController<String> uwbPayload$ = StreamController<String>.broadcast();

class MQTTPage extends StatefulWidget {
  const MQTTPage({super.key});

  @override
  State<MQTTPage> createState() => _MQTTPageState();
}

class _MQTTPageState extends State<MQTTPage> {

  MqttServerClient? client;
  String status = 'Disconnected';
  bool isConnected = false;
  String _lastJson = 'N/A';

  @override
  void initState() {
    super.initState();
    _connect();
  }

  Future<void> _connect() async {
    const brokerIp = '192.168.119.63';
    const port = 1883;
    const username = 'flutter_client';
    const password = 'flutter_client!';
    const topic = 'homeassistant/esp32/location';
    const clientId = 'flutter_client';

    client = MqttServerClient.withPort(brokerIp, clientId, port);
    client!.logging(on: true);
    client!.keepAlivePeriod = 60;
    client!.onConnected = _onConnected;
    client!.onDisconnected = _onDisconnected;
    client!.onSubscribed = _onSubscribed;
    client!.onSubscribeFail = _onSubscribeFail;
    client!.pongCallback = _onPong;

    client!.connectionMessage = MqttConnectMessage()
        .authenticateAs(username, password)
        .withWillTopic('willtopic')
        .withWillMessage('MQTT client disconnected')
        .startClean()
        .withWillQos(MqttQos.atLeastOnce);

    try {
      await client!.connect();
    } catch (e) {
      debugPrint('[MQTT] connect exception: $e');
      client!.disconnect();
      setState(() => status = 'Error');
    }
  }

  void _onConnected() {
    setState(() {
      status = 'Connected';
      isConnected = true;
    });
    const topic = 'homeassistant/esp32/location';
    client!.subscribe(topic, MqttQos.atLeastOnce);

    client!.updates!.listen((events) {
      final rec = events.first.payload as MqttPublishMessage;
      final json = MqttPublishPayload.bytesToStringAsString(rec.payload.message);
      debugPrint('[MQTT] payload: $json');

      uwbPayload$.add(json);
      setState(() => _lastJson = json);
    });
  }

  void _onDisconnected() {
    setState(() {
      status = 'Disconnected';
      isConnected = false;
    });
  }

  void _onSubscribed(String topic) {
    debugPrint('[MQTT] subscribed: $topic');
  }

  void _onSubscribeFail(String topic) {
    debugPrint('[MQTT] subscribe failed: $topic');
  }

  void _onPong() {
    debugPrint('[MQTT] ping response');
  }

  @override
  void dispose() {
    client?.disconnect();
    uwbPayload$.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('MQTT Debug')),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Status: $status', style: const TextStyle(fontSize: 18)),
              const SizedBox(height: 12),
              const Text('Last payload:'),
              Text(_lastJson, style: const TextStyle(fontFamily: 'monospace')),
            ],
          ),
        ),
      );
}