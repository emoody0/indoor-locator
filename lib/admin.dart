import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'config.dart';
import 'settings.dart';
import '../../log_view/view_logs.dart';
import '../../log_view/view_alerts.dart';
import '../../server/manage_sql_page.dart'; // Import the new SQL management page
import '../../reports/reports.dart';
import '../../server/mqtt.dart'; // This should export your MQTTPage widget
import 'main.dart';

class AdminPortal extends StatelessWidget {
  final VoidCallback onLogout;

  const AdminPortal({super.key, required this.onLogout});

  Future<void> _logout(BuildContext context) async {
    // print("DEBUG: Logout function called!");
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('logged_in_user');
    // print("DEBUG: User logged out, SharedPreferences cleared.");

    // Trigger auto-login again after logout
    String newUser = await MyApp().autoLogin();
    // print("DEBUG: New user after logout: $newUser");

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (Route<dynamic> route) => false,
    );
  }



  Future<String> _getCurrentUser() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    String? user = prefs.getString('logged_in_user');
    // print("DEBUG: Fetching from SharedPreferences, found: $user");
    return user ?? 'Unknown User';
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Portal'),
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
                'Admin Menu',
                style: TextStyle(
                  color: AppColors.colorScheme.onPrimary,
                  fontSize: 24,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.article),
              title: const Text('View Logs'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ViewLogsPage(
                      key: UniqueKey(),
                      isAdmin: true,
                    ),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.notifications),
              title: const Text('View Alerts'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ViewAlertsPage(
                      key: UniqueKey(),
                      isAdmin: true,
                    ),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Settings'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SettingsPage(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.table_chart),
              title: const Text('Manage SQL Tables'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ManageSQLPage(),
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
                    builder: (context) => const ReportsPage(
                      isAdmin: true,
                    ),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.network_wifi),
              title: const Text('MQTT Data'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MQTTPage(),
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
