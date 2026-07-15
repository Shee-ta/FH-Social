
import 'package:flutter/material.dart';
import 'package:frontend/UI/constants.dart';
import 'package:frontend/UI/formatter.dart';
import 'package:frontend/entity/event.dart';
import 'package:frontend/screens/main_screen/map/event_popup_components/event_popup_tags.dart';

class EventPopupInfo extends StatelessWidget {
  const EventPopupInfo({
    super.key,
    required this.event,
  });

  final Event event;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.onPrimary,
      elevation: 6,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 12,
          children: [
            Align(
              alignment: Alignment.topRight,
              child: Text(
                'Erstellt von ${event.creator.displayname.isEmpty ? 'Unbekannt' : event.creator.displayname}',
                textAlign: TextAlign.right,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            Text(
              event.title,
              style: Theme.of(context).textTheme.titleLarge,
            ),

            Text('Ort: ${event.location}'),

            Text('Zeit: ${Formatter.deserialiseDateTime(event.iso8601startDateTime, rawDates: true).time}'
              ' ${event.iso8601endDateTime.isEmpty ? '' : '- ${Formatter.deserialiseDateTime(event.iso8601endDateTime, rawDates: true).time}'}' ),

            if(event.days.isEmpty) ...[
              Text('Datum: ${event.date}'),
            ]
            else ...[
              Text('Nächster Termin: ${
                Formatter.deserialiseDateTime(
                Formatter.calculateNextIso8601(
                  event.iso8601startDateTime,
                  event.days)).date
              }'),
              Text('Wiederholt sich: ${Formatter.deserialiseDays(event.days).join(', ')}'),
            ],
            if (event.description.isNotEmpty) ...[
              Divider(),
              Text(event.description),
            ],
            if(event.recommendation.isNotEmpty) ...[
              Card(
                color: Theme.of(context).colorScheme.surfaceContainer,
                elevation: 6,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.lightbulb, color: Theme.of(context).colorScheme.onSurfaceVariant),
                      Const.spacing,
                      Expanded(
                        child: Text(
                          event.recommendation,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  )
                ),
              )
            ],
            if(event.tags.isNotEmpty) ...[
              EventPopupTags(
                tags: event.tags,
              ),
            ],
          ],
        ),
      ),
    );
  }
}