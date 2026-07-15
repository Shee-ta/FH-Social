import 'package:flutter/material.dart';
import 'package:frontend/UI/formatter.dart';
import 'package:frontend/entity/event.dart';

const List<String> dashboardWeekdayNames = [
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday',
];

const Map<String, int> dashboardWeekdayByCode = {
  'Mo': DateTime.monday,
  'Tu': DateTime.tuesday,
  'We': DateTime.wednesday,
  'Th': DateTime.thursday,
  'Fr': DateTime.friday,
  'Sa': DateTime.saturday,
  'Su': DateTime.sunday,
};

DateTime dashboardEventNextDateTime(Event event) {
  if (event.days.isNotEmpty) {
    return Formatter.iso8601StringToDateTime(
      Formatter.calculateNextIso8601(event.iso8601startDateTime, event.days),
    );
  }
  return Formatter.iso8601StringToDateTime(event.iso8601startDateTime);
}

bool dashboardIsEventPast(Event event) {
  return dashboardEventNextDateTime(event).isBefore(DateTime.now());
}

DateTime dashboardNextOccurrenceForWeekday(Event event, int targetWeekday) {
  final base = Formatter.iso8601StringToDateTime(event.iso8601startDateTime);
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);

  for (int offset = 0; offset <= 7; offset++) {
    final candidate = today.add(Duration(days: offset));
    if (candidate.weekday != targetWeekday) {
      continue;
    }
    final candidateDateTime = DateTime(
      candidate.year,
      candidate.month,
      candidate.day,
      base.hour,
      base.minute,
    );
    if (!candidateDateTime.isBefore(now)) {
      return candidateDateTime;
    }
  }

  return base;
}

Color dashboardColorForEvent(BuildContext context, Event event) {
  if (event.days.isEmpty) {
    return Theme.of(context).colorScheme.surface;
  }

  const palette = [
    Colors.red,
    Colors.orange,
    Colors.yellow,
    Colors.lime,
    Colors.green,
    Colors.cyan,
    Colors.blue,
    Colors.purple,
    Colors.pink,
    Colors.deepPurple
  ];

  final idx = event.id.hashCode.abs() % palette.length;
  return palette[idx].withValues(alpha: 0.26);
}
