/// English display formatting. Instants are shown in the device's local
/// time; ET is only a server concern.
abstract final class DisplayFormatters {
  static const List<String> _months = <String>[
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  static const List<String> _weekdays = <String>[
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];

  /// `1:05`; negative durations show `0:00`.
  static String clock(Duration value) {
    final int seconds = value.isNegative
        ? 0
        : (value.inMilliseconds / 1000).ceil();
    return '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}';
  }

  /// `06:42:18`; negative durations show `00:00:00`.
  static String hms(Duration value) {
    final int seconds = value.isNegative
        ? 0
        : (value.inMilliseconds / 1000).ceil();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(seconds ~/ 3600)}:${two(seconds % 3600 ~/ 60)}:'
        '${two(seconds % 60)}';
  }

  /// `5h 12m`, `12m`, `45s`.
  static String compactDuration(Duration value) {
    if (value.isNegative || value == Duration.zero) return '0s';
    if (value.inHours >= 1) {
      final int minutes = value.inMinutes % 60;
      return minutes == 0
          ? '${value.inHours}h'
          : '${value.inHours}h ${minutes}m';
    }
    if (value.inMinutes >= 1) return '${value.inMinutes}m';
    return '${value.inSeconds}s';
  }

  /// `12:00 AM`.
  static String time(DateTime value) {
    final DateTime local = value.toLocal();
    final int hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final String minute = local.minute.toString().padLeft(2, '0');
    return '$hour:$minute ${local.hour < 12 ? 'AM' : 'PM'}';
  }

  /// `Nov 15, 2026`.
  static String date(DateTime value) {
    final DateTime local = value.toLocal();
    return '${_months[local.month - 1]} ${local.day}, ${local.year}';
  }

  /// `Sat, Nov 15`.
  static String weekdayDate(DateTime value) {
    final DateTime local = value.toLocal();
    return '${_weekdays[local.weekday - 1]}, ${_months[local.month - 1]} '
        '${local.day}';
  }

  /// `Dec 1` — the ET calendar day of an instant at ET midnight (a season
  /// boundary). Midnight ET is 04:00 or 05:00 UTC, so 4 hours back lands on
  /// that day in both standard and daylight time, wherever the device is.
  static String etBoundaryDay(DateTime instant) {
    final DateTime et = instant.toUtc().subtract(const Duration(hours: 4));
    return '${_months[et.month - 1]} ${et.day}';
  }

  /// `Today, 14:12`, `Yesterday`, `Wed, 12 Nov` — when a match finished.
  static String matchDate(DateTime value, DateTime now) {
    final DateTime local = value.toLocal();
    final DateTime today = DateTime(now.year, now.month, now.day);
    final DateTime day = DateTime(local.year, local.month, local.day);
    final int days = today.difference(day).inDays;
    if (days == 0) {
      String two(int n) => n.toString().padLeft(2, '0');
      return 'Today, ${two(local.hour)}:${two(local.minute)}';
    }
    if (days == 1) return 'Yesterday';
    return '${_weekdays[local.weekday - 1]}, ${local.day} '
        '${_months[local.month - 1]}';
  }

  /// `2,048`; negative values keep a true minus sign (`−1,032`).
  static String thousands(int value) {
    final String digits = value.abs().toString();
    final StringBuffer buffer = StringBuffer(value < 0 ? '−' : '');
    for (int i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(',');
      buffer.write(digits[i]);
    }
    return buffer.toString();
  }

  /// `Nov 2026`.
  static String monthYear(DateTime value) {
    final DateTime local = value.toLocal();
    return '${_months[local.month - 1]} ${local.year}';
  }

  /// `Nov 15, 12:00 AM`.
  static String dateTime(DateTime value) {
    final DateTime local = value.toLocal();
    return '${_months[local.month - 1]} ${local.day}, ${time(local)}';
  }

  /// `Just now`, `2h ago`, `Yesterday`, `Mon`, `Nov 3`.
  static String relative(DateTime value, DateTime now) {
    final DateTime local = value.toLocal();
    final Duration ago = now.difference(local);
    if (ago.inMinutes < 1) return 'Just now';
    if (ago.inHours < 1) return '${ago.inMinutes}m ago';
    final DateTime today = DateTime(now.year, now.month, now.day);
    final DateTime day = DateTime(local.year, local.month, local.day);
    final int days = today.difference(day).inDays;
    if (days == 0) return '${ago.inHours}h ago';
    if (days == 1) return 'Yesterday';
    if (days < 7) return _weekdays[local.weekday - 1];
    return '${_months[local.month - 1]} ${local.day}';
  }

  /// When an ET reset instant happens, in local terms:
  /// `12:00 AM (in 5h 12m)`.
  static String resetsAt(DateTime value, DateTime now) =>
      '${time(value)} (in ${compactDuration(value.toLocal().difference(now))})';

  /// `62.5%`; `—` when there is no data (never `0%`).
  static String percent(double? value) {
    if (value == null) return '—';
    final String text = value == value.roundToDouble()
        ? value.toStringAsFixed(0)
        : value.toStringAsFixed(1);
    return '$text%';
  }

  /// `12.4 s`; `—` without data.
  static String seconds(Duration? value) {
    if (value == null) return '—';
    return '${(value.inMilliseconds / 1000).toStringAsFixed(1)} s';
  }

  /// `$7.99` for USD cents.
  static String money(int cents, String currency) {
    final String amount = (cents / 100).toStringAsFixed(2);
    return currency == 'USD' ? '\$$amount' : '$amount $currency';
  }

  /// `4,523` — scores and points with thousands separators.
  static String grouped(int value) {
    final String digits = value.abs().toString();
    final StringBuffer out = StringBuffer(value < 0 ? '−' : '');
    for (int i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) out.write(',');
      out.write(digits[i]);
    }
    return out.toString();
  }

  /// `+1,116` for earned points (never negative).
  static String points(int value) => '+${grouped(value)}';

  /// `+16`, `−14` (true minus), `0`.
  static String signed(int value) {
    if (value > 0) return '+$value';
    if (value < 0) return '−${value.abs()}';
    return '0';
  }
}
