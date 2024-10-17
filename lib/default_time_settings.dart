import 'package:flutter/material.dart';
import 'config.dart'; // Import config file
import 'configure_alert_windows.dart'; // Import the ConfigureAlertWindowsPage file


class DefaultTimeSettingsPage extends StatefulWidget {
  final bool isAdmin; // Parameter to determine if the user is an admin

  const DefaultTimeSettingsPage({super.key, required this.isAdmin});

  @override
  _DefaultTimeSettingsPageState createState() => _DefaultTimeSettingsPageState();
}

class _DefaultTimeSettingsPageState extends State<DefaultTimeSettingsPage> {
  String? monitoringStartTime; // For monitoring start time
  String? monitoringEndTime; // For monitoring end time
  String? selectedSensor; // For selected sensor (only for admin)
  int? reAlertMinutes; // For re-alert minutes

  // Generate time options in 30-minute increments
  List<String> generateTimeOptions() {
    List<String> times = [];
    for (int hour = 0; hour < 24; hour++) {
      for (int minute = 0; minute < 60; minute += 30) {
        String time = '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
        times.add(time);
      }
    }
    return times;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configure Default Time Settings'),
        backgroundColor: AppColors.colorScheme.primary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context); // Back button functionality
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // Default Monitoring Time Window
            const Text(
              'Monitoring Time Window:',
              style: TextStyle(fontSize: 18),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                DropdownButton<String>(
                  value: monitoringStartTime,
                  hint: const Text('Start Time'),
                  items: generateTimeOptions().map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      monitoringStartTime = value;
                    });
                  },
                ),
                const Text('to'),
                DropdownButton<String>(
                  value: monitoringEndTime,
                  hint: const Text('End Time'),
                  items: generateTimeOptions().map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      monitoringEndTime = value;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Set Alert Windows for Spaces (Admin only)
            if (widget.isAdmin) ...[
              const Text('Set Alert Windows for Spaces:'),
              ElevatedButton(
                onPressed: () {
                  // Navigate to ConfigureAlertWindowsPage
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ConfigureAlertWindowsPage(),
                    ),
                  );
                },
                child: const Text('Set Alert Windows for Spaces'),
              ),
              const SizedBox(height: 20),
            ],


            // Re-alert Resident After
            const Text('Re-alert Resident After:'),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                DropdownButton<int>(
                  value: reAlertMinutes,
                  hint: const Text('Minutes'),
                  items: List.generate(13, (index) {
                    return DropdownMenuItem<int>(
                      value: index * 5, // 5-minute increments
                      child: Text('${index * 5} minutes'),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      reAlertMinutes = value;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Note about user privacy (for Residents)
            if (!widget.isAdmin) ...[
              const Divider(), // Divider for visual separation
              const Text(
                'Please note: For user privacy, you may configure your own time settings but cannot modify global settings.',
                style: TextStyle(fontSize: 14, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ] else ...[
              const Divider(), // Divider for visual separation
              const Text(
                'Please note: For user privacy, users may or may not configure their own time settings.',
                style: TextStyle(fontSize: 14, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
