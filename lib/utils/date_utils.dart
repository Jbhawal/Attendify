import 'package:intl/intl.dart';

class DateUtilsX {
  static final DateFormat fullDate = DateFormat('EEEE, d MMMM');
  static final DateFormat shortDate = DateFormat('dd MMM');
  static final DateFormat timeFormat = DateFormat('hh:mm a');

  static String greetingFor(DateTime dateTime, {String? name}) {
    final hour = dateTime.hour;
    String greeting;
    if (hour < 12) {
      greeting = 'Good Morning';
    } else if (hour < 17) {
      greeting = 'Good Afternoon';
    } else {
      greeting = 'Good Evening';
    }
    return name == null || name.isEmpty ? greeting : '$greeting, $name!';
  }

  static DateTime startOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  static DateTime endOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day, 23, 59, 59);
  }
}
