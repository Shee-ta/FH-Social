import 'package:flutter/material.dart';

class Formatter {

  static const Map<String, int> _weekdayByCode = {
    'Mo': DateTime.monday,
    'Tu': DateTime.tuesday,
    'We': DateTime.wednesday,
    'Th': DateTime.thursday,
    'Fr': DateTime.friday,
    'Sa': DateTime.saturday,
    'Su': DateTime.sunday,
  };

  static String formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(2)} KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
    } else {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
    }
  }

  static DateTime stringToDateTime(String date) {
    final parts = date.split('.');
    if (parts.length != 3) {
      return DateTime.now().toLocal();
    }

    final day = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final year = int.tryParse(parts[2]);
    if (day == null || month == null || year == null) {
      return DateTime.now().toLocal();
    }

    return DateTime(year, month, day);
  }

  static TimeOfDay iso8601StringToTimeOfDay(String iso8601String) {
    final dateTime = DateTime.tryParse(iso8601String)?.toLocal() ?? DateTime.now().toLocal();
    return TimeOfDay(hour: dateTime.hour, minute: dateTime.minute);
  }

  static DateTime iso8601StringToDateTime(String iso8601String) {
    return DateTime.tryParse(iso8601String)?.toLocal() ?? DateTime.now().toLocal();
  }

  static bool isIso8601InPast(String iso8601dateTime) {
    final parsedEvent = DateTime.tryParse(iso8601dateTime);
    if (parsedEvent == null) {
      return false;
    }
    return parsedEvent.toLocal().isBefore(DateTime.now().toLocal());
  }

  static String calculateNextIso8601(String iso8601dateTime, List<String> days) {

    final parsedEvent = DateTime.tryParse(iso8601dateTime);
    if (parsedEvent == null) {
      return iso8601dateTime;
    }

    final eventDays = days
        .map((day) => _weekdayByCode[day])
        .whereType<int>()
        .toSet();
    if (eventDays.isEmpty) {
      return iso8601dateTime;
    }

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final eventDateTime = parsedEvent.toLocal();

      for (int i = 0; i <= 7; i++) {
        final candidateDate = today.add(Duration(days: i));
        if (!eventDays.contains(candidateDate.weekday)) {
          continue;
        }

        final candidateDateTime = DateTime(
          candidateDate.year,
          candidateDate.month,
          candidateDate.day,
          eventDateTime.hour,
          eventDateTime.minute,
          eventDateTime.second,
          eventDateTime.millisecond,
          eventDateTime.microsecond,
        );

        if (!candidateDateTime.isBefore(now)) {
          return candidateDateTime.toIso8601String();
        }
      }

      return iso8601dateTime;
  }

  static String serialiseDateTime(DateTime date, TimeOfDay time) {
    final localDateTime = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
    return localDateTime.toUtc().toIso8601String();
  }

  static ({String date, String time}) deserialiseDateTime(
    String iso8601String, 
    {bool rawDates = false}
  ) {
    if (iso8601String.isEmpty) {
      return (date: 'Unknown date', time: '');
    }
    final parsed = DateTime.tryParse(iso8601String)?.toLocal();
    if (parsed == null) {
      return (date: 'Unknown date', time: '');
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final parsedDateOnly = DateTime(parsed.year, parsed.month, parsed.day);

    final hours = parsed.hour.toString().padLeft(2, '0');
    final minutes = parsed.minute.toString().padLeft(2, '0');
    final formattedTime = '$hours:$minutes';

    if (parsedDateOnly == today && !rawDates) {
      return (date: 'Today', time: 'at $formattedTime');
    }

    if (parsedDateOnly == yesterday && !rawDates) {
      return (date: 'Yesterday', time: 'at $formattedTime');
    }

    final formattedDate = '${parsed.day}.${parsed.month}.${parsed.year}';
    return (date: formattedDate, time: formattedTime);
  }

  static List<String> deserialiseDays(List<String> days) {
    return days.map((day) {
      switch (day) {
        case 'Mo':
          return 'Monday';
        case 'Tu':
          return 'Tuesday';
        case 'We':
          return 'Wednesday';
        case 'Th':
          return 'Thursday';
        case 'Fr':
          return 'Friday';
        case 'Sa':
          return 'Saturday';
        case 'Su':
          return 'Sunday';
        default:
          return day;
      }
    }).toList();
  }
}
