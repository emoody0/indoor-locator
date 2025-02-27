import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'config.dart';
import '../time_windows/default_time_settings.dart';
import '../log_view/view_logs.dart';
import '../log_view/view_alerts.dart';
import '../reports/reports.dart';
import 'main.dart';

class ResidentPortal extends StatelessWidget {
  const ResidentPortal({super.key});

  Future<void> _logout(BuildContext context) async {
    print("DEBUG: Logout function called!");
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('logged_in_user');
    print("DEBUG: User logged out, SharedPreferences cleared.");

    // Trigger auto-login again after logout
    String newUser = await MyApp().autoLogin();
    print("DEBUG: New user after logout: $newUser");

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (Route<dynamic> route) => false,
    );
  }


  Future<String> _getCurrentUser() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    String? user = prefs.getString('logged_in_user');
    print("DEBUG: Fetching from SharedPreferences, found: $user");
    return user ?? 'Unknown User';
  }




  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Resident Portal'),
        backgroundColor: AppColors.primaryColor,
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                color: AppColors.primaryColor,
              ),
              child: Text(
                'Resident Menu',
                style: TextStyle(
                  color: AppColors.colorScheme.onPrimary,
                  fontSize: 24,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.access_time),
              title: const Text('Time Configuration Settings'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DefaultTimeSettingsPage(
                      key: UniqueKey(),
                      isAdmin: false,
                    ),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.list),
              title: const Text('View Logs'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ViewLogsPage(
                      key: UniqueKey(),
                      isAdmin: false,
                    ),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.warning),
              title: const Text('View Alerts'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ViewAlertsPage(
                      key: UniqueKey(),
                      isAdmin: false,
                    ),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.analytics_outlined),
              title: const Text('Reports'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ReportsPage(isAdmin: false),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Log Out'),
              onTap: () => _logout(context),
            ),
          ],
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            FutureBuilder<String>(
              future: _getCurrentUser(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                }
                return Text(
                  'Logged in as: ${snapshot.data}',
                  style: const TextStyle(fontSize: 24),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
