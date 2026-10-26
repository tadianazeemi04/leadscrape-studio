enum LogType {
  info,
  search,
  visit,
  emailFound,
  facebook,
  warning,
  error,
  success,
}

class LogEntry {
  final DateTime timestamp;
  final String message;
  final LogType type;

  LogEntry({
    required this.message,
    required this.type,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  String get timeFormatted {
    final h = timestamp.hour.toString().padLeft(2, '0');
    final m = timestamp.minute.toString().padLeft(2, '0');
    final s = timestamp.second.toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  String get prefix {
    switch (type) {
      case LogType.search:
        return '[SEARCH]';
      case LogType.visit:
        return '[VISIT]';
      case LogType.emailFound:
        return '[EMAIL FOUND]';
      case LogType.facebook:
        return '[FACEBOOK]';
      case LogType.warning:
        return '[WARN]';
      case LogType.error:
        return '[ERROR]';
      case LogType.success:
        return '[SUCCESS]';
      case LogType.info:
        return '[INFO]';
    }
  }
}
