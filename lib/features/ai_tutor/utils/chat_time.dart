


/// Time formatting for the AI Tutor (no intl package needed).
class ChatTime {
  ChatTime._();

  static const List<String> _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  static const List<String> _weekdays = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday',
    'Friday', 'Saturday', 'Sunday',
  ];

  /// "9:41 AM"
  static String clock(DateTime time) {
    final hour = time.hour % 12 == 0 ? 12 : time.hour % 12;
    final minute = time.minute.toString().padLeft(2, '0');
    final suffix = time.hour >= 12 ? 'PM' : 'AM';

    return '$hour:$minute $suffix';
  }

  static bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  /// Separator label inside a chat: "Today", "Yesterday", "Monday, Mar 3".
  static String dayLabel(DateTime time, {DateTime? now}) {
    final today = now ?? DateTime.now();

    if (isSameDay(time, today)) {
      return 'Today';
    }

    if (isSameDay(time, today.subtract(const Duration(days: 1)))) {
      return 'Yesterday';
    }

    final label =
        '${_weekdays[time.weekday - 1]}, ${_months[time.month - 1]} ${time.day}';

    return time.year == today.year ? label : '$label, ${time.year}';
  }

  /// Short label for lists: "Just now", "5 min ago", "9:41 AM",
  /// "Yesterday", "Monday", "Mar 3".
  static String relative(DateTime time, {DateTime? now}) {
    final current = now ?? DateTime.now();
    final difference = current.difference(time);

    if (difference.inMinutes < 1) {
      return 'Just now';
    }

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} min ago';
    }

    if (isSameDay(time, current)) {
      return clock(time);
    }

    if (isSameDay(time, current.subtract(const Duration(days: 1)))) {
      return 'Yesterday';
    }

    if (difference.inDays < 7) {
      return _weekdays[time.weekday - 1];
    }

    return '${_months[time.month - 1]} ${time.day}';
  }
}






