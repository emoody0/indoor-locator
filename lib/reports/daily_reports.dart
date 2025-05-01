import 'package:flutter/material.dart';
import '../server/database_helper.dart';
import 'package:provider/provider.dart';
import '../theme_color_notifier.dart'; //

class DailyReportsPage extends StatefulWidget {
  final bool isAdmin;

  const DailyReportsPage({super.key, required this.isAdmin});

  @override
  _DailyReportsPageState createState() => _DailyReportsPageState();
}

class _DailyReportsPageState extends State<DailyReportsPage> {
  String? selectedUser;
  String? selectedDate;
  Map<String, dynamic> reportData = {};
  List<Map<String, dynamic>> users = [];
  List<String> reportDates = [];

  @override
  void initState() {
    super.initState();
    fetchUsers();
    fetchReportDates();
    fetchReportData();
  }

  Future<void> fetchReportData() async {
    final dbHelper = DatabaseHelper();
    final db = await dbHelper.database;
    final int userId = widget.isAdmin ? await getSelectedUserId() : await getCurrentUserId();

    final List<Map<String, dynamic>> results = await db.query(
      'daily_reports',
      where: 'user_id = ? AND date = ?',
      whereArgs: [userId, selectedDate ?? DateTime.now().toIso8601String().split('T')[0]],
      orderBy: 'id DESC',
      limit: 1,
    );

    setState(() {
      reportData = results.isNotEmpty ? results.first : {
        'mostActiveTime': 'No data available',
        'leastActiveTime': 'No data available',
        'mostTimeSpent': 'No data available',
        'areasExplored': 'No data available',
        'activityComparison': 'No data available',
        'alertsToday': 'No data available',
      };
    });
  }

  Future<int> getCurrentUserId() async {
    final dbHelper = DatabaseHelper();
    final db = await dbHelper.database;
    final userList = await db.query('users');
    return userList.isNotEmpty ? userList.first['id'] as int : -1;
  }

  Future<int> getSelectedUserId() async {
    if (selectedUser == null) return await getCurrentUserId();
    final user = users.firstWhere((user) => user['name'] == selectedUser, orElse: () => {'id': -1});
    return user['id'] as int? ?? -1;
  }

  Future<void> fetchUsers() async {
    if (!widget.isAdmin) return;
    final dbHelper = DatabaseHelper();
    final db = await dbHelper.database;
    final userList = await db.query('users');
    setState(() {
      users = userList;
      selectedUser = users.isNotEmpty ? users.first['name'] as String : null;
    });
  }

  Future<void> fetchReportDates() async {
    final dbHelper = DatabaseHelper();
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> results = await db.rawQuery(
      'SELECT DISTINCT date FROM daily_reports ORDER BY date DESC'
    );
    setState(() {
      reportDates = results.map((row) => row['date'] as String).toList();
      selectedDate = reportDates.isNotEmpty ? reportDates.first : null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isAdmin ? 'Admin Daily Reports' : 'Resident Daily Reports'),
        backgroundColor: Provider.of<ThemeColorNotifier>(context).primaryColor,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.isAdmin) ...[
              DropdownButtonFormField<String>(
                value: selectedUser,
                hint: const Text('Select a user'),
                items: users.map((user) {
                  return DropdownMenuItem<String>(
                    value: user['name'] as String,
                    child: Text(user['name'] as String),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedUser = value;
                  });
                  fetchReportData();
                },
              ),
              const SizedBox(height: 16),
            ],
            DropdownButtonFormField<String>(
              value: selectedDate,
              hint: const Text('Select a date'),
              items: reportDates.map((date) {
                return DropdownMenuItem<String>(
                  value: date,
                  child: Text(date),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedDate = value;
                });
                fetchReportData();
              },
            ),
            const SizedBox(height: 16),
            Text('Most active time period: ${reportData['mostActiveTime']}'),
            const SizedBox(height: 8),
            Text('Least active time period: ${reportData['leastActiveTime']}'),
            const SizedBox(height: 8),
            Text('Most time spent: ${reportData['mostTimeSpent']}'),
            const SizedBox(height: 8),
            Text('Areas explored today: ${reportData['areasExplored']}'),
            const SizedBox(height: 8),
            Text('${reportData['activityComparison']}'),
            const SizedBox(height: 8),
            Text('You received ${reportData['alertsToday']} total alerts today.'),
          ],
        ),
      ),
    );
  }
}