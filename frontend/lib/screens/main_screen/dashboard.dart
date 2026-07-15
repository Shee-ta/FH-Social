import 'package:flutter/material.dart';
import 'package:frontend/controller/auth_controller.dart';
import 'package:frontend/controller/event_controller.dart';
import 'package:frontend/di/app_di.dart';
import 'package:frontend/entity/event.dart';
import 'package:frontend/screens/main_screen/dashboard/dashboard_header.dart';
import 'package:frontend/screens/main_screen/dashboard/dashboard_helpers.dart';
import 'package:frontend/screens/main_screen/dashboard/dashboard_section.dart';
import 'package:frontend/screens/main_screen/dashboard/weekly_schedule.dart';
import 'package:frontend/screens/main_screen/map/create_event_form_components/create_event_form.dart';
import 'package:frontend/screens/main_screen/map/event_popup_components/event_popup.dart';
import 'package:frontend/screens/main_screen/map/event_popup_components/event_popup_comment_input.dart';
import 'package:frontend/services/settings_service.dart';

class Dashboard extends StatefulWidget {
  Dashboard({
    super.key,
  })  : authController = AppDI.instance.authController,
        eventController = AppDI.instance.eventController,
        settingsService = AppDI.instance.settingsService,
        commentDrafts = AppDI.instance.commentDraft;

  final AuthController authController;
  final EventController eventController;
  final SettingsService settingsService;
  final List<CommentDraft> commentDrafts;

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  late bool _showWeeklySchedule = widget.settingsService.dashbordSelectedMode[1];

  @override
  Widget build(BuildContext context) {
    if (!widget.authController.isLoggedIn) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Please log in to see your dashboard.',
            style: Theme.of(context).textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    return Container(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Stack(
        fit: StackFit.expand,
        children: [
          AnimatedBuilder(
            animation: Listenable.merge([widget.authController, widget.eventController]),
            builder: (context, _) {
              final userId = widget.authController.userId;
              final allEvents = widget.eventController.events;

              final createdEvents = allEvents
                  .where((event) => event.creator.id == userId)
                  .toList()
                ..sort((a, b) => dashboardEventNextDateTime(a).compareTo(dashboardEventNextDateTime(b)));

              final joinedEvents = allEvents
                  .where((event) => event.members.any((member) => member.id == userId))
                  .toList()
                ..sort((a, b) => dashboardEventNextDateTime(a).compareTo(dashboardEventNextDateTime(b)));

              final upcomingCreatedEvents = createdEvents.where((event) => !dashboardIsEventPast(event)).toList();
              final upcomingJoinedEvents = joinedEvents.where((event) => !dashboardIsEventPast(event)).toList();

              final uniqueEvents = <String, Event>{
                for (final event in [...upcomingCreatedEvents, ...upcomingJoinedEvents]) event.id: event,
              }.values.toList();

              final screenWidth = MediaQuery.of(context).size.width;
              final isWide = screenWidth >= 1100;

              final createdIds = upcomingCreatedEvents.map((event) => event.id).toSet();
              final memberIds = upcomingJoinedEvents.map((event) => event.id).toSet();

              return SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  isWide ? 24 : 12,
                  isWide ? 24 : 12,
                  isWide ? 24 : 12,
                  120,
                ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      DashboardHeader(
                        showWeeklySchedule: _showWeeklySchedule,
                        onModeChanged: (isWeekly) {
                          setState(() {
                            _showWeeklySchedule = isWeekly;
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      if (_showWeeklySchedule)
                        WeeklySchedule(
                          events: uniqueEvents,
                          createdIds: createdIds,
                          memberIds: memberIds,
                          isWide: isWide,
                          openEventPopup: (event) => _openEventPopup(context, event),
                        )
                      else
                        _buildCardMode(
                          isWide: isWide,
                          upcomingCreatedEvents: upcomingCreatedEvents,
                          upcomingJoinedEvents: upcomingJoinedEvents,
                          onEventTap: (event) => _openEventPopup(context, event),
                        ),
                      ],
                    ),
                  );
                },
              ),
        Positioned(
          left: 24,
          bottom: 24,
            child: ElevatedButton(
              onPressed: () => _openCreateEventForm(context, draftReset: false),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.primaryContainer,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(16)),
                ),
                padding: const EdgeInsets.all(24),
              ),
              child: const Icon(Icons.add, size: 40),
            ),
          ),
        ]
      )
    );
  }

  Widget _buildCardMode({
    required bool isWide,
    required List<Event> upcomingCreatedEvents,
    required List<Event> upcomingJoinedEvents,
    required ValueChanged<Event> onEventTap,
  }) {
    final createdEventsSection = DashboardSection(
      title: 'Your events',
      subtitle: 'Your own upcoming events in time order.',
      events: upcomingCreatedEvents,
      emptyMessage: 'You have not created any upcoming events yet.',
      onEventTap: (_, event) => onEventTap(event),
    );

    final upcomingEventsSection = DashboardSection(
      title: 'Memberships',
      subtitle: 'Events you joined in time order.',
      events: upcomingJoinedEvents,
      emptyMessage: 'You are not yet a member of any upcoming events.',
      onEventTap: (_, event) => onEventTap(event),
    );

    if (isWide) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: createdEventsSection),
          const SizedBox(width: 20),
          Expanded(child: upcomingEventsSection),
        ],
      );
    }

    return Column(
      children: [
        createdEventsSection,
        const SizedBox(height: 16),
        upcomingEventsSection,
      ],
    );
  }

  void _openEventPopup(BuildContext context, Event event) {
    eventPopup(
      context,
      event,
      () => _openCreateEventForm(context),
    );
  }

  void _openCreateEventForm(BuildContext context, {bool draftReset = false}) {
    createEventForm(
      context,
      () async => null,
      widget.eventController.events,
      draftReset,
      hasNoMap: true,
    );
  }
}
