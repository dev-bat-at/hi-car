import 'package:flutter/material.dart';

/// Design tokens for Giọng Thương Gia - Automotive Dark Theme
class AppColors {
  AppColors._();

  // ===== Primary =====
  static const Color primary = Color(0xFF00E5FF);
  static const Color primaryDark = Color(0xFF00B8CC);
  static const Color primaryLight = Color(0xFF61FFFF);

  // ===== Background =====
  static const Color background = Color(0xFF000000);
  static const Color surface = Color(0xFF080808);
  static const Color card = Color(0xFF0F0F0F);
  static const Color cardElevated = Color(0xFF161616);
  static const Color divider = Color(0xFF1C1C1C);
  static const Color border = Color(0xFF222222);

  // ===== Text =====
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF8C9EAA);
  static const Color textHint = Color(0xFF445566);
  static const Color textDisabled = Color(0xFF334455);

  // ===== Status =====
  static const Color success = Color(0xFF00E676);
  static const Color error = Color(0xFFFF3D71);
  static const Color warning = Color(0xFFFFAB00);
  static const Color info = Color(0xFF0091EA);

  // ===== Glows =====
  static Color get primaryGlow => primary.withOpacity(0.25);
  static Color get primaryGlowStrong => primary.withOpacity(0.45);
  static Color get primaryFaint => primary.withOpacity(0.08);
  static Color get primaryFaintest => primary.withOpacity(0.05);
  static Color get successGlow => success.withOpacity(0.25);
  static Color get errorGlow => error.withOpacity(0.25);

  // ===== Gradients =====
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF00E5FF), Color(0xFF0072FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkGradient = LinearGradient(
    colors: [Color(0xFF0A0A0A), Color(0xFF000000)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFF141414), Color(0xFF0A0A0A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
