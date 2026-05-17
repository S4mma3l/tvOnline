import 'package:flutter/material.dart';

class AppColors {
  // Backgrounds
  static const Color background = Color(0xFF0A0A0F);
  static const Color surface = Color(0xFF141420);
  static const Color card = Color(0xFF1E1E2E);
  static const Color cardHover = Color(0xFF252535);

  // Accent
  static const Color primary = Color(0xFFE63946);
  static const Color primaryDark = Color(0xFFB02A33);
  static const Color primaryGlow = Color(0x44E63946);
  static const Color secondary = Color(0xFF7C6AF7);
  static const Color secondaryGlow = Color(0x447C6AF7);

  // Text
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB0B0C0);
  static const Color textMuted = Color(0xFF606070);
  static const Color textDisabled = Color(0xFF404050);

  // Status
  static const Color success = Color(0xFF2ECC71);
  static const Color warning = Color(0xFFF39C12);
  static const Color error = Color(0xFFE74C3C);
  static const Color info = Color(0xFF3498DB);

  // Rating
  static const Color ratingGold = Color(0xFFFFD700);
  static const Color ratingEmpty = Color(0xFF404050);

  // Player
  static const Color playerBackground = Color(0xFF000000);
  static const Color playerControls = Color(0xFFFFFFFF);
  static const Color playerControlsBg = Color(0x88000000);
  static const Color playerProgress = Color(0xFFE63946);
  static const Color playerBuffered = Color(0x66FFFFFF);

  // Gradients
  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0x00000000),
      Color(0x40000000),
      Color(0xCC000000),
      Color(0xFF0A0A0F),
    ],
    stops: [0.0, 0.4, 0.75, 1.0],
  );

  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0x00000000), Color(0xDD000000)],
    stops: [0.5, 1.0],
  );

  static const LinearGradient sideGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [Color(0xFF0A0A0F), Color(0x000A0A0F)],
  );

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFFE63946), Color(0xFFAA2030)],
  );
}
