import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:journal_app/providers/app_settings.dart';

void main() {
  group('AppSettings', () {
    late AppSettings settings;

    setUp(() => settings = AppSettings());

    test('toggleDarkMode notifies listeners', () {
      var notified = false;
      settings.addListener(() => notified = true);

      settings.toggleDarkMode(true);
      expect(settings.isDarkMode, isTrue);
      expect(notified, isTrue);
    });

    test('updateHeaderColor changes color', () {
      var notified = false;
      settings.addListener(() => notified = true);

      settings.updateHeaderColor(Color(0xFFFF0000));
      expect(settings.headerColor, equals(Color(0xFFFF0000)));
      expect(notified, isTrue);
    });
  });
}
