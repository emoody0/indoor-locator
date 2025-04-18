import 'dart:convert';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:flutter/material.dart';
import '../houses/room.dart';
import '../houses/sensor.dart';

class UwbMqttService {
  final String brokerIp;
  final int port;
  final String topic;
  final void Function(Offset tagPosition) onTagPositionUpdate;
  late MqttServerClient client;

  UwbMqttService({
    required this.brokerIp,
    this.port = 1883,
    required this.topic,
    required this.onTagPositionUpdate,
  });

  Future<void> connect() async {
    final clientId = 'uwb_flutter_${DateTime.now().millisecondsSinceEpoch}';
    client = MqttServerClient.withPort(brokerIp, clientId, port);
    client.logging(on: false);
    client.keepAlivePeriod = 60;
    client.onConnected = onConnected;
    client.onDisconnected = onDisconnected;
    client.onSubscribed = (String topic) => debugPrint('Subscribed to $topic');
    client.onSubscribeFail = (String topic) => debugPrint('Failed to subscribe $topic');

    try {
      await client.connect();
    } catch (e) {
      debugPrint('MQTT connection failed: $e');
      client.disconnect();
    }
  }

  void onConnected() {
    debugPrint('Connected to MQTT Broker');
    client.subscribe(topic, MqttQos.atLeastOnce);
    client.updates!.listen((List<MqttReceivedMessage<MqttMessage>> event) {
      final recMess = event[0].payload as MqttPublishMessage;
      final payload = MqttPublishPayload.bytesToStringAsString(recMess.payload.message);
      _handleMessage(payload);
    });
  }

  void onDisconnected() {
    debugPrint('Disconnected from MQTT Broker');
  }

  void _handleMessage(String payload) {
    try {
      final data = jsonDecode(payload);
      final links = data['links'];

      if (links.length >= 3) {
        // Extract anchor data
        final anchors = links.map((e) => {
          'id': e['A'],
          'distance': double.tryParse(e['R']) ?? 0.0,
        }).toList();

        // Lookup anchor positions from hardcoded map for testing
        final Map<String, Offset> anchorPositions = {
          '1786': const Offset(100, 200),
          '1783': const Offset(300, 400),
          '1790': const Offset(200, 100),
        };

        final validAnchors = anchors.where((a) => anchorPositions.containsKey(a['id'])).toList();

        if (validAnchors.length >= 3) {
          final trilaterated = _trilaterate(validAnchors, anchorPositions);
          debugPrint('[UWB] Fake position sent!');
          onTagPositionUpdate(trilaterated);
        }
      }
    } catch (e) {
      debugPrint('Failed to parse MQTT payload: $e');
    }
    debugPrint('[UWB] Raw payload: $payload');
  }

  Offset _trilaterate(List<Map<String, dynamic>> anchors, Map<String, Offset> anchorPositions) {
    // TEMP: Fake a position for visual testing
    return const Offset(150, 150);
  }
} 
