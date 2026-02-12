import 'package:intl/intl.dart';

class DateUtils {
  static final DateFormat timeFormat = DateFormat('HH:mm:ss');
  static final DateFormat dateFormat = DateFormat('yyyy-MM-dd');
  static final DateFormat dateTimeFormat = DateFormat('yyyy-MM-dd HH:mm:ss');

  /// Get start of today
  static DateTime get startOfToday {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  /// Get end of today
  static DateTime get endOfToday {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, 23, 59, 59);
  }

  /// Get time ago string (e.g., "2 min ago")
  static String getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return '${difference.inSeconds}s ago';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  /// Format time for chart
  static String formatChartTime(DateTime dateTime) {
    return timeFormat.format(dateTime);
  }

  /// Get start time for chart window
  static DateTime getChartStartTime(int windowMinutes) {
    return DateTime.now().subtract(Duration(minutes: windowMinutes));
  }
}
