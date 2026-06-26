import 'package:flutter/material.dart';

/// Centralized color palette. Primary accent is a deep purple/violet to give
/// the app a premium, futuristic feel distinct from the typical
/// green/blue palettes of other AI chat apps.
class AppColors {
  AppColors._();

  // Brand
  static const Color primary = Color(0xFF7C5CFF);
  static const Color primaryDark = Color(0xFF5B3FE0);
  static const Color primaryLight = Color(0xFFA98CFF);
  static const Color secondary = Color(0xFF00D4B8);

  // Dark theme surfaces
  static const Color darkBackground = Color(0xFF0E0B1A);
  static const Color darkSurface = Color(0xFF161229);
  static const Color darkSurfaceVariant = Color(0xFF1F1A36);
  static const Color darkCard = Color(0xFF1C1830);
  static const Color darkBorder = Color(0xFF2E2748);

  // Light theme surfaces
  static const Color lightBackground = Color(0xFFF7F6FC);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceVariant = Color(0xFFEFEDFB);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightBorder = Color(0xFFE3E0F5);

  // Text
  static const Color textPrimaryDark = Color(0xFFF4F2FF);
  static const Color textSecondaryDark = Color(0xFFA8A2C7);
  static const Color textPrimaryLight = Color(0xFF1A1730);
  static const Color textSecondaryLight = Color(0xFF6B6588);

  // Status
  static const Color success = Color(0xFF22C55E);
  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);

  // Chat bubbles
  static const Color userBubbleDark = Color(0xFF7C5CFF);
  static const Color aiBubbleDark = Color(0xFF1F1A36);
  static const Color userBubbleLight = Color(0xFF7C5CFF);
  static const Color aiBubbleLight = Color(0xFFEFEDFB);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF7C5CFF), Color(0xFF00D4B8)],
  );

  static const LinearGradient darkBackgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF161229), Color(0xFF0E0B1A)],
  );
}
