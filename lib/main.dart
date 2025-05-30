import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'providers/app_settings.dart';
import 'app.dart';

/// Observes navigation changes for widgets that mix in [RouteAware].
/// Used by HomeScreen to refresh on return.
final RouteObserver<ModalRoute<dynamic>> routeObserver =
    RouteObserver<ModalRoute<dynamic>>();

/// Entry point of the application.
///
/// Initializes SQLite FFI on desktop platforms, then wraps [MyApp]
/// with [AppSettings] via [ChangeNotifierProvider].
void main() {
  // On desktop, initialize sqflite for ffi to run in Dart VM.
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  // Launch the app with AppSettings available throughout.
  runApp(
    ChangeNotifierProvider(
      create: (_) => AppSettings(),
      child: const MyApp(),
    ),
  );
}
