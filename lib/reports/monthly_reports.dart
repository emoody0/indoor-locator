import 'package:flutter/material.dart';
import '../config.dart';
import '../server/database_helper.dart';

class MonthlyReportsPage extends StatefulWidget {
  final bool isAdmin;

  const MonthlyReportsPage({super.key, required this.isAdmin});

  @override
  _MonthlyReportsPageState createState() => _MonthlyReportsPageState();
}

class _MonthlyReportsPageState extends State<MonthlyReportsPage> {
  String? selectedMonth; // For dropdown to select a month
  String? selectedUser; // Admin-only feature to select a user

  // Placeholder for dynamic data fetched from a database
  Map<String, dynamic> reportData = {
    'mostActiveDay': null,
    'leastActiveDay': null,
    'mostTimeSpent': null,
    'daysWithFewAlerts': null,
    'monthlyComparison': null,
    'rewardsEarned': null,
    'totalAlerts': {
      'thisMonth': null,
      'lastMonth': null,
    },
  };

  // Example data
  final List<String> months = ['This Month', 'Last Month', 'March 2025'];
  List<Map<String, dynamic>> users = []; // Admin-only

  void fetchReportData() {
    // Simulate fetching data from the database
    setState(() {
      reportData = {
        'mostActiveDay': 'Monday (0 alerts)',
        'leastActiveDay': 'Wednesday (4 alerts)',
        'mostTimeSpent': 'Living Room, Desk',
        'daysWithFewAlerts': ['3/11', '3/14', '3/16', '3/22', '3/31'],
        'monthlyComparison':
            'You were more active in March than you were in February. Good job!',
        'rewardsEarned': 2,
        'totalAlerts': {
          'thisMonth': 25,
          'lastMonth': 30,
        },
      };
    });
  }

  @override
  void initState() {
    super.initState();
    fetchReportData(); // Fetch initial report data (e.g., "Today" for the logged-in user)
    fetchUsers();
  }

  

  void fetchUsers() async {
    final db = DatabaseHelper();
    final userList = await db.getUsers();
    setState(() {
      users = userList;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isAdmin ? 'Admin Monthly Reports' : 'Resident Monthly Reports'),
        backgroundColor: AppColors.primaryColor,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Dropdown to select a month
            DropdownButtonFormField<String>(
              value: selectedMonth,
              hint: const Text('Select a month'),
              items: months.map((month) {
                return DropdownMenuItem<String>(
                  value: month,
                  child: Text(month),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedMonth = value;
                  fetchReportData(); // Simulate fetching data for the selected month
                });
              },
            ),
            const SizedBox(height: 16),

            // Admin-only dropdown to select a user
            if (widget.isAdmin) ...[
              DropdownButtonFormField<String>(
                value: selectedUser,
                hint: const Text('Select a user'),
                items: users.map((user) {
                  return DropdownMenuItem<String>(
                    value: user['name'],
                    child: Text(user['name']),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedUser = value;
                    fetchReportData(); // Update data for the selected user
                  });
                },
              ),
              const SizedBox(height: 16),
            ],

            // Display report data
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Monthly Report for ${selectedUser ?? 'you'} (${selectedMonth ?? 'This Month'}):',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    Text(
                      'Most active day: ${reportData['mostActiveDay'] ?? 'Loading...'}',
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 8),

                    Text(
                      'Least active day: ${reportData['leastActiveDay'] ?? 'Loading...'}',
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 8),

                    Text(
                      'Most time spent: ${reportData['mostTimeSpent'] ?? 'Loading...'}',
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 8),

                    Text(
                      'Days with one alert or less: ${(reportData['daysWithFewAlerts'] as List<String>?)?.join(', ') ?? 'Loading...'}',
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 8),

                    Text(
                      '${reportData['monthlyComparison'] ?? 'Loading...'}',
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 8),

                    Text(
                      'Rewards earned this month: ${reportData['rewardsEarned'] ?? 'Loading...'}',
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 16),

                    Text(
                      'Total alerts this month: ${reportData['totalAlerts']['thisMonth'] ?? 'Loading...'}',
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 8),

                    Text(
                      'Total alerts last month: ${reportData['totalAlerts']['lastMonth'] ?? 'Loading...'}',
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 32),

                    // Placeholder for graphs
                    Center(
                      child: Column(
                        children: [
                          Container(
                            height: 200,
                            width: double.infinity,
                            color: Colors.grey[300], // Placeholder for alerts graph
                            child: const Center(child: Text('Alerts Graph Placeholder')),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            height: 200,
                            width: double.infinity,
                            color: Colors.grey[300], // Placeholder for total time graph
                            child: const Center(child: Text('Total Time Graph Placeholder')),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            height: 200,
                            width: double.infinity,
                            color: Colors.grey[300], // Placeholder for heatmap
                            child: const Center(child: Text('Heatmap Placeholder')),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
