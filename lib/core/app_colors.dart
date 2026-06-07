import 'package:flutter/material.dart';

/// Design tokens for Giọng Thương Gia - Premium "Cyberpunk Automotive" Theme
/// Standardized on 005CFF Sky Blue with ultra-deep surfaces and SHARP accents.
class AppColors {
  AppColors._();

  // ===== Primary Accents (Vibrant 005CFF) =====
  static const Color primary = Color(0xFF005CFF);
  static const Color primaryDark = Color(0xFF0044CC);
  static const Color primaryLight = Color(0xFF337DFF);

  // Specific color requested by user: 005CFF
  static const Color brandBlue = Color(0xFF005CFF);

  // ===== Background & Surfaces (Deep, Sharp, Premium) =====
  static const Color background = Color(
      0xFF020617); // Ultra Deep Navy Black (Tailwind Slate-950 equivalent)
  static const Color surface = Color(0xFF0F172A); // Slate-900
  static const Color card =
      Color(0xFF1E293B); // Slate-800 - much more distinct and premium
  static const Color cardElevated = Color(0xFF334155); // Slate-700
  static const Color divider = Color(0xFF334155); // Clearly visible
  static const Color border = Color(0xFF475569); // Sharp borders

  // ===== Text (Crystal White & Silver) =====
  static const Color textPrimary = Color(0xFFF8FAFC); // Crystal White
  static const Color textSecondary =
      Color(0xFFCBD5E1); // Silver Grey (Tailwind Slate-300)
  static const Color textHint = Color(0xFF94A3B8); // Slate-400
  static const Color textDisabled = Color(0xFF64748B);

  // ===== Status (Vivid Solids) =====
  static const Color success = Color(0xFF22C55E); // Green-500
  static const Color error = Color(0xFF334155); // Neutral Slate (No Red)
  static const Color warning = Color(0xFFEAB308); // Yellow-500
  static const Color info = Color(0xFF0EA5E9); // Sky-500

  // ===== Brand Solids (For containers and accents) =====
  static const Color brandBackground =
      Color(0xFF0F172A); // Deep contrast for icons
  static const Color primaryBackground = Color(0xFF1E3A8A); // Blue-900

  // ===== Gradients (Keep it simple but premium) =====
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, Color(0xFF0044CC)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
