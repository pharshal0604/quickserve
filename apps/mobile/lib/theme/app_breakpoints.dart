/// Width breakpoints for responsive layouts.
///
/// Values are logical pixels, matching Flutter's own Material 3 window
/// size class convention.
abstract final class AppBreakpoints {
  /// Below this width: phone portrait. Single-column layouts.
  static const double compact = 600;

  /// Below this width and at/above [compact]: tablet / large phone
  /// landscape. Two-column layouts where it helps.
  static const double medium = 900;

  /// At/above this width: desktop / web. Navigation rail plus multi-pane.
  static const double expanded = 1200;
}
