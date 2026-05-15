import 'package:flutter/material.dart';

/// Premium color palette for VD Shift Manager
/// Theme: Dark Navy + Gold Professional
class AppColors {
  AppColors._();

  // Primary - Deep Navy
  static const Color primaryDark = Color(0xFF0A1628);
  static const Color primary = Color(0xFF0F2140);
  static const Color primaryLight = Color(0xFF1A3258);

  // Accent - Premium Gold
  static const Color accent = Color(0xFFD4A04A);
  static const Color accentLight = Color(0xFFE8C07A);
  static const Color accentDark = Color(0xFFB8862E);

  // Surface Colors (Dark Mode)
  static const Color surfaceDark = Color(0xFF111B2E);
  static const Color cardDark = Color(0xFF162038);
  static const Color cardDarkElevated = Color(0xFF1C2A48);

  // Surface Colors (Light Mode)
  static const Color surfaceLight = Color(0xFFF5F5F7);
  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color cardLightElevated = Color(0xFFF0F0F5);

  // Text Colors
  static const Color textPrimaryDark = Color(0xFFE8E8F0);
  static const Color textSecondaryDark = Color(0xFF8A8FA8);
  static const Color textPrimaryLight = Color(0xFF1A1A2E);
  static const Color textSecondaryLight = Color(0xFF6B7085);

  // Status Colors
  static const Color success = Color(0xFF2ECC71);
  static const Color warning = Color(0xFFF39C12);
  static const Color error = Color(0xFFE74C3C);
  static const Color info = Color(0xFF3498DB);

  // Chart Colors
  static const Color chartBlue = Color(0xFF4A90D9);
  static const Color chartGreen = Color(0xFF27AE60);
  static const Color chartOrange = Color(0xFFE67E22);
  static const Color chartPurple = Color(0xFF9B59B6);
  static const Color chartCyan = Color(0xFF1ABC9C);

  // Gradient - Primary
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, primaryLight],
  );

  // Gradient - Accent/Gold
  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [accentDark, accent, accentLight],
  );

  // Gradient - Card
  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [cardDark, cardDarkElevated],
  );

  // Gradient - Earning Card
  static const LinearGradient earningGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1A3258), Color(0xFF0F2140)],
  );
}
