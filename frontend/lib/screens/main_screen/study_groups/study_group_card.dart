
import 'package:flutter/material.dart';
import 'package:frontend/UI/formatter.dart';
import 'package:frontend/entity/event.dart';
import 'package:frontend/screens/main_screen/map/event_popup_components/event_popup.dart';
import 'package:frontend/screens/main_screen/map/event_popup_components/event_popup_comment_input.dart';
import 'package:frontend/screens/main_screen/study_groups/study_group_status.dart';

/// A rich, tappable card summarising a single study group. Tapping opens the
/// existing detailed event popup (info, members, join, files, comments).
class StudyGroupCard extends StatelessWidget {
  const StudyGroupCard({
    super.key,
    required this.event,
    required this.commentDrafts,
    required this.setEventDraft,
    required this.createEvent,
    this.distanceMeters,
    this.highlightCreator = false,
    this.currentUserId,
  });

  final Event event;
  final List<CommentDraft> commentDrafts;
  final void Function(EventDraft) setEventDraft;
  final void Function() createEvent;
  final double? distanceMeters;
  final bool highlightCreator;
  final String? currentUserId;

  String get _timeLabel {
    final start = Formatter.deserialiseDateTime(
      event.iso8601startDateTime,
      rawDates: true,
    ).time;
    if (event.iso8601endDateTime.isEmpty) {
      return start;
    }
    final end = Formatter.deserialiseDateTime(
      event.iso8601endDateTime,
      rawDates: true,
    ).time;
    return '$start – $end';
  }

  String get _dateLabel {
    if (event.days.isEmpty) {
      return event.date;
    }
    return Formatter.deserialiseDateTime(
      Formatter.calculateNextIso8601(event.iso8601startDateTime, event.days),
    ).date;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isCreator =
        currentUserId != null && event.creator.id == currentUserId;

    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => eventPopup(
          context,
          event,
          commentDrafts,
          setEventDraft,
          createEvent,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      event.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  StudyGroupStatusBadge(event: event, compact: true),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                highlightCreator && isCreator
                    ? 'Von dir erstellt'
                    : 'Von ${event.creator.displayname.isEmpty ? 'Unbekannt' : event.creator.displayname}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 12),
              _infoRow(context, Icons.place_outlined, event.location),
              const SizedBox(height: 6),
              _infoRow(
                context,
                Icons.calendar_today_outlined,
                '$_dateLabel · $_timeLabel',
              ),
              if (event.days.isNotEmpty) ...[
                const SizedBox(height: 6),
                _infoRow(
                  context,
                  Icons.repeat,
                  Formatter.deserialiseDays(event.days).join(', '),
                ),
              ],
              if (distanceMeters != null) ...[
                const SizedBox(height: 6),
                _infoRow(
                  context,
                  Icons.near_me_outlined,
                  '${formatDistance(distanceMeters!)} entfernt',
                ),
              ],
              const SizedBox(height: 12),
              _memberRow(context),
              if (event.tags.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: event.tags
                      .take(6)
                      .map(
                        (tag) => Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: scheme.primaryContainer,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            tag,
                            style: TextStyle(
                              color: scheme.onPrimaryContainer,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRow(BuildContext context, IconData icon, String text) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 17, color: scheme.onSurfaceVariant),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }

  Widget _memberRow(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final members = event.members;
    if (members.isEmpty) {
      return Row(
        children: [
          Icon(Icons.group_outlined, size: 17, color: scheme.onSurfaceVariant),
          const SizedBox(width: 8),
          Text(
            'Noch niemand dabei',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
          ),
        ],
      );
    }

    const double radius = 13;
    final visible = members.take(3).toList();
    final stackWidth = radius * 2 + (visible.length - 1) * radius * 1.4;

    return Row(
      children: [
        SizedBox(
          width: stackWidth,
          height: radius * 2,
          child: Stack(
            children: List.generate(visible.length, (index) {
              return Positioned(
                left: index * radius * 1.4,
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: scheme.surface, width: 1.5),
                  ),
                  child: CircleAvatar(
                    radius: radius,
                    backgroundColor: scheme.inverseSurface,
                    child: Text(
                      visible[index].displayname.isEmpty
                          ? '?'
                          : visible[index]
                              .displayname
                              .substring(
                                0,
                                visible[index].displayname.length >= 2 ? 2 : 1,
                              )
                              .toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        color: scheme.onInverseSurface,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          members.length == 1 ? '1 dabei' : '${members.length} dabei',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }
}
