import 'package:flutter/material.dart';
import 'package:g14_indoor_locator/houses/manage_houses.dart';
import 'package:g14_indoor_locator/houses/manage_spaces.dart';
import 'package:g14_indoor_locator/users/manage_users.dart';
import 'config.dart'; // Import config file
import '../time_windows/default_time_settings.dart'; // Import Default Time Settings Page
import '../houses/new_house_setup.dart'; // Import New House Setup Page

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: AppColors.colorScheme.primary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context); // Back button functionality
          },
        ),
      ),
      body: Column(
        children: <Widget>[
          ListTile(
            title: const Text('Manage Users'),
            onTap: () {
              // Navigate to Manage Users Page
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ManageUsersPage()),
              );
            },
          ),
          ListTile(
            title: const Text('Manage Houses'),
            onTap: () {
              // Navigate to Manage Houses Page
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ManageHousesPage()),
              );
            },
          ),
          ListTile(
            title: const Text('New House Setup'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const NewHouseSetupPage()),
              );
            },
          ),
          ListTile(
            title: const Text('Set Default Time Windows'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => DefaultTimeSettingsPage(
                  key: UniqueKey(),
                  isAdmin: true,
                )),
              );
            },
          ),
        ],
      ),
    );
  }
}