// Pure Dart time primitives. Everything that depends on "now" receives a Clock
// so tests never touch the real system time.

abstract class Clock {
  const Clock();

  /// Current instant in the device's local time zone.
  DateTime now();
}

class SystemClock extends Clock {
  const SystemClock();

  @override
  DateTime now() => DateTime.now();
}

class FixedClock extends Clock {
  FixedClock(this.current);

  DateTime current;

  @override
  DateTime now() => current;

  void advance(Duration d) => current = current.add(d);
}

/// A calendar date with no time or zone, e.g. the day a chapter was completed
/// in the reader's own time zone. Stored as `YYYY-MM-DD`.
class LocalDate implements Comparable<LocalDate> {
  const LocalDate(this.year, this.month, this.day);

  factory LocalDate.of(DateTime localDateTime) =>
      LocalDate(localDateTime.year, localDateTime.month, localDateTime.day);

  factory LocalDate.parse(String iso) {
    final parts = iso.split('-');
    if (parts.length != 3) throw FormatException('Invalid LocalDate', iso);
    return LocalDate(
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
    );
  }

  final int year;
  final int month;
  final int day;

  String get iso =>
      '${year.toString().padLeft(4, '0')}-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';

  /// Midnight of this date (local), useful for date arithmetic.
  DateTime get asDateTime => DateTime(year, month, day);

  LocalDate addDays(int days) =>
      LocalDate.of(DateTime(year, month, day + days));

  @override
  int compareTo(LocalDate other) => iso.compareTo(other.iso);

  @override
  bool operator ==(Object other) => other is LocalDate && other.iso == iso;

  @override
  int get hashCode => iso.hashCode;

  @override
  String toString() => iso;
}
