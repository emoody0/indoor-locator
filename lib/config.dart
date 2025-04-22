import 'package:flutter/material.dart';

// This file holds all the centralized configurations for the app.

// Color scheme configuration
class AppColors {
  static Color primaryColor = Colors.blue; // Default banner color

  static const ColorScheme colorScheme = ColorScheme(
    primary: Colors.blue,
    primaryContainer: Colors.blueAccent,
    secondary: Colors.green,
    secondaryContainer: Colors.greenAccent,
    surface: Colors.white,
    error: Colors.red,
    onPrimary: Colors.white,
    onSecondary: Colors.white,
    onSurface: Colors.black,
    onError: Colors.white,
    brightness: Brightness.light,
  );

  static void setPrimaryColor(Color color) {
    primaryColor = color;
  }
}


// Permission-related data
class PermissionData {
  static const List<String> adminPermissions = [
    'Manage Users',
    'View Reports',
    'Modify Settings', // Added more permissions as an example
  ];

  static const List<String> residentPermissions = [
    'View Profile',
    'Submit Feedback',
    'Request Assistance',
  ];
}

// Default values or configurations (future expansion)
class DefaultValues {
  static const String defaultUsername = 'Guest';
  static const int timeoutDuration = 300; // Timeout in seconds
}
