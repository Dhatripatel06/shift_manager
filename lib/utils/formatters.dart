import 'package:intl/intl.dart';

/// Utility class for formatting dates, times, and currency values
class Formatters {
  Formatters._();

  static final DateFormat _dateFormat = DateFormat('dd MMM yyyy');
  static final DateFormat _dayFormat = DateFormat('EEEE');
  static final DateFormat _shortDateFormat = DateFormat('dd/MM/yy');
  static final DateFormat _monthYearFormat = DateFormat('MMMM yyyy');
  static final DateFormat _timeFormat = DateFormat('HH:mm');
  static final DateFormat _time12Format = DateFormat('hh:mm a');
  static final DateFormat _clockFormat = DateFormat('hh:mm:ss a');
  static final DateFormat _isoDateFormat = DateFormat('yyyy-MM-dd');

  /// Format date as "15 May 2026"
  static String formatDate(DateTime date) => _dateFormat.format(date);

  /// Format day name
  static String formatDay(DateTime date) => _dayFormat.format(date);

  /// Format as short date "15/05/26"
  static String formatShortDate(DateTime date) => _shortDateFormat.format(date);

  /// Format as "May 2026"
  static String formatMonthYear(DateTime date) => _monthYearFormat.format(date);

  /// Format time as "14:30"
  static String formatTime24(DateTime time) => _timeFormat.format(time);

  /// Format time as "02:30 PM"
  static String formatTime12(DateTime time) => _time12Format.format(time);

  /// Format clock time with seconds
  static String formatClock(DateTime time) => _clockFormat.format(time);

  /// Format ISO date
  static String formatIsoDate(DateTime date) => _isoDateFormat.format(date);

  /// Format currency as "£1,234.56"
  static String formatCurrency(double amount) {
    final formatter = NumberFormat.currency(symbol: '£', decimalDigits: 2);
    return formatter.format(amount);
  }

  /// Format hours as "8.5h"
  static String formatHours(double hours) {
    return '${hours.toStringAsFixed(1)}h';
  }

  /// Format hours as "8h 30m"
  static String formatHoursMinutes(double hours) {
    final h = hours.floor();
    final m = ((hours - h) * 60).round();
    if (m == 0) return '${h}h';
    if (h == 0) return '${m}m';
    return '${h}h ${m}m';
  }

  /// Format pay rate as "£12.00/hr"
  static String formatPayRate(double rate) {
    return '£${rate.toStringAsFixed(2)}/hr';
  }

  /// Get greeting based on time of day
  static String getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }
}
