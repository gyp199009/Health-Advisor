import 'package:intl/intl.dart';

class DateTimeUtils {
  static DateTime toLocalTime(DateTime utcTime) {
    // 将UTC时间转换为东八区（UTC+8）时间
    return utcTime.add(const Duration(hours: 8));
  }

  static String formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return 'N/A';
    final localTime = toLocalTime(dateTime);
    return DateFormat('yyyy/MM/dd HH:mm:ss').format(localTime);
  }

  static String formatMessageTime(DateTime time) {
    final localTime = toLocalTime(time);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDate = DateTime(localTime.year, localTime.month, localTime.day);
    
    String timeStr = '${localTime.hour.toString().padLeft(2, '0')}:${localTime.minute.toString().padLeft(2, '0')}';
    
    if (messageDate == today) {
      return '今天 $timeStr';
    } else if (messageDate == yesterday) {
      return '昨天 $timeStr';
    } else {
      return '${localTime.year}-${localTime.month.toString().padLeft(2, '0')}-${localTime.day.toString().padLeft(2, '0')} $timeStr';
    }
  }
}