import 'package:flutter/material.dart';

import 'soul_colors.dart';

/// Restrained iOS-native typography helpers (SF Pro via platform defaults).
abstract final class SoulTypography {
  static TextStyle get appTitle => const TextStyle(
    color: SoulColors.warmIvory,
    fontSize: 13,
    fontWeight: FontWeight.w600,
    letterSpacing: 4.2,
    height: 1.2,
  );

  static TextStyle get appSubtitle => TextStyle(
    color: SoulColors.mistyLavender.withValues(alpha: 0.75),
    fontSize: 11,
    fontWeight: FontWeight.w400,
    letterSpacing: 2.4,
    height: 1.3,
  );

  static TextStyle get evolutionTitle => const TextStyle(
    color: SoulColors.warmIvory,
    fontSize: 28,
    fontWeight: FontWeight.w600,
    letterSpacing: 3.5,
    height: 1.15,
  );

  static TextStyle get evolutionSubtitle => TextStyle(
    color: SoulColors.mistyLavender.withValues(alpha: 0.9),
    fontSize: 15,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.2,
    height: 1.35,
  );

  static TextStyle get sectionLabel => TextStyle(
    color: SoulColors.mistyLavender.withValues(alpha: 0.7),
    fontSize: 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.8,
  );

  static TextStyle get cardTitle => const TextStyle(
    color: SoulColors.warmIvory,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
  );

  static TextStyle get cardBody => TextStyle(
    color: SoulColors.mistyLavender.withValues(alpha: 0.85),
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.35,
  );

  static TextStyle get cta => const TextStyle(
    color: SoulColors.nightDeep,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.2,
  );
}
