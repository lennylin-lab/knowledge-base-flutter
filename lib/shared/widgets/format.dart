import 'package:intl/intl.dart';

/// Formats an ISO8601 timestamp (as carried verbatim by the DTOs) for
/// display in the device's local time zone — display-only formatting, the
/// DTO itself is never mutated (type-safety spec).
///
/// The numeric pattern is locale-independent, so no
/// `initializeDateFormatting` bootstrapping is required. Unparseable input
/// is shown verbatim rather than crashing the view.
String formatIsoTimestamp(String iso) {
  final dateTime = DateTime.tryParse(iso);
  if (dateTime == null) return iso;
  return DateFormat('y-MM-dd HH:mm').format(dateTime.toLocal());
}
