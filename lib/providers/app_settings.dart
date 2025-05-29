import 'package:flutter/material.dart';

class AppSettings extends ChangeNotifier {
  bool isDarkMode = false;
  Color headerColor = Colors.lightBlue;

  void toggleDarkMode(bool value) {
    isDarkMode = value;
    notifyListeners();
  }

  void updateHeaderColor(Color color) {
    headerColor = color;
    notifyListeners();
  }
}
