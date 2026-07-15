import 'package:flutter/material.dart';
import 'package:frontend/UI/formatter.dart';
import 'package:frontend/controller/event_controller.dart';
import 'package:frontend/di/app_di.dart';
import 'package:frontend/entity/event.dart';
import 'package:frontend/screens/main_screen/event_card.dart';
import 'package:frontend/screens/main_screen/map/create_event_form_components/create_event_form.dart';
import 'package:frontend/screens/main_screen/map/event_popup_components/event_popup.dart';
import 'package:frontend/screens/main_screen/map/event_popup_components/event_popup_comment_input.dart';
import 'package:frontend/services/settings_service.dart';

class EventsTab extends StatefulWidget {
  EventsTab({super.key})
    : eventController = AppDI.instance.eventController,
      commentDrafts = AppDI.instance.commentDraft,
      settingsService = AppDI.instance.settingsService;

  final EventController eventController;
  final List<CommentDraft> commentDrafts;
  final SettingsService settingsService;

  @override
  State<EventsTab> createState() => _EventsTabState();
}

class _EventsTabState extends State<EventsTab> with AutomaticKeepAliveClientMixin {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    widget.eventController.addListener(_onControllerChanged);
  }

  @override
  void dispose() {
    widget.eventController.removeListener(_onControllerChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  bool _isPast(Event event) {
    final nextIso = event.days.isNotEmpty
        ? Formatter.calculateNextIso8601(event.iso8601startDateTime, event.days)
        : event.iso8601startDateTime;
    return Formatter.isIso8601InPast(nextIso);
  }

  bool _matchesQuery(Event event) {
    if (_query.isEmpty) {
      return true;
    }

    final query = _query.toLowerCase();
    final hostName = event.creator.displayname.isNotEmpty
        ? event.creator.displayname.toLowerCase()
        : event.creator.username.toLowerCase();
    final haystack = [
      event.title.toLowerCase(),
      hostName,
      event.creator.username.toLowerCase(),
      ...event.tags.map((tag) => tag.toLowerCase()),
    ].join(' ');

    final tokens = query.split(RegExp(r'\s+')).where((part) => part.isNotEmpty);
    return tokens.every(haystack.contains);
  }

  List<Event> get _visibleEvents {
    final events = widget.eventController.events
        .where((event) => widget.settingsService.eventSelectedMode[0] || !_isPast(event))
        .where(_matchesQuery)
        .toList();

    events.sort((a, b) {
      final aPast = _isPast(a);
      final bPast = _isPast(b);
      if (aPast != bPast) {
        return aPast ? 1 : -1;
      }

      final aNextIso = a.days.isNotEmpty
          ? Formatter.calculateNextIso8601(a.iso8601startDateTime, a.days)
          : a.iso8601startDateTime;
      final bNextIso = b.days.isNotEmpty
          ? Formatter.calculateNextIso8601(b.iso8601startDateTime, b.days)
          : b.iso8601startDateTime;
      final aDate = Formatter.iso8601StringToDateTime(aNextIso);
      final bDate = Formatter.iso8601StringToDateTime(bNextIso);

      if (aPast && bPast) {
        return bDate.compareTo(aDate);
      }
      return aDate.compareTo(bDate);
    });

    return events;
  }

  void onModeChanged(bool futureEventsOnly) {
    setState(() {
      widget.settingsService.eventSelectedMode = [!futureEventsOnly, futureEventsOnly];
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final scheme = Theme.of(context).colorScheme;

    return AnimatedBuilder(
      animation: Listenable.merge([widget.settingsService, widget.eventController]),
      builder: (context, _) {
        final events = _visibleEvents;
        final screenWidth = MediaQuery.of(context).size.width;
        final isWide = screenWidth >= 1100;

        return Container(
          color: scheme.primaryContainer,
          child: Stack(
            fit: StackFit.expand,
            children: [
              RefreshIndicator(
                onRefresh: () async => widget.eventController.fetchAll(),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(
                    isWide ? 24 : 12,
                    isWide ? 24 : 12,
                    isWide ? 24 : 12,
                    120,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Events',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: ToggleButtons(
                          fillColor: scheme.primary,
                          selectedColor: scheme.primaryContainer,
                          isSelected: widget.settingsService.eventSelectedMode,
                          onPressed: (index) => onModeChanged(index == 1),
                          borderRadius: BorderRadius.circular(10),
                          constraints: const BoxConstraints(minHeight: 40, minWidth: 120),
                          children: const [
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8),
                              child: Text('With past events'),
                            ),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8),
                              child: Text('Future events only'),
                            ),
                          ],
                        ),
                      ),
                      _searchBar(scheme),
                      const SizedBox(height: 12),
                      if (events.isEmpty) _emptyState(scheme) else _eventsWrap(events),
                    ],
                  ),
                ),
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
            ],
          ),
        );
      },
    );
  }

  Widget _searchBar(ColorScheme scheme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 12, 0, 6),
      child: TextField(
        controller: _searchController,
        onChanged: (value) => setState(() => _query = value.trim()),
        decoration: InputDecoration(
          hintText: 'Nach Titel, Tag oder Host suchen',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _query.isEmpty
              ? null
              : IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _query = '');
                  },
                ),
          filled: true,
          fillColor: scheme.surfaceContainerHighest,
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
    );
  }

  Widget _eventsWrap(List<Event> events) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 12.0;
        final maxWidth = constraints.maxWidth;

        int columns;
        if (maxWidth >= 1350) {
          columns = 4;
        } else if (maxWidth >= 920) {
          columns = 3;
        } else if (maxWidth >= 620) {
          columns = 2;
        } else {
          columns = 1;
        }

        final cardWidth = (maxWidth - (spacing * (columns - 1))) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: events
              .map(
                (event) => SizedBox(
                  width: cardWidth,
                  child: ListenableBuilder(
                    listenable: event.controller,
                    builder: (context, _) => DashboardEventCard(
                      event: event,
                      onTap: () => _openEventPopup(context, event),
                    ),
                  ),
                ),
              )
              .toList(),
        );
      },
    );
  }

  Widget _emptyState(ColorScheme scheme) {
    return Padding(
      padding: const EdgeInsets.only(top: 72),
      child: Column(
        children: [
          Icon(Icons.event_busy_outlined, size: 64, color: scheme.onSurfaceVariant),
          const SizedBox(height: 16),
          Text(
            _query.isNotEmpty
                ? 'Keine Events passen zur Suche.'
                : widget.settingsService.eventSelectedMode[0]
                    ? 'Es sind noch keine Events vorhanden.'
                    : 'Es sind aktuell keine zukünftigen Events vorhanden.',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
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