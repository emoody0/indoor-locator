import 'dart:convert';
import 'package:flutter/material.dart';
import 'database.dart';
import 'rest_API.dart';

class SendDataView extends StatefulWidget {
  const SendDataView({Key? key}) : super(key: key);

  @override
  _SendDataViewState createState() => _SendDataViewState();
}

class _SendDataViewState extends State<SendDataView> {
  final TextEditingController _entityIdController = TextEditingController();
  final TextEditingController _distanceController = TextEditingController();
  final TextEditingController _attributesController = TextEditingController();
  final TextEditingController _tableNameController = TextEditingController();

  String _statusMessage = "";
  bool _isLoading = false;

  String _validateJson(String input) {
    try {
      jsonDecode(input);
      return input;
    } catch (_) {
      return "{}";
    }
  }

  Future<void> _sendData() async {
    final entityId = _entityIdController.text.trim();
    final distance = _distanceController.text.trim();
    final attributes = _validateJson(_attributesController.text.trim());

    if (entityId.isEmpty || distance.isEmpty) {
      setState(() {
        _statusMessage = "Entity ID and Distance are required!";
      });
      return;
    }

    try {
      setState(() => _isLoading = true);

      final db = HomeAssistantDatabase();

      // Insert data using raw SQL
      final sql = '''
        INSERT INTO sensor_distance (entity_id, distance, attributes, last_updated)
        VALUES (?, ?, ?, ?);
      ''';
      await db.execute(sql, [
        entityId,
        distance,
        attributes,
        DateTime.now().toIso8601String(),
      ]);

      // Sync with Home Assistant
      final api = HomeAssistantApi('http://localhost:8123', 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJiNGQ3NWViZjA2ODI0NTRkODI5NDk5MDcyZDMxZGU1ZSIsImlhdCI6MTczNzU3MTkxNSwiZXhwIjoyMDUyOTMxOTE1fQ.e2w0UeDV9WLT3-Zz2WWQGjoEPtyNOMQm2m_I-7MrxEs');
      await api.createOrUpdateState(entityId, {
        "state": distance,
        "attributes": jsonDecode(attributes),
      });

      setState(() {
        _statusMessage = "Data sent successfully and synced with Home Assistant!";
      });

      // Clear input fields
      _entityIdController.clear();
      _distanceController.clear();
      _attributesController.clear();
    } catch (e) {
      setState(() {
        _statusMessage = "Error sending data: $e";
      });
      print("Error details: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteTable() async {
    final tableName = _tableNameController.text.trim();

    if (tableName.isEmpty) {
      setState(() {
        _statusMessage = "Table name is required to delete!";
      });
      return;
    }

    try {
      setState(() => _isLoading = true);

      final db = HomeAssistantDatabase();
      await db.execute('DROP TABLE IF EXISTS $tableName;');

      setState(() {
        _statusMessage = "Table '$tableName' deleted successfully!";
      });

      // Clear table name input
      _tableNameController.clear();
    } catch (e) {
      setState(() {
        _statusMessage = "Error deleting table: $e";
      });
      print("Error deleting table: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Manage SQLite Database"),
        backgroundColor: Colors.blue,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _entityIdController,
                    decoration: const InputDecoration(
                      labelText: "Entity ID (e.g., sensor.distance)",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _distanceController,
                    decoration: const InputDecoration(
                      labelText: "Distance",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _attributesController,
                    decoration: const InputDecoration(
                      labelText: "Attributes (JSON)",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _sendData,
                    child: const Text("Send Data"),
                  ),
                  const Divider(height: 40),
                  TextField(
                    controller: _tableNameController,
                    decoration: const InputDecoration(
                      labelText: "Table Name to Delete",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: _deleteTable,
                    child: const Text("Delete Table"),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    _statusMessage,
                    style: const TextStyle(color: Colors.green),
                  ),
                ],
              ),
            ),
    );
  }
}
