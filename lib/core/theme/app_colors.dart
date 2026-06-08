import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const accent = Color(0xFFFF2D55);
  static const accentSoft = Color(0xFFFF6B81);

  static const bg = Color(0xFF08080A);
  static const bgElevated = Color(0xFF101013);

  static const surface = Color(0xFF16161B);
  static const surfaceHigh = Color(0xFF1E1E25);

  static const textPrimary = Color(0xFFF5F5F7);
  static const textSecondary = Color(0xFFA1A1AA);
  static const textMuted = Color(0xFF6B6B73);

  static const border = Color(0x14FFFFFF); // white 8%
  static const borderStrong = Color(0x29FFFFFF); // white 16%

  static const glassFill = Color(0x0FFFFFFF); // white 6%
  static const glassFillHigh = Color(0x1FFFFFFF); // white 12%

  static const success = Color(0xFF34D399);
  static const warning = Color(0xFFFBBF24);
  static const danger = Color(0xFFFB7185);

  static const accentGradient = LinearGradient(
    colors: [accent, Color(0xFFFF5E7A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const bgGradient = LinearGradient(
    colors: [Color(0xFF0C0C12), bg],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}

class AppRadius {
  AppRadius._();
  static const sm = 12.0;
  static const md = 16.0;
  static const lg = 20.0;
  static const xl = 28.0;
  static const pill = 999.0;
}

class AppSpace {
  AppSpace._();
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 24.0;
  static const xxl = 32.0;
}

class AppShadow {
  AppShadow._();

  static const soft = [
    BoxShadow(color: Color(0x40000000), blurRadius: 24, offset: Offset(0, 8)),
  ];

  static const accentGlow = [
    BoxShadow(color: Color(0x59FF2D55), blurRadius: 24, offset: Offset(0, 8)),
  ];
}
