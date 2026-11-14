/// America/New_York calendar arithmetic without a timezone database.
///
/// The server owns every ET decision (quota resets, seasons, streaks); the
/// client only needs today's ET date for the age screen. US DST: from the
/// second Sunday of March 02:00 EST to the first Sunday of November 02:00
/// EDT.
abstract final class EasternTime {
  /// Calendar date (at midnight, UTC-flagged fields) in ET for [instant].
  static DateTime dateOf(DateTime instant) {
    final DateTime utc = instant.toUtc();
    final DateTime local = utc.add(offsetAt(utc));
    return DateTime.utc(local.year, local.month, local.day);
  }

  /// UTC offset of New York at [instant]: −4 h in DST, −5 h otherwise.
  static Duration offsetAt(DateTime instant) {
    final DateTime utc = instant.toUtc();
    final DateTime dstStart = DateTime.utc(
      utc.year,
      3,
      _nthSunday(utc.year, 3, 2),
      7,
    );
    final DateTime dstEnd = DateTime.utc(
      utc.year,
      11,
      _nthSunday(utc.year, 11, 1),
      6,
    );
    final bool isDst = !utc.isBefore(dstStart) && utc.isBefore(dstEnd);
    return Duration(hours: isDst ? -4 : -5);
  }

  static int _nthSunday(int year, int month, int n) {
    final int firstWeekday = DateTime.utc(year, month).weekday;
    final int firstSunday = 1 + (DateTime.sunday - firstWeekday) % 7;
    return firstSunday + (n - 1) * 7;
  }
}
