import 'package:flutter/material.dart';

/// Shared Soul — celestial companionship color tokens.
abstract final class SoulColors {
  // Midnight celestial palette
  static const Color nightDeep = Color(0xFF17263B);
  static const Color night = Color(0xFF243650);
  static const Color nightMid = Color(0xFF293A52);
  static const Color elevated = Color(0xFF2E425C);

  static const Color celestialGold = Color(0xFFE8C779);
  static const Color warmIvory = Color(0xFFF5F0E8);
  static const Color mistyLavender = Color(0xFFB8BED4);
  static const Color mutedBlue = Color(0xFF8F9CB9);

  // Companion / accent aliases (painter + legacy)
  static const Color cream = warmIvory;
  static const Color creamSoft = Color(0xFFEDE6DA);
  static const Color fur = Color(0xFFFFF0E0);
  static const Color furShadow = Color(0xFFE8D0B8);

  static const Color starBlue = mutedBlue;
  static const Color starBlueDeep = Color(0xFF6A7A9A);
  static const Color starYellow = celestialGold;
  static const Color blush = Color(0xFFFFC0C8);

  static const Color roseGold = celestialGold;
  static const Color ember = Color(0xFFE8D4A8);
  static const Color emberCore = Color(0xFFFFF0D0);

  static const Color textPrimary = warmIvory;
  static const Color textMuted = mistyLavender;
  static const Color textSoft = mutedBlue;

  static const Color chipIdle = Color(0x33F5F0E8);
  static const Color chipActive = Color(0x55E8C779);

  static const Color cardSurface = Color(0xCC243650);
  static const Color cardBorder = Color(0x33E8C779);
}
