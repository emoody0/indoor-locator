import 'package:flutter/material.dart';
import '../config.dart';
import 'daily_reports.dart';
import 'weekly_reports.dart';
import 'monthly_reports.dart';

class ReportsPage extends StatelessWidget {
  final bool isAdmin;

  const ReportsPage({super.key, required this.isAdmin});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isAdmin ? 'Admin Reports' : 'Resident Reports'),
        backgroundColor: AppColors.primaryColor,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
            spacing: 8, // Horizontal spacing
            runSpacing: 8, // Vertical spacing
            children: [
              ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DailyReportsPage(isAdmin: isAdmin),
                      ),
                    );
                  },
                  child: const Text('Daily Reports'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => WeeklyReportsPage(isAdmin: isAdmin),
                      ),
                    );
                  },
                  child: const Text('Weekly Reports'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MonthlyReportsPage(isAdmin: isAdmin),
                      ),
                    );
                  },
                  child: const Text('Monthly Reports'),
                ),
            ],
          ),
            const SizedBox(height: 16),
            Expanded(
              child: Center(
                child: Text(
                  isAdmin
                      ? 'Welcome to the Admin Reports page. Choose a report type to view details.'
                      : 'Welcome to the Resident Reports page. Choose a report type to view details.',
                  style: const TextStyle(fontSize: 18),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
