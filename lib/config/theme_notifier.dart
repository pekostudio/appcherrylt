import 'package:appcherrylt/config/theme.dart';
import 'package:flutter/material.dart';

class ThemeNotifier with ChangeNotifier {
  ThemeData _currentTheme = cherryLightTheme;

  ThemeData getTheme() => _currentTheme;

  void setTheme(ThemeData theme) {
    _currentTheme = theme;
    notifyListeners();
  }
}
