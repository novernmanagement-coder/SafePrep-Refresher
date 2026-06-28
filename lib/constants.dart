import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────
// COLORS
// ─────────────────────────────────────────────────────────────
class AppColors {
  static const Color background = Color(0xFF1A3A5C);
  static const Color gold = Color(0xFFE8D5A0);
  static const Color goldDark = Color(0xFFC8A84B);
  static const Color goldText = Color(0xFF1A3A5C);
  static const Color cardBackground = Color(0x0FFFFFFF);
  static const Color cardBorder = Color(0x40E8D5A0);
  static const Color bodyText = Color(0xFFE8D5A0);
  static const Color subtleText = Color(0x73FFFFFF);
  static const Color footerText = Color(0x33FFFFFF);
  static const Color marqueeBackground = Color(0xFFF5F0E8);
  static const Color marqueeBorder = Color(0xFFC8B89A);
  static const Color marqueeText = Color(0xFF4A3728);
  static const Color funnelBackground = Color(0x0AFFFFFF);
  static const Color funnelBorder = Color(0x1AFFFFFF);
}

// ─────────────────────────────────────────────────────────────
// FONTS
// ─────────────────────────────────────────────────────────────
class AppFonts {
  static const double header = 20.0;
  static const double subheader = 16.0;
  static const double body = 13.0;
  static const double caption = 11.0;
  static const double footer = 10.0;
  static const double button = 15.0;
  static const double question = 14.0;
}

// ─────────────────────────────────────────────────────────────
// SIZES
// ─────────────────────────────────────────────────────────────
class AppSizes {
  static const EdgeInsets pageMargin = EdgeInsets.symmetric(
    horizontal: 16,
    vertical: 8,
  );
  static const EdgeInsets cardPadding = EdgeInsets.all(14);
  static const double cardCornerRadius = 12.0;
  static const double buttonCornerRadius = 10.0;
  static const double primaryButtonHeight = 50.0;
  static const double footerSpacing = 2.0;
}

// ─────────────────────────────────────────────────────────────
// STRINGS
// ─────────────────────────────────────────────────────────────
class AppStrings {
  static const String footerLine1 =
      'SafePrep™ is not affiliated with ServSafe® or the National Restaurant Association.';
  static const String footerLine2 =
      'ServSafe® is a registered trademark of the National Restaurant Association Educational Foundation.';
  static const String footerLine3 =
      'Our team brings over 20 years of ServSafe® instruction and proctoring experience.';

  static const String safePrepManagerUrl =
      'https://apps.apple.com/us/app/safeprep/id6766696371';
}
