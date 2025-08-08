// File: utils/date_utils.dart
class DateUtilites {
  static String formatDueDate(DateTime date) {
    final now = DateTime.now();
    final difference = date.difference(now);

    if (difference.isNegative) {
      final daysPast = now.difference(date).inDays;
      if (daysPast == 0) return 'Overdue today';
      return 'Overdue ${daysPast}d';
    } else if (difference.inDays == 0) {
      final hours = difference.inHours;
      if (hours <= 0) return 'Due now';
      return 'Due ${hours}h';
    } else if (difference.inDays == 1) {
      return 'Due tomorrow';
    } else {
      return 'Due ${difference.inDays}d';
    }
  }

  static String formatDetailedDeadline(DateTime deadline) {
    final now = DateTime.now();
    final difference = deadline.difference(now);

    if (difference.isNegative) {
      final daysPast = now.difference(deadline).inDays;
      return 'Overdue by $daysPast day${daysPast == 1 ? '' : 's'}';
    } else if (difference.inDays == 0) {
      return 'Due today at ${_formatTime(deadline)}';
    } else if (difference.inDays == 1) {
      return 'Due tomorrow at ${_formatTime(deadline)}';
    } else {
      return 'Due in ${difference.inDays} days (${_formatDate(deadline)})';
    }
  }

  static String _formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  static String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}