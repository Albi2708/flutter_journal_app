import 'package:flutter/material.dart';
import 'package:journal_app/main.dart';
import 'package:provider/provider.dart';
import 'providers/app_settings.dart';
import 'screens/home_screen.dart';

/// The root widget of the Journal App.
///
/// Listens to [AppSettings] to apply dynamic theming, and sets up
/// the home screen and navigation observers.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Watch for changes in dark mode and header color.
    final settings = context.watch<AppSettings>();

    return MaterialApp(
      title: 'Journal App',
      theme: ThemeData(
        // Switch between light and dark based on user setting.
        brightness: settings.isDarkMode ? Brightness.dark : Brightness.light,
        // Apply the chosen header color to all AppBars.
        appBarTheme: AppBarTheme(backgroundColor: settings.headerColor),
        useMaterial3: true,
      ),
      // The first screen displayed when the app launches.
      home: const HomeScreen(),
      // Observe route changes to refresh UI when returning to HomeScreen.
      navigatorObservers: [routeObserver],
    );
  }
}
