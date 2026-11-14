/// Paths of the SVG icons exported from the Paper design (`assets/icons/`).
///
/// Each file keeps the color it has in Paper; [AppSvgIcon] can tint the
/// monochrome ones.
abstract final class AppIcons {
  static const String _dir = 'assets/icons';

  /// The SkillBattles mark on a blue tile (28 x 28).
  static const String logoMark = '$_dir/logo_mark.svg';

  /// The SkillBattles mark on a white tile, for blue surfaces (28 x 28).
  static const String logoMarkInverse = '$_dir/logo_mark_inverse.svg';

  /// White check inside the selected subject radio (12 x 12).
  static const String check = '$_dir/check.svg';

  /// Green check of the "Answered" tag (10 x 10).
  static const String checkSmall = '$_dir/check_small.svg';

  /// White arrow of the ranked match button (28 x 28).
  static const String arrowRight = '$_dir/arrow_right.svg';

  /// Ink arrow between the old and the new rating (20 x 12).
  static const String arrowLong = '$_dir/arrow_long.svg';

  /// Copy icon of the private duel code button (16 x 16).
  static const String copy = '$_dir/copy.svg';

  /// Amber flame of the win streak (12 x 14).
  static const String flame = '$_dir/flame.svg';

  /// Muted chevron of a dropdown field (14 x 14).
  static const String chevronDown = '$_dir/chevron_down.svg';

  /// Muted chevron of a "Back to …" link (16 x 16).
  static const String chevronLeft = '$_dir/chevron_left.svg';

  /// White arrow of a "Continue" button (16 x 16).
  static const String arrowSmall = '$_dir/arrow_small.svg';

  /// Amber arrow of the "See plans" link (14 x 14).
  static const String arrowLink = '$_dir/arrow_link.svg';

  /// Ink arrow of a link that leaves the app (12 x 12).
  static const String external = '$_dir/external.svg';

  /// Amber star of the Pro pill (12 x 12).
  static const String star = '$_dir/star.svg';

  /// Ink exclamation in a circle (26 x 26).
  static const String alert = '$_dir/alert.svg';

  /// White check on a green circle of a success callout (20 x 20).
  static const String statusSuccess = '$_dir/status_success.svg';

  /// White exclamation on a red circle of an error callout (20 x 20).
  static const String statusError = '$_dir/status_error.svg';

  /// Amber stopwatch of the overtime callout (22 x 22).
  static const String timer = '$_dir/timer.svg';

  /// Amber padlock of Pro-only content; tint for the muted variant (16 x 16).
  static const String lock = '$_dir/lock.svg';

  /// Muted cross that closes a modal (20 x 20).
  static const String close = '$_dir/close.svg';

  /// Muted circled "i" before a footnote (18 x 18).
  static const String info = '$_dir/info.svg';

  /// Muted clock of the "Taking longer than usual" callout (22 x 22).
  static const String clock = '$_dir/clock.svg';

  static const List<String> all = <String>[
    logoMark,
    logoMarkInverse,
    check,
    checkSmall,
    arrowRight,
    arrowLong,
    copy,
    flame,
    chevronDown,
    chevronLeft,
    arrowSmall,
    arrowLink,
    external,
    star,
    alert,
    statusSuccess,
    statusError,
    timer,
    lock,
    close,
    info,
    clock,
  ];
}
