import 'package:flutter/material.dart';

// This file holds all the centralized configurations for the app.

// Color scheme configuration
class AppColors {
  static const Color primaryColor = Colors.blue;
  static const ColorScheme colorScheme = ColorScheme(
    primary: primaryColor,
    primaryContainer: Colors.blueAccent, // Updated from primaryVariant
    secondary: Colors.green,
    secondaryContainer: Colors.greenAccent, // Updated from secondaryVariant
    surface: Colors.white,
    background: Colors.grey,
    error: Colors.red,
    onPrimary: Colors.white,
    onSecondary: Colors.white,
    onSurface: Colors.black,
    onBackground: Colors.black,
    onError: Colors.white,
    brightness: Brightness.light,
  );
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
