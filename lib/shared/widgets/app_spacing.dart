import 'package:flutter/material.dart';

/// Design tokens for consistent spacing, radius, and sizing across the app.
class AppSpacing {
  AppSpacing._();

  // Spacing / Margins / Paddings
  static const double xxs = 2.0;
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 20.0;
  static const double xxl = 24.0;
  static const double xxxl = 32.0;
  static const double section = 28.0;

  // Border Radii
  static const double radiusXs = 6.0;
  static const double radiusSm = 10.0;
  static const double radiusMd = 14.0;
  static const double radiusLg = 18.0;
  static const double radiusXl = 24.0;
  static const double radiusFull = 999.0;

  // Max widths for responsive layouts
  static const double maxContentWidth = 1080.0;
  static const double maxAuthWidth = 460.0;
  static const double maxReadingWidth = 760.0;

  // Standard touch target minimum
  static const double minTouchTarget = 48.0;

  // EdgeInsets shortcuts
  static const EdgeInsets pagePaddingMobile = EdgeInsets.fromLTRB(20, 12, 20, 32);
  static const EdgeInsets pagePaddingTablet = EdgeInsets.fromLTRB(32, 20, 32, 40);
  static const EdgeInsets cardPadding = EdgeInsets.all(18);
}
