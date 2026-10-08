import 'package:flutter/foundation.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// Loads the time-zone database and points `tz.local` at the device zone.
/// Returns the IANA identifier in use.
class TimeZoneService {
  bool _databaseLoaded = false;

  Future<String> configureLocal() async {
    if (!_databaseLoaded) {
      tz_data.initializeTimeZones();
      _databaseLoaded = true;
    }
    String? identifier;
    try {
      identifier = (await FlutterTimezone.getLocalTimezone()).identifier;
    } on Object catch (e) {
      debugPrint('Could not read device time zone: $e');
    }
    final location =
        _resolve(identifier) ?? _fromOffset(DateTime.now().timeZoneOffset);
    tz.setLocalLocation(location);
    return location.name;
  }

  tz.Location? _resolve(String? identifier) {
    if (identifier == null) return null;
    try {
      return tz.getLocation(identifier);
    } on Object {
      return null;
    }
  }

  /// Fallback when the platform zone is unknown: a fixed-offset Etc zone.
  /// (Etc/GMT signs are inverted by convention.)
  tz.Location _fromOffset(Duration offset) {
    if (offset.inMinutes % 60 == 0) {
      final h = offset.inHours;
      final name = h == 0 ? 'Etc/UTC' : 'Etc/GMT${h > 0 ? '-' : '+'}${h.abs()}';
      final loc = _resolve(name);
      if (loc != null) return loc;
    }
    return tz.UTC;
  }
}
