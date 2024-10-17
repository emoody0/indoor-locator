import 'package:flutter/material.dart';
import 'config.dart';

class ConfigureAlertWindowsPage extends StatefulWidget {
  const ConfigureAlertWindowsPage({Key? key}) : super(key: key);

  @override
  _ConfigureAlertWindowsPageState createState() => _ConfigureAlertWindowsPageState();
}

class _ConfigureAlertWindowsPageState extends State<ConfigureAlertWindowsPage> {
  final List<String> spaces = ['Space A', 'Space B', 'Space C'];
  Map<String, String> selectedTimes = {};

  // Generate time options from 30 minutes to 6 hours
  List<String> generateTimeOptions() {
    List<String> times = [];
    for (int hour = 0; hour <= 6; hour++) {
      for (int minute = 0; minute < 60; minute += 30) {
        if (hour == 0 && minute == 0) continue; // Skip 0:00
        String time = '${hour > 0 ? hour.toString() + ' hr ' : ''}${minute > 0 ? minute.toString() + ' min' : ''}';
        times.add(time.trim());
      }
    }
    return times;
  }

  @override
  void initState() {
    super.initState();
    // Set default value for each space
    for (var space in spaces) {
      selectedTimes[space] = '2 hr'; // Default value is 2 hours
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configure Alert Windows'),
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
        child: ListView.builder(
          itemCount: spaces.length,
          itemBuilder: (context, index) {
            String space = spaces[index];
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  space,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                DropdownButton<String>(
                  value: selectedTimes[space],
                  items: generateTimeOptions().map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedTimes[space] = value!;
                    });
                  },
                ),
                const SizedBox(height: 20),
              ],
            );
          },
        ),
      ),
    );
  }
}