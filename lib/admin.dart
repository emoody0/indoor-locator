import 'package:flutter/material.dart';
import 'config.dart';
import 'settings.dart';
import 'view_logs.dart';
import 'view_alerts.dart';

class AdminPortal extends StatelessWidget {
  const AdminPortal({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Admin Portal'),
        backgroundColor: AppColors.primaryColor,
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
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
              leading: Icon(Icons.article),
              title: Text('View Logs'),
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
              leading: Icon(Icons.notifications),
              title: Text('View Alerts'),
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
              leading: Icon(Icons.settings),
              title: Text('Settings'),
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
              leading: Icon(Icons.logout),
              title: Text('Log Out'),
              onTap: () {
                Navigator.popUntil(context, (route) => route.isFirst);
              },
            ),
          ],
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              '___ alerts today from ___ residents\nMore general data here!', // Placeholder for alert count
              style: TextStyle(fontSize: 24),
            ),
          ],
        ),
      ),
    );
  }
}