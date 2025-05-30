import 'package:flutter/material.dart';

/// Manages global application settings such as dark mode and header color.
/// 
/// Extends [ChangeNotifier] so that UI widgets can listen for updates.
class AppSettings extends ChangeNotifier {
  /// Whether dark mode is currently enabled.
  bool isDarkMode = false;

  /// The current color used for the app’s header bar.
  Color headerColor = Colors.lightBlue;

  /// Enables or disables dark mode.
  ///
  /// [value] true to turn on dark mode; false to use light mode.
  /// Calls [notifyListeners] after updating.
  void toggleDarkMode(bool value) {
    isDarkMode = value;
    notifyListeners();
  }

  /// Changes the app header’s color.
  ///
  /// [color] The new [Color] for the header bar.
  /// Calls [notifyListeners] after updating.
  void updateHeaderColor(Color color) {
    headerColor = color;
    notifyListeners();
  }
}
