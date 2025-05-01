import 'package:flutter/material.dart';
import 'package:g14_indoor_locator/houses/manage_houses.dart';
import 'package:g14_indoor_locator/users/manage_users_UI.dart';
import '../time_windows/default_time_settings.dart'; // Import Default Time Settings Page
import 'package:provider/provider.dart';
import 'theme_color_notifier.dart'; //
import 'package:flutter_colorpicker/flutter_colorpicker.dart'; // Import ColorPicker

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Provider.of<ThemeColorNotifier>(context).primaryColor,
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
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ManageUsersPage()),
              );
            },
          ),
          ListTile(
            title: const Text('Manage Houses'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ManageHousesPage()),
              );
            },
          ),
          ListTile(
            title: const Text('Set Default Time Windows'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => DefaultTimeSettingsPage(
                          key: UniqueKey(),
                          isAdmin: true,
                        )),
              );
            },
          ),
          ListTile(
            title: const Text('Change Banner Color'),
            onTap: () => showColorPicker(context),
          ),
        ],
      ),
    );
  }

  void showColorPicker(BuildContext context) {
    final themeNotifier = Provider.of<ThemeColorNotifier>(context, listen: false);
    Color currentColor = themeNotifier.primaryColor;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Pick Banner Color'),
          content: SingleChildScrollView(
            child: ColorPicker(
              pickerColor: currentColor,
              onColorChanged: (Color color) {
                currentColor = color;
              },
            ),
          ),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Save'),
              onPressed: () {
                themeNotifier.setPrimaryColor(currentColor); // ✅ triggers immediate update
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}