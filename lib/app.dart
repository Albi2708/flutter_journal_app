import 'package:flutter/material.dart';
import 'package:journal_app/main.dart';
import 'package:provider/provider.dart';
import 'providers/app_settings.dart';
import 'screens/home_screen.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AppSettings>();
    return MaterialApp(
      title: 'Journal App',
      theme: ThemeData(
        brightness: settings.isDarkMode ? Brightness.dark : Brightness.light,
        appBarTheme: AppBarTheme(backgroundColor: settings.headerColor),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
      navigatorObservers: [routeObserver],
    );
  }
}
