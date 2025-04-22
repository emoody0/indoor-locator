import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config.dart';
import '../database_helper.dart';
import 'package:provider/provider.dart';
import '../theme_color_notifier.dart';

class ViewAlertsPage extends StatefulWidget {
  final bool isAdmin;
  final int userId;

  const ViewAlertsPage({super.key, required this.isAdmin, required this.userId});

  @override
  _ViewAlertsPageState createState() => _ViewAlertsPageState();
}

class _ViewAlertsPageState extends State<ViewAlertsPage> {
  List<Map<String, dynamic>> alerts = [];
  bool isLoading = true;
  
  String? selectedUser;
  String? selectedHouse;
  String? selectedRoom;
  List<String> houses = [];
  List<Map<String, dynamic>> users = [];

  @override
  void initState() {
    super.initState();
    final db = DatabaseHelper();
    db.insertSampleAlerts().then((_) {
    fetchAlerts();
    });
    fetchUsersAndHouses();
  }

  Future<void> fetchAlerts() async {
    print("DEBUG: Fetching alerts for user ${widget.userId}, Admin: ${widget.isAdmin}");
    
    final db = DatabaseHelper();
    
    try {
      final fetchedAlerts = await db.getAlerts(widget.userId, widget.isAdmin);
      print("DEBUG: getAlerts() returned: $fetchedAlerts");

      setState(() {
        alerts = fetchedAlerts;
        isLoading = false; // Ensure loading state is updated
      });

    } catch (e) {
      print("ERROR: fetchAlerts() failed: $e");
      setState(() {
        isLoading = false; // Avoid infinite loading
      });
    }
  }


  Future<void> fetchUsersAndHouses() async {
    final db = DatabaseHelper();
    final userList = await db.getUsers();
    final houseList = await db.getDistinctHouseNames();

    setState(() {
      users = userList;
      houses = houseList;
    });
  }

  void applyFilters() {
    setState(() {
      alerts = alerts.where((alert) {
        bool matchesUser = selectedUser == null || alert['user_id'].toString() == selectedUser;
        bool matchesHouse = selectedHouse == null || alert['house'] == selectedHouse;
        bool matchesRoom = selectedRoom == null || alert['room_origin'] == selectedRoom;
        return matchesUser && matchesHouse && matchesRoom;
      }).toList();
    });
  }

  void addAlertAnnotation(int alertId, String existingAnnotation) async {
    TextEditingController annotationController = TextEditingController(text: existingAnnotation);

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add Annotation'),
          content: TextField(
            controller: annotationController,
            decoration: const InputDecoration(labelText: 'Your annotation'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                await DatabaseHelper().addAlertAnnotation(alertId, annotationController.text, widget.userId);
                fetchAlerts();
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('View Alerts'),
        backgroundColor: Provider.of<ThemeColorNotifier>(context).primaryColor,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                if (widget.isAdmin) ...[
                  DropdownButtonFormField<String>(
                    value: selectedHouse,
                    decoration: const InputDecoration(labelText: 'Filter by House'),
                    items: houses.map((house) => DropdownMenuItem(value: house, child: Text(house))).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedHouse = value;
                        applyFilters();
                      });
                    },
                  ),
                  DropdownButtonFormField<String>(
                    value: selectedUser,
                    decoration: const InputDecoration(labelText: 'Filter by User'),
                    items: users.map((user) => DropdownMenuItem(value: user['id'].toString(), child: Text(user['name']))).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedUser = value;
                        applyFilters();
                      });
                    },
                  ),
                ],
                DropdownButtonFormField<String>(
                  value: selectedRoom,
                  decoration: const InputDecoration(labelText: 'Filter by Room'),
                  items: alerts.map((alert) => alert['room_origin']?.toString() ?? '').toSet().where((room) => room.isNotEmpty).map((room) => DropdownMenuItem(value: room, child: Text(room))).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedRoom = value;
                      applyFilters();
                    });
                  },
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      selectedUser = null;
                      selectedHouse = null;
                      selectedRoom = null;
                      fetchAlerts();
                    });
                  },
                  child: const Text('Clear Filters'),
                ),
                Expanded(
                  child: alerts.isEmpty
                      ? const Center(child: Text('No alerts available.'))
                      : ListView.builder(
                          itemCount: alerts.length,
                          itemBuilder: (context, index) {
                            final alert = alerts[index];
                            return ListTile(
                              title: Text('${alert['timestamp']}'),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Room: ${alert['room_origin']}, House: ${alert['house']}'),
                                  if (alert['annotation'] != null && alert['annotation'].trim().isNotEmpty)
                                    Text(
                                      'Annotation: ${alert['annotation']}',
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                ],
                              ),
                              trailing: (!widget.isAdmin && alert['user_id'] == widget.userId)
                                  ? IconButton(
                                      icon: const Icon(Icons.edit),
                                      onPressed: () => addAlertAnnotation(alert['id'], alert['annotation'] ?? ""),
                                    )
                                  : null,
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}