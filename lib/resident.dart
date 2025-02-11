import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'database_helper.dart';
import 'config.dart';
import '../time_windows/default_time_settings.dart';
import '../log_view/view_logs.dart';
import '../log_view/view_alerts.dart';
import '../reports/reports.dart';

class ResidentPortal extends StatefulWidget {
  const ResidentPortal({super.key});

  @override
  State<ResidentPortal> createState() => _ResidentPortalState();
}

class _ResidentPortalState extends State<ResidentPortal> {
  User? currentUser;
  String? userType;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      String? type = await DatabaseHelper().getUserType(currentUser!.email!);
      setState(() {
        userType = type;
      });

      // If user is not a resident, log them out
      /*if (userType != 'Resident') {
        await FirebaseAuth.instance.signOut();
        Navigator.pushReplacementNamed(context, '/login');
      }*/
    }
  }

  void _logout() async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Resident Portal'),
        backgroundColor: AppColors.primaryColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
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
                      isAdmin: false, // Only allow changes to own settings
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
                      isAdmin: false, // No filtering options for residents
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
                      isAdmin: false, // No filtering options for residents
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
                    builder: (context) => const ReportsPage(
                      isAdmin: false,
                    ),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Log Out'),
              onTap: _logout, // Use Firebase logout function
            ),
          ],
        ),
      ),
      body: Center(
        child: currentUser == null
            ? const CircularProgressIndicator()
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Welcome, ${currentUser!.displayName ?? 'Resident'}",
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Text("Email: ${currentUser!.email}"),
                  const SizedBox(height: 20),
                  Text("Role: ${userType ?? 'Checking...'}"),
                  const SizedBox(height: 20),
                  const Text("Last alert: x time, y sensor\nStaying focused!"),
                ],
              ),
      ),
    );
  }
}
