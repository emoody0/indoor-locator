import 'package:flutter/material.dart';
import '../config.dart';
import '../database_helper.dart';
import 'package:provider/provider.dart';
import '../theme_color_notifier.dart';

class ViewLogsPage extends StatefulWidget {
  final bool isAdmin;
  final int userId; // Add user ID

  const ViewLogsPage({super.key, required this.isAdmin, required this.userId});

  @override
  _ViewLogsPageState createState() => _ViewLogsPageState();
}

class _ViewLogsPageState extends State<ViewLogsPage> {
  String? selectedUser;
  String? selectedHouse;
  String? selectedRoom;
  
  List<Map<String, dynamic>> logs = [];
  List<Map<String, dynamic>> filteredLogs = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchLogs();
  }

  Future<void> fetchLogs() async {
    print("DEBUG: Fetching logs for user ${widget.userId}, Admin: ${widget.isAdmin}");
    final db = DatabaseHelper();
    final fetchedLogs = await db.getLogs(widget.userId, widget.isAdmin);

    print("DEBUG: getLogs() result: $fetchedLogs");

    setState(() {
      logs = fetchedLogs;
      filteredLogs = logs; // Initially, show all logs
      isLoading = false;
    });
  }

  void applyFilters() {
    setState(() {
      filteredLogs = logs.where((log) {
        bool matchesUser = selectedUser == null || log['user_id'].toString() == selectedUser;
        bool matchesHouse = selectedHouse == null || log['house'] == selectedHouse;
        bool matchesRoom = selectedRoom == null || log['room_origin'] == selectedRoom;
        return matchesUser && matchesHouse && matchesRoom;
      }).toList();
    });
  }

  void addAnnotation(int logId, String existingAnnotation) async {
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
                await DatabaseHelper().addAnnotation(logId, annotationController.text, widget.userId);
                fetchLogs(); // Refresh logs after annotation update
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
        title: const Text('View Logs'),
        backgroundColor: Provider.of<ThemeColorNotifier>(context).primaryColor,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Filters
                if (widget.isAdmin) ...[
                  DropdownButtonFormField<String>(
                    value: selectedUser,
                    decoration: const InputDecoration(labelText: 'Filter by User'),
                    items: logs.map((log) => log['user_id'].toString()).toSet().map((user) {
                      return DropdownMenuItem(value: user, child: Text('User $user'));
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedUser = value;
                        applyFilters();
                      });
                    },
                  ),
                  DropdownButtonFormField<String>(
                    value: selectedHouse,
                    decoration: const InputDecoration(labelText: 'Filter by House'),
                    items: logs
                        .map<String>((log) => log['house']?.toString() ?? '') // Explicitly cast to String
                        .toSet()
                        .where((house) => house.isNotEmpty) // Remove empty values
                        .map((house) => DropdownMenuItem<String>(
                              value: house,
                              child: Text(house),
                            ))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedHouse = value;
                        applyFilters();
                      });
                    },
                  ),

                ],
                DropdownButtonFormField<String>(
                  value: selectedRoom,
                  decoration: const InputDecoration(labelText: 'Filter by Room'),
                  items: logs
                      .map<String>((log) => log['room_origin']?.toString() ?? '') // Explicitly cast to String
                      .toSet()
                      .where((room) => room.isNotEmpty) // Remove empty values
                      .map((room) => DropdownMenuItem<String>(
                            value: room,
                            child: Text(room),
                          ))
                      .toList(),
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
                      filteredLogs = logs; // Reset filters
                    });
                  },
                  child: const Text('Clear Filters'),
                ),
                const SizedBox(height: 10),
                // Log List
                Expanded(
                  child: filteredLogs.isEmpty
                      ? const Center(child: Text('No logs available.'))
                      : ListView.builder(
                          itemCount: filteredLogs.length,
                          itemBuilder: (context, index) {
                            final log = filteredLogs[index];
                            return ListTile(
                              title: Text('${log['room_origin']} - ${log['date']}'),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Start: ${log['start_window']}, End: ${log['end_window']}'),
                                  if (log['annotation'] != null && log['annotation'].trim().isNotEmpty)
                                    Text(
                                      'Annotation: ${log['annotation']}',
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                ],
                              ),
                              // Users can edit their own logs, but admins cannot add annotations
                              trailing: (!widget.isAdmin && log['user_id'] == widget.userId)
                                  ? IconButton(
                                      icon: const Icon(Icons.edit),
                                      onPressed: () => addAnnotation(log['id'], log['annotation'] ?? ""),
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
