import 'package:flutter/material.dart';
import 'package:frontend/UI/formatter.dart';
import 'package:frontend/entity/event.dart';
import 'package:frontend/screens/main_screen/dashboard/dashboard_helpers.dart';

class WeeklySchedule extends StatelessWidget {
  const WeeklySchedule({
    super.key,
    required this.events,
    required this.createdIds,
    required this.memberIds,
    required this.isWide,
    required this.openEventPopup,
  });

  final List<Event> events;
  final Set<String> createdIds;
  final Set<String> memberIds;
  final bool isWide;
  final ValueChanged<Event> openEventPopup;

  @override
  Widget build(BuildContext context) {
    final entriesByWeekday = {
      for (var weekday = DateTime.monday; weekday <= DateTime.sunday; weekday++)
        weekday: <ScheduleEntry>[],
    };

    for (final event in events) {
      final roleLabel = createdIds.contains(event.id)
          ? (memberIds.contains(event.id) ? 'Created + Joined' : 'Created')
          : 'Joined';

      if (event.days.isEmpty) {
        final occurrence = Formatter.iso8601StringToDateTime(event.iso8601startDateTime);
        if (!occurrence.isBefore(DateTime.now())) {
          entriesByWeekday[occurrence.weekday]!.add(
            ScheduleEntry(event: event, occurrence: occurrence, roleLabel: roleLabel),
          );
        }
        continue;
      }

      for (final dayCode in event.days) {
        final weekday = dashboardWeekdayByCode[dayCode];
        if (weekday == null) {
          continue;
        }
        final occurrence = dashboardNextOccurrenceForWeekday(event, weekday);
        entriesByWeekday[weekday]!.add(
          ScheduleEntry(event: event, occurrence: occurrence, roleLabel: roleLabel),
        );
      }
    }

    for (final entries in entriesByWeekday.values) {
      entries.sort((a, b) {
        final cmp = a.occurrence.compareTo(b.occurrence);
        if (cmp != 0) {
          return cmp;
        }
        return a.event.title.toLowerCase().compareTo(b.event.title.toLowerCase());
      });
    }

    if (isWide) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: List.generate(7, (index) {
          final weekday = index + 1;
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: index == 6 ? 0 : 8),
              child: ScheduleDayColumn(
                title: dashboardWeekdayNames[index],
                entries: entriesByWeekday[weekday]!,
                onTap: openEventPopup,
                colorForEvent: (event) => dashboardColorForEvent(context, event),
              ),
            ),
          );
        }),
      );
    }

    return Column(
      children: List.generate(7, (index) {
        final weekday = index + 1;
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: ScheduleDayColumn(
            title: dashboardWeekdayNames[index],
            entries: entriesByWeekday[weekday]!,
            onTap: openEventPopup,
            colorForEvent: (event) => dashboardColorForEvent(context, event),
          ),
        );
      }),
    );
  }
}

class ScheduleEntry {
  const ScheduleEntry({
    required this.event,
    required this.occurrence,
    required this.roleLabel,
  });

  final Event event;
  final DateTime occurrence;
  final String roleLabel;
}

class ScheduleDayColumn extends StatelessWidget {
  const ScheduleDayColumn({
    super.key,
    required this.title,
    required this.entries,
    required this.onTap,
    required this.colorForEvent,
  });

  final String title;
  final List<ScheduleEntry> entries;
  final ValueChanged<Event> onTap;
  final Color Function(Event event) colorForEvent;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            if (entries.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'No events',
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
              )
            else
              Column(
                spacing: 8,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: entries
                    .map(
                      (entry) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: SizedBox(
                          width: double.infinity,
                          child: ScheduleEventTile(
                            entry: entry,
                            cardColor: colorForEvent(entry.event),
                            onTap: () => onTap(entry.event),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
          ],
        ),
      ),
    );
  }
}

class ScheduleEventTile extends StatelessWidget {
  const ScheduleEventTile({
    super.key,
    required this.entry,
    required this.cardColor,
    required this.onTap,
  });

  final ScheduleEntry entry;
  final Color cardColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final startTime = Formatter.deserialiseDateTime(
      entry.occurrence.toIso8601String(),
      rawDates: true,
    ).time;
    final endTime = entry.event.iso8601endDateTime.isEmpty
        ? '--'
        : Formatter.deserialiseDateTime(
            entry.event.iso8601endDateTime,
            rawDates: true,
          ).time;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black26.withValues(alpha: 0.05),
              spreadRadius: 2,
              blurRadius: 1,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: SizedBox(
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.event.title,
                  style: Theme.of(context).textTheme.titleMedium,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '$startTime - $endTime',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 2),
                Text(
                  entry.event.location,
                  style: Theme.of(context).textTheme.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  entry.roleLabel,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
