import 'package:flutter/material.dart';
import '../config.dart';

class DailyReportsPage extends StatefulWidget {
  final bool isAdmin;

  const DailyReportsPage({super.key, required this.isAdmin});

  @override
  _DailyReportsPageState createState() => _DailyReportsPageState();
}

class _DailyReportsPageState extends State<DailyReportsPage> {
  String? selectedDate; // Selected date for the report
  String? selectedUser; // Selected user (Admin-only)
  
  // Placeholder for dynamic data fetched from a database
  Map<String, dynamic> reportData = {
    'mostActiveTime': null,
    'leastActiveTime': null,
    'mostTimeSpent': null,
    'areasExplored': null,
    'activityComparison': null,
    'alertsToday': null,
  };

  // Example data
  final List<String> dates = ['Today', 'Yesterday', '01/20/2025', '01/19/2025'];
  final List<String> users = ['User1', 'User2', 'User3']; // Admin-only

  void fetchReportData() {
    // Simulate fetching data from the database
    setState(() {
      reportData = {
        'mostActiveTime': '4:00pm - 8:00pm (no alerts)',
        'leastActiveTime': '8:00am - 12:00pm (2 alerts)',
        'mostTimeSpent': 'Living Room, Couch',
        'areasExplored': ['Bedroom', 'Living Room', 'Bathroom', 'Kitchen'],
        'activityComparison': 'You were more active today, good job!',
        'alertsToday': 5,
      };
    });
  }

  @override
  void initState() {
    super.initState();
    fetchReportData(); // Fetch initial report data (e.g., "Today" for the logged-in user)
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isAdmin ? 'Admin Daily Reports' : 'Resident Daily Reports'),
        backgroundColor: AppColors.primaryColor,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Dropdown to select a date
            DropdownButtonFormField<String>(
              value: selectedDate,
              hint: const Text('Select a date'),
              items: dates.map((date) {
                return DropdownMenuItem<String>(
                  value: date,
                  child: Text(date),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedDate = value;
                  fetchReportData(); // Simulate fetching data for the selected date
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
                      'Daily Report for ${selectedUser ?? 'you'} (${selectedDate ?? 'Today'}):',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    Text(
                      'Most active time period: ${reportData['mostActiveTime'] ?? 'Loading...'}',
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 8),

                    Text(
                      'Least active time period: ${reportData['leastActiveTime'] ?? 'Loading...'}',
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 8),

                    Text(
                      'Most time spent: ${reportData['mostTimeSpent'] ?? 'Loading...'}',
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 8),

                    Text(
                      'Areas explored today: ${(reportData['areasExplored'] as List<String>?)?.join(', ') ?? 'Loading...'}',
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 8),

                    Text(
                      '${reportData['activityComparison'] ?? 'Loading...'}',
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 8),

                    Text(
                      'You received ${reportData['alertsToday'] ?? 'Loading...'} total alerts today.',
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
