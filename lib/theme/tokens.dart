import 'package:flutter/material.dart';
import 'app_theme.dart';

class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;
}

class AppRadius {
  static const double card = 20;
  static const double cardLarge = 24;
  static const double pill = 50;
  static const double button = 12;
  static const double small = 8;
}

class AppShadows {
  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.25),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> glowShadow(Color color) => [
        BoxShadow(
          color: color.withValues(alpha: 0.3),
          blurRadius: 16,
          spreadRadius: 1,
        ),
      ];

  static List<BoxShadow> get subtleGlow => [
        BoxShadow(
          color: AppColors.primary.withValues(alpha: 0.15),
          blurRadius: 12,
          spreadRadius: 0,
        ),
      ];
}

class AppGradients {
  static const primaryGradient = LinearGradient(
    colors: [AppColors.primary, Color(0xFF2BC89B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const secondaryGradient = LinearGradient(
    colors: [AppColors.secondary, Color(0xFF6B5CE7)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const surfaceGradient = LinearGradient(
    colors: [Color(0xFF1E2433), Color(0xFF161B26)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const backgroundGradient = LinearGradient(
    colors: [Color(0xFF131620), AppColors.background],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const statusCardGradient = LinearGradient(
    colors: [Color(0xFF1E2A3A), Color(0xFF162030)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
