
import 'package:flutter/material.dart';
import 'package:frontend/UI/app_colors.dart';
import 'package:frontend/UI/formatter.dart';
import 'package:frontend/entity/event.dart';
import 'package:latlong2/latlong.dart';

/// Lifecycle state of a study group, derived purely from its start/end time
/// (and the next occurrence for repeating groups). No backend data needed.
enum StudyGroupStatus { live, soon, upcoming, past }

class StudyGroupStatusInfo {
  final StudyGroupStatus status;
  final String label;

  const StudyGroupStatusInfo(this.status, this.label);
}

/// Computes the current status of a study group.
StudyGroupStatusInfo studyGroupStatus(Event event) {
  final startIso = Formatter.calculateNextIso8601(
    event.iso8601startDateTime,
    event.days,
  );
  final start = DateTime.tryParse(startIso)?.toLocal();
  if (start == null) {
    return const StudyGroupStatusInfo(StudyGroupStatus.upcoming, 'Geplant');
  }

  // Derive an end time. For repeating groups we re-apply the original
  // duration to the next occurrence.
  DateTime effectiveEnd = start.add(const Duration(hours: 2));
  if (event.iso8601endDateTime.isNotEmpty) {
    final startOrig = DateTime.tryParse(event.iso8601startDateTime);
    final endOrig = DateTime.tryParse(event.iso8601endDateTime);
    if (startOrig != null && endOrig != null) {
      final duration = endOrig.difference(startOrig);
      if (!duration.isNegative) {
        effectiveEnd = start.add(duration);
      }
    }
  }

  final now = DateTime.now();

  if (now.isAfter(effectiveEnd)) {
    return const StudyGroupStatusInfo(StudyGroupStatus.past, 'Vorbei');
  }
  if (!now.isBefore(start) && now.isBefore(effectiveEnd)) {
    return const StudyGroupStatusInfo(StudyGroupStatus.live, 'Läuft gerade');
  }
  if (start.difference(now) <= const Duration(minutes: 60)) {
    return const StudyGroupStatusInfo(StudyGroupStatus.soon, 'Startet bald');
  }
  return const StudyGroupStatusInfo(StudyGroupStatus.upcoming, 'Geplant');
}

/// Sort key: soonest upcoming/live first, past groups pushed to the end.
DateTime studyGroupSortKey(Event event) {
  final startIso = Formatter.calculateNextIso8601(
    event.iso8601startDateTime,
    event.days,
  );
  return DateTime.tryParse(startIso)?.toLocal() ??
      DateTime.fromMillisecondsSinceEpoch(0);
}

const Distance _distanceCalc = Distance();

double? distanceToEventMeters(LatLng? from, Event event) {
  if (from == null) return null;
  return _distanceCalc.as(
    LengthUnit.Meter,
    from,
    LatLng(event.latitude, event.longitude),
  );
}

String formatDistance(double meters) {
  if (meters < 1000) {
    return '${meters.round()} m';
  }
  return '${(meters / 1000).toStringAsFixed(1)} km';
}

/// A small coloured pill that visualises the study group status.
class StudyGroupStatusBadge extends StatelessWidget {
  const StudyGroupStatusBadge({
    super.key,
    required this.event,
    this.compact = false,
  });

  final Event event;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final info = studyGroupStatus(event);
    final scheme = Theme.of(context).colorScheme;
    final appColors = Theme.of(context).extension<AppColors>();

    late Color background;
    late Color foreground;
    late IconData icon;

    switch (info.status) {
      case StudyGroupStatus.live:
        background = appColors?.success ?? scheme.tertiary;
        foreground = appColors?.onSuccess ?? scheme.onTertiary;
        icon = Icons.podcasts;
        break;
      case StudyGroupStatus.soon:
        background = Color.alphaBlend(
          Colors.orange.withValues(alpha: 0.85),
          scheme.surface,
        );
        foreground = Colors.white;
        icon = Icons.schedule;
        break;
      case StudyGroupStatus.upcoming:
        background = scheme.secondaryContainer;
        foreground = scheme.onSecondaryContainer;
        icon = Icons.event_available;
        break;
      case StudyGroupStatus.past:
        background = scheme.surfaceContainerHighest;
        foreground = scheme.onSurfaceVariant;
        icon = Icons.history;
        break;
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: compact ? 13 : 15, color: foreground),
          const SizedBox(width: 5),
          Text(
            info.label,
            style: TextStyle(
              color: foreground,
              fontSize: compact ? 11 : 12.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
