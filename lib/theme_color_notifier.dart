import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeColorNotifier extends ChangeNotifier {
  Color _primaryColor = Colors.blue;
  int? _userId;

  Color get primaryColor => _primaryColor;

  Future<void> setUserId(int userId) async {
    _userId = userId;
    await _loadColorFromPrefs();
  }

  Future<void> _loadColorFromPrefs() async {
    if (_userId == null) return;
    final prefs = await SharedPreferences.getInstance();
    final colorValue = prefs.getInt('primaryColor_user_$_userId');
    if (colorValue != null) {
      _primaryColor = Color(colorValue);
      notifyListeners();
    }
  }

  Future<void> setPrimaryColor(Color color) async {
    if (_userId == null) return;
    _primaryColor = color;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('primaryColor_user_$_userId', color.value);
  }
}
