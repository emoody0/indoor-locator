import 'package:flutter/material.dart';
import '../config.dart'; // Import config file
// Import the ConfigureAlertWindowsPage file
import '../server/database_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DefaultTimeSettingsPage extends StatefulWidget {
  final bool isAdmin; // Parameter to determine if the user is an admin

  const DefaultTimeSettingsPage({super.key, required this.isAdmin});

  @override
  _DefaultTimeSettingsPageState createState() => _DefaultTimeSettingsPageState();
}

class _DefaultTimeSettingsPageState extends State<DefaultTimeSettingsPage> {
  String? monitoringStartTime; // For monitoring start time
  String? monitoringEndTime; // For monitoring end time
  int? reAlertMinutes; // For re-alert minutes

  @override
  void initState() {
    super.initState();
    loadUserSettings();
  }

  Future<void> loadUserSettings() async {
    final db = DatabaseHelper();
    final prefs = await SharedPreferences.getInstance();
    int userId = prefs.getInt('user_id') ?? -1;

    print("DEBUG: Retrieved user_id from SharedPreferences: $userId");

    if (userId == -1) {
        print("DEBUG: User ID not found in SharedPreferences, attempting database lookup...");
        List<Map<String, dynamic>> users = await db.getUsers();
        if (users.isNotEmpty) {
            userId = users.first['id'] ?? -1;
            await prefs.setInt('user_id', userId);
            print("DEBUG: Retrieved user_id from DB and saved: $userId");
        } else {
            print("DEBUG: No users found in the database.");
            return;
        }
    }

    List<Map<String, dynamic>> userData = await db.getUsers();
    var user = userData.firstWhere((u) => u['id'] == userId, orElse: () => {});

    if (user.isNotEmpty) {
        print("DEBUG: Retrieved user settings from DB: $user");

        int startWindow = user['start_window'] is int
            ? user['start_window']
            : _convertToInt(user['start_window']);

        int endWindow = user['end_window'] is int
            ? user['end_window']
            : _convertToInt(user['end_window']);

        print("DEBUG: Corrected StartWindow: $startWindow, EndWindow: $endWindow");

        setState(() {
            monitoringStartTime = _epochToTime(startWindow);
            monitoringEndTime = _epochToTime(endWindow);
        });

        print("DEBUG: Updated UI with new settings - Start: $monitoringStartTime, End: $monitoringEndTime");
    } else {
        print("DEBUG: No user settings found for user ID $userId in database");
    }
  }




// Utility function to safely convert values to integers
  int _convertToInt(dynamic value) {
    if (value is int) {
        return value;  // If it's already an integer, return as is
    } else if (value is String) {
        int? parsedValue = int.tryParse(value);
        if (parsedValue != null) {
            return parsedValue;
        }
    }
    print("WARNING: Unexpected data type for time value: $value (${value.runtimeType})");
    return 0;  // Return 0 instead of 28800000 to avoid forcing an incorrect time
  }





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

  Future<void> saveTimeWindow() async {
    final db = DatabaseHelper();
    final prefs = await SharedPreferences.getInstance();
    int userId = prefs.getInt('user_id') ?? -1;

    if (userId == -1) {
        print("DEBUG: No valid user ID found for saving settings.");
        return;
    }

    int startEpoch = _timeToEpoch(monitoringStartTime!);
    int endEpoch = _timeToEpoch(monitoringEndTime!);

    print("DEBUG: Attempting to update user time window - Start: $monitoringStartTime ($startEpoch), End: $monitoringEndTime ($endEpoch)");

    await db.updateUserTimeWindow(userId, startEpoch, endEpoch);

    // Remove old SharedPreferences values and set new ones
    await prefs.setInt('start_window', startEpoch);
    await prefs.setInt('end_window', endEpoch);

    // Ensure UI updates immediately
    setState(() {
        monitoringStartTime = _epochToTime(startEpoch);
        monitoringEndTime = _epochToTime(endEpoch);
    });

    // Delay before reloading from the database
    await Future.delayed(const Duration(milliseconds: 500)); // Ensure DB transaction completes
    await loadUserSettings();

    print("DEBUG: Successfully updated and reloaded user settings.");
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Time settings updated successfully!')),
    );
  }


  


  Future<void> revertToDefault() async {
    final db = DatabaseHelper();
    final prefs = await SharedPreferences.getInstance();
    int? userId = prefs.getInt('user_id');

    print("DEBUG: Attempting to revert settings for user ID: $userId");

    if (userId != null && userId != -1) {
        await db.revertToDefaultTimeWindow(userId);
        print("DEBUG: User reverted to default settings successfully");
        await loadUserSettings();
    } else {
        print("DEBUG: Failed to revert settings - user ID not found, retrying fetch from DB");

        // Fetch the first user from the database and retry
        List<Map<String, dynamic>> users = await db.getUsers();
        if (users.isNotEmpty) {
            int newUserId = users.first['id'];
            await prefs.setInt('user_id', newUserId);
            print("DEBUG: Retrieved user_id from DB and saved: $newUserId");
            await db.revertToDefaultTimeWindow(newUserId);
            await loadUserSettings();
        } else {
            print("DEBUG: No user found in DB");
        }
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Reverted to default settings')),
    );
  }


  int _timeToEpoch(String time) {
    List<String> parts = time.split(':');
    int hour = int.parse(parts[0]);
    int minute = int.parse(parts[1]);
    DateTime now = DateTime.now();
    return DateTime(now.year, now.month, now.day, hour, minute).millisecondsSinceEpoch;
  }

  String _epochToTime(int epoch) {
    DateTime date = DateTime.fromMillisecondsSinceEpoch(epoch, isUtc: true).toLocal();
    String formattedTime = '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    
    print("DEBUG: Converted epoch $epoch to time string: $formattedTime");
    return formattedTime;
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isAdmin ? 'Configure Default Time Windows' : 'Configure Time Windows'),
        backgroundColor: AppColors.colorScheme.primary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text('Monitoring Time Window:', style: TextStyle(fontSize: 18)),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                DropdownButton<String>(
                  value: monitoringStartTime ?? generateTimeOptions().first,
                  hint: const Text('Select Start Time'),
                  items: generateTimeOptions().map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      monitoringStartTime = value;
                    });
                    print("DEBUG: Start time changed to $monitoringStartTime");
                  },
                ),
                const Text('to'),
                DropdownButton<String>(
                  value: monitoringEndTime ?? generateTimeOptions().first,
                  hint: const Text('Select End Time'),
                  items: generateTimeOptions().map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      monitoringEndTime = value;
                    });
                    print("DEBUG: End time changed to $monitoringEndTime");
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: saveTimeWindow,
              child: const Text('Save'),
            ),
            if (!widget.isAdmin) ...[
              ElevatedButton(
                onPressed: revertToDefault,
                child: const Text('Revert to Default Settings'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
