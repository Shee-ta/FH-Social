import 'package:flutter/material.dart';
import 'package:frontend/UI/formatter.dart';
import 'package:frontend/entity/event.dart';

class DashboardEventCard extends StatelessWidget {
  const DashboardEventCard({
    super.key,
    required this.event,
    required this.onTap,
  });

  final Event event;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final nextOccurrence = event.days.isNotEmpty
        ? Formatter.calculateNextIso8601(event.iso8601startDateTime, event.days)
        : event.iso8601startDateTime;
    final dateInfo = Formatter.deserialiseDateTime(nextOccurrence, rawDates: true);
    final endsAt = event.iso8601endDateTime.isNotEmpty
        ? Formatter.deserialiseDateTime(event.iso8601endDateTime, rawDates: true).time
        : "--";
    final isRepeating = event.days.isNotEmpty;
    final creatorName = event.creator.displayname.isNotEmpty
        ? event.creator.displayname
        : event.creator.username;
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Card(
        color: colorScheme.surface,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          child: Column(
            spacing: 12,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                event.title,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              Row(
                children: [
                  Icon(Icons.calendar_month),
                  const SizedBox(width: 4),
                  Text(
                    dateInfo.date,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
              Row(
                children: [
                  Icon(Icons.access_time),
                  const SizedBox(width: 4),
                  Text(
                    '${dateInfo.time} - $endsAt',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
              Row(
                children: [
                  Icon(Icons.account_circle_outlined),
                  const SizedBox(width: 4),
                  Text(
                    creatorName,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (event.location.isNotEmpty)
                    Chip(
                      backgroundColor: colorScheme.primaryContainer,
                      label: Text(
                        event.location,
                        style: TextStyle(color: colorScheme.onPrimaryContainer),
                      ),
                      visualDensity: VisualDensity.compact,
                    ),
                  Chip(
                    backgroundColor: colorScheme.primaryContainer,
                    label: Text(
                      '${event.members.length} member${event.members.length == 1 ? '' : 's'}',
                      style: TextStyle(color: colorScheme.onPrimaryContainer),
                    ),
                    visualDensity: VisualDensity.compact,
                  ),
                  if (isRepeating)
                    Chip(
                      backgroundColor: colorScheme.primaryContainer,
                      label: Text(
                        'Repeats ${Formatter.deserialiseDays(event.days).join(', ')}',
                        style: TextStyle(color: colorScheme.onPrimaryContainer),
                      ),
                      visualDensity: VisualDensity.compact,
                    ),
                ],
              ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final tag in event.tags)
                  Chip(
                    backgroundColor: colorScheme.tertiaryContainer,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    label: Text(
                      tag,
                      style: TextStyle(color: colorScheme.onTertiaryContainer),
                    ),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
