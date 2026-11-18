/// Product features switched at build time.
abstract final class FeatureFlags {
  /// Payments and everything that mentions them: the Pro page and the
  /// billing return page, "Go Pro" and "See Pro plans" calls, the
  /// subscription settings, PRO badges, and Free/Pro wording.
  ///
  /// Off until billing launches. The server still applies the Free limits;
  /// with the flag off the app explains them without offering Pro. Turn it
  /// on with `--dart-define=BILLING_ENABLED=true`.
  static const bool billing = bool.fromEnvironment('BILLING_ENABLED');
}
