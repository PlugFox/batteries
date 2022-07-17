import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_batteries/flutter_batteries.dart';

void main() => runZonedGuarded<Future<void>>(
      () async {
        runApp(const App());
      },
      (error, stackTrace) => log(
        'Top level exception',
        error: error,
        stackTrace: stackTrace,
        level: 1000,
        name: 'main',
      ),
    );

final AppModel appModel = AppModel();

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<ThemeData>(
        valueListenable: appModel.select<ThemeData>(
          (controller) => controller.themeData,
          (prev, next) => prev.brightness != next.brightness,
        ),
        builder: (context, themeData, child) => MaterialApp(
          title: 'Material App',
          theme: themeData,
          home: Scaffold(
            body: SafeArea(
              child: Center(
                child: TextButton(
                  onPressed: appModel.switchTheme,
                  child: Text('Switch theme'),
                ),
              ),
            ),
          ),
        ),
      );
}

class AppModel with ChangeNotifier {
  ThemeData get themeData => _themeData;
  ThemeData _themeData = ThemeData.light();
  void switchTheme() {
    _themeData = _themeData.brightness == Brightness.light
        ? ThemeData.dark()
        : ThemeData.light();
    notifyListeners();
  }
}
