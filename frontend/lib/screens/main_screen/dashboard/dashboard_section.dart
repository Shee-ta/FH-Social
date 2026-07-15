import 'package:flutter/material.dart';
import 'package:frontend/entity/event.dart';
import 'package:frontend/screens/main_screen/event_card.dart';

class DashboardSection extends StatelessWidget {
  const DashboardSection({
    super.key,
    required this.title,
    required this.subtitle,
    required this.events,
    required this.emptyMessage,
    required this.onEventTap,
  });

  final String title;
  final String subtitle;
  final List<Event> events;
  final String emptyMessage;
  final void Function(BuildContext context, Event event) onEventTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(width: 8),
              if (events.isNotEmpty)
                CircleAvatar(
                  radius: 12,
                  backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                  child: Text(
                    events.length.toString(),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                  ),
                ),
            ]),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            if (events.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Text(
                  emptyMessage,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              )
            else
              Column(
                children: events
                    .map(
                      (event) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: DashboardEventCard(
                          event: event,
                          onTap: () => onEventTap(context, event),
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
