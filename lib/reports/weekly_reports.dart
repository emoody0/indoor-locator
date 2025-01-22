import 'package:flutter/material.dart';
import '../config.dart';

class WeeklyReportsPage extends StatefulWidget {
  final bool isAdmin;

  const WeeklyReportsPage({super.key, required this.isAdmin});

  @override
  _WeeklyReportsPageState createState() => _WeeklyReportsPageState();
}

class _WeeklyReportsPageState extends State<WeeklyReportsPage> {
  String? selectedWeek; // For dropdown to select a week
  String? selectedUser; // Admin-only feature to select a user

  // Placeholder for dynamic data fetched from a database
  Map<String, dynamic> reportData = {
    'mostActiveDay': null,
    'leastActiveDay': null,
    'mostTimeSpent': null,
    'daysWithFewAlerts': null,
    'weeklyComparison': null,
    'rewardEarned': null,
    'totalAlerts': {
      'thisWeek': null,
      'lastWeek': null,
    },
  };

  // Example data
  final List<String> weeks = ['This Week', 'Last Week', 'Week of 01/14/2025'];
  final List<String> users = ['User1', 'User2', 'User3']; // Admin-only

  void fetchReportData() {
    // Simulate fetching data from the database
    setState(() {
      reportData = {
        'mostActiveDay': 'Monday (0 alerts)',
        'leastActiveDay': 'Wednesday (4 alerts)',
        'mostTimeSpent': 'Living Room, Desk',
        'daysWithFewAlerts': ['Monday', 'Thursday', 'Friday'],
        'weeklyComparison': 'You were more active this week; keep it up!',
        'rewardEarned': 'Try again next week to receive a reward.',
        'totalAlerts': {
          'thisWeek': 10,
          'lastWeek': 15,
        },
      };
    });
  }

  @override
  void initState() {
    super.initState();
    fetchReportData(); // Fetch initial report data (e.g., for "This Week")
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isAdmin ? 'Admin Weekly Reports' : 'Resident Weekly Reports'),
        backgroundColor: AppColors.primaryColor,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Dropdown to select a week
            DropdownButtonFormField<String>(
              value: selectedWeek,
              hint: const Text('Select a week'),
              items: weeks.map((week) {
                return DropdownMenuItem<String>(
                  value: week,
                  child: Text(week),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedWeek = value;
                  fetchReportData(); // Simulate fetching data for the selected week
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
                    value: user,
                    child: Text(user),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedUser = value;
                    fetchReportData(); // Simulate fetching data for the selected user
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
                      'Weekly Report for ${selectedUser ?? 'you'} (${selectedWeek ?? 'This Week'}):',
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
                      '${reportData['weeklyComparison'] ?? 'Loading...'}',
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 8),

                    Text(
                      '${reportData['rewardEarned'] ?? 'Loading...'}',
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 16),

                    Text(
                      'Total alerts this week: ${reportData['totalAlerts']['thisWeek'] ?? 'Loading...'}',
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 8),

                    Text(
                      'Total alerts last week: ${reportData['totalAlerts']['lastWeek'] ?? 'Loading...'}',
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
                            color: Colors.grey[300], // Placeholder for alert graph
                            child: const Center(child: Text('Alert Graph Placeholder')),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            height: 200,
                            width: double.infinity,
                            color: Colors.grey[300], // Placeholder for total time spent graph
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
