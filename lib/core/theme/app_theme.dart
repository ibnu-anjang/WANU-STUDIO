import 'package:flutter/material.dart';

class AppTheme {
  static const _seed = Color(0xFFFF2D55);

  static ThemeData get dark => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: _seed,
      brightness: Brightness.dark,
    ),
    scaffoldBackgroundColor: Colors.black,
  );
}
