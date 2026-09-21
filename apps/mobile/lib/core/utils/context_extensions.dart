import 'package:flutter/material.dart';

import 'package:quickserve_mobile/config/theme/app_breakpoints.dart';

/// Convenience accessors for responsive layout decisions.
///
/// Uses [MediaQuery.sizeOf] and [MediaQuery.platformBrightnessOf] rather
/// than [MediaQuery.of], so widgets rebuild only when the queried value
/// actually changes — not on every MediaQuery notification (keyboard,
/// insets, orientation, etc.).
extension ResponsiveContext on BuildContext {
  /// The current screen size.
  Size get screenSize => MediaQuery.sizeOf(this);

  /// The current screen width in logical pixels.
  double get screenWidth => MediaQuery.sizeOf(this).width;

  /// The current screen height in logical pixels.
  double get screenHeight => MediaQuery.sizeOf(this).height;

  /// True when the viewport is narrower than [AppBreakpoints.compact].
  bool get isCompact => screenWidth < AppBreakpoints.compact;

  /// True when the viewport is at or above [AppBreakpoints.compact] and
  /// below [AppBreakpoints.expanded].
  bool get isMedium =>
      screenWidth >= AppBreakpoints.compact &&
      screenWidth < AppBreakpoints.expanded;

  /// True when the viewport is at or above [AppBreakpoints.expanded].
  bool get isExpanded => screenWidth >= AppBreakpoints.expanded;

  /// The current platform brightness.
  bool get isDark => MediaQuery.platformBrightnessOf(this) == Brightness.dark;

  /// The current text scaler, honoring system accessibility settings.
  TextScaler get textScaler => MediaQuery.textScalerOf(this);
}
