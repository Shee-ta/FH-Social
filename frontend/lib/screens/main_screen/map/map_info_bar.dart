import 'package:flutter/material.dart';
import 'package:frontend/UI/formatter.dart';
import 'package:frontend/controller/auth_controller.dart';
import 'package:frontend/controller/event_controller.dart';
import 'dart:async';

import 'package:frontend/di/app_di.dart';
import 'package:frontend/entity/event.dart';
import 'package:frontend/screens/main_screen/map/create_event_form_components/create_event_form.dart';
import 'package:frontend/screens/main_screen/map/event_popup_components/event_popup.dart';
import 'package:latlong2/latlong.dart';

class MapInfoBar extends StatefulWidget {
  MapInfoBar({
    super.key,
    required this.toggleEventList,
    required this.useLocationForEvent,
  })
  : eventController = AppDI.instance.eventController,
    authController = AppDI.instance.authController;

  final void Function(List<Event> events, {bool forceClose}) toggleEventList;
  final Future<LatLng?> Function() useLocationForEvent;
  final EventController eventController;
  final AuthController authController;

  @override
  State<MapInfoBar> createState() => _MapInfoBarState();
}

class _MapInfoBarState extends State<MapInfoBar> {
  final List<Event> _relevantFutureEvents = [];
  Event? _nextEvent;
  String _label = '';
  Timer? _timer;
  int _futureEventCount = 0;
  bool _isMinimised = false;

  void update() {
    if (!mounted) return;
    setState(() {
      _futureEventCount = 0;
      _nextEvent = null;
      _relevantFutureEvents.clear();
      for(final event in widget.eventController.futureEvents) {
        if (Formatter.iso8601StringToDateTime(Formatter.calculateNextIso8601(event.iso8601startDateTime, event.days)).isAfter(DateTime.now())) {
          if (event.creator.id == widget.authController.userId || event.members.any((member) => member.id == widget.authController.userId)) {
            _futureEventCount += 1;
            _nextEvent = event;
            _relevantFutureEvents.add(event);
          }
        }
      }
      _label = _countdownText(_nextEvent != null
        ? Formatter.iso8601StringToDateTime(Formatter.calculateNextIso8601(_nextEvent!.iso8601startDateTime, _nextEvent!.days))
        : null);
    });
  }

  @override
  void initState() {
    super.initState();
    widget.eventController.addListener(update);
    _timer = Timer.periodic(const Duration(minutes: 1), (_) { update(); });
    update();
  }

  @override
  void dispose() {
    widget.eventController.removeListener(update);
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 6,
      color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Wrap(
          spacing: 10,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            _InfoPill(
              icon: _isMinimised ? Icons.more_horiz : Icons.close,
              label: '',
              value: '',
              onPressed: () {
                setState(() {
                  _isMinimised = !_isMinimised;
                });
              },
            ),
            if (!_isMinimised)
            _InfoPill(
              icon: Icons.event,
              label: 'Relevant future events: ',
              value: '$_futureEventCount',
              onPressed: _futureEventCount < 1 ? null : () {
                widget.toggleEventList(_relevantFutureEvents, forceClose: false);
              },
            ),
            if (!_isMinimised)
            _InfoPill(
              icon: Icons.timer,
              label: 'Next in: ',
              value: _label,
              onPressed: _nextEvent == null ? null : () {
                eventPopup(
                  context,
                  _nextEvent!,
                  ({bool draftReset = false}) => 
                    createEventForm(
                      context,
                      widget.useLocationForEvent,
                      widget.eventController.events,
                      draftReset,
                    )
                  );
                  },
            ),
          ],
        ),
      ),
    );
  }

  String _countdownText(DateTime? nextEventDateTime) {
    if (nextEventDateTime == null) {
      return 'No upcoming';
    }

    final remaining = nextEventDateTime.difference(DateTime.now());
    if (remaining.isNegative) {
      return 'Now';
    }

    final days = remaining.inDays;
    final hours = remaining.inHours.remainder(24).toString().padLeft(2, '0');
    final minutes = remaining.inMinutes.remainder(60).toString().padLeft(2, '0');

    if (days > 0) {
      return '${days}d ${hours}h ${minutes}m';
    }
    return '$hours:$minutes';
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({
    required this.icon,
    required this.label,
    required this.value,
    required this.onPressed,
  }) : color = null;

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onPressed;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? Theme.of(context).colorScheme.primary;

    return ElevatedButton(
      onPressed: onPressed,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: effectiveColor),
          if (label.isNotEmpty) SizedBox(width: 6),
          if (label.isNotEmpty) Text(label, style: Theme.of(context).textTheme.bodyMedium),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}
