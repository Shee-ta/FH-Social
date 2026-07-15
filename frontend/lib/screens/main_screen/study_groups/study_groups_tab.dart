
import 'package:flutter/material.dart';
import 'package:frontend/controller/event_controller.dart';
import 'package:frontend/di/app_di.dart';
import 'package:frontend/entity/event.dart';
import 'package:frontend/screens/main_screen/map/event_popup_components/event_popup_comment_input.dart';
import 'package:frontend/screens/main_screen/study_groups/study_group_card.dart';
import 'package:frontend/screens/main_screen/study_groups/study_group_status.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

enum _SortMode { soonest, nearby }

class StudyGroupsTab extends StatefulWidget {
  StudyGroupsTab({
    super.key,
    required this.commentDrafts,
    required this.setEventDraft,
    required this.createEvent,
  }) : eventController = AppDI.instance.eventController;

  final EventController eventController;
  final List<CommentDraft> commentDrafts;
  final void Function(EventDraft) setEventDraft;
  final void Function() createEvent;

  @override
  State<StudyGroupsTab> createState() => _StudyGroupsTabState();
}

class _StudyGroupsTabState extends State<StudyGroupsTab>
    with AutomaticKeepAliveClientMixin {
  final _searchController = TextEditingController();
  String _query = '';
  final Set<String> _activeTags = {};
  _SortMode _sortMode = _SortMode.soonest;
  LatLng? _currentLocation;
  bool _hidePast = true;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    widget.eventController.addListener(_onChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _resolveLocation();
    });
  }

  @override
  void dispose() {
    widget.eventController.removeListener(_onChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _resolveLocation() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return;
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      }
      final pos = await Geolocator.getCurrentPosition();
      if (mounted) {
        setState(() => _currentLocation = LatLng(pos.latitude, pos.longitude));
      }
    } catch (_) {
      // Location stays null; nearby sort will simply be unavailable.
    }
  }

  List<String> get _allTags {
    final tags = widget.eventController.tags.keys.toList();
    tags.sort();
    return tags;
  }

  bool _matchesQuery(Event event) {
    if (_query.isEmpty) return true;
    final q = _query.toLowerCase();
    return event.title.toLowerCase().contains(q) ||
        event.location.toLowerCase().contains(q) ||
        event.description.toLowerCase().contains(q) ||
        event.creator.displayname.toLowerCase().contains(q) ||
        event.tags.any((t) => t.toLowerCase().contains(q));
  }

  bool _matchesTags(Event event) {
    if (_activeTags.isEmpty) return true;
    return event.tags.any(_activeTags.contains);
  }

  List<Event> get _visibleEvents {
    var events = widget.eventController.events
        .where(_matchesQuery)
        .where(_matchesTags)
        .toList();

    if (_hidePast) {
      events = events
          .where((e) => studyGroupStatus(e).status != StudyGroupStatus.past)
          .toList();
    }

    if (_sortMode == _SortMode.nearby && _currentLocation != null) {
      events.sort((a, b) {
        final da = distanceToEventMeters(_currentLocation, a) ?? double.infinity;
        final db = distanceToEventMeters(_currentLocation, b) ?? double.infinity;
        return da.compareTo(db);
      });
    } else {
      events.sort((a, b) => studyGroupSortKey(a).compareTo(studyGroupSortKey(b)));
    }
    return events;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final events = _visibleEvents;
    final scheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        _searchBar(scheme),
        _controlsRow(scheme),
        if (_allTags.isNotEmpty) _tagFilter(scheme),
        const SizedBox(height: 4),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => widget.eventController.fetchAll(),
            child: events.isEmpty
                ? _emptyState(scheme)
                : ListView.builder(
                    padding: const EdgeInsets.only(top: 4, bottom: 24),
                    itemCount: events.length,
                    itemBuilder: (context, index) {
                      final event = events[index];
                      return ListenableBuilder(
                        listenable: event.controller,
                        builder: (context, _) => StudyGroupCard(
                          event: event,
                          commentDrafts: widget.commentDrafts,
                          setEventDraft: widget.setEventDraft,
                          createEvent: widget.createEvent,
                          currentUserId:
                              AppDI.instance.authController.userId,
                          distanceMeters: _sortMode == _SortMode.nearby
                              ? distanceToEventMeters(_currentLocation, event)
                              : null,
                        ),
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }

  Widget _searchBar(ColorScheme scheme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
      child: TextField(
        controller: _searchController,
        onChanged: (value) => setState(() => _query = value.trim()),
        decoration: InputDecoration(
          hintText: 'Lerngruppe, Ort oder Thema suchen',
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
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _controlsRow(ColorScheme scheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          Expanded(
            child: SegmentedButton<_SortMode>(
              style: ButtonStyle(
                visualDensity: VisualDensity.compact,
                textStyle: WidgetStatePropertyAll(
                  Theme.of(context).textTheme.bodySmall,
                ),
              ),
              segments: const [
                ButtonSegment(
                  value: _SortMode.soonest,
                  label: Text('Nächste'),
                  icon: Icon(Icons.schedule, size: 16),
                ),
                ButtonSegment(
                  value: _SortMode.nearby,
                  label: Text('In der Nähe'),
                  icon: Icon(Icons.near_me, size: 16),
                ),
              ],
              selected: {_sortMode},
              onSelectionChanged: (selection) {
                final mode = selection.first;
                if (mode == _SortMode.nearby && _currentLocation == null) {
                  _resolveLocation();
                }
                setState(() => _sortMode = mode);
              },
            ),
          ),
          const SizedBox(width: 8),
          Tooltip(
            message: _hidePast
                ? 'Vergangene anzeigen'
                : 'Vergangene ausblenden',
            child: IconButton.filledTonal(
              isSelected: !_hidePast,
              icon: Icon(_hidePast ? Icons.history_toggle_off : Icons.history),
              onPressed: () => setState(() => _hidePast = !_hidePast),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tagFilter(ColorScheme scheme) {
    return SizedBox(
      height: 42,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: [
          for (final tag in _allTags)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(tag),
                selected: _activeTags.contains(tag),
                onSelected: (selected) => setState(() {
                  if (selected) {
                    _activeTags.add(tag);
                  } else {
                    _activeTags.remove(tag);
                  }
                }),
              ),
            ),
        ],
      ),
    );
  }

  Widget _emptyState(ColorScheme scheme) {
    return ListView(
      children: [
        const SizedBox(height: 80),
        Icon(Icons.groups_2_outlined, size: 64, color: scheme.onSurfaceVariant),
        const SizedBox(height: 16),
        Center(
          child: Text(
            _query.isNotEmpty || _activeTags.isNotEmpty
                ? 'Keine Lerngruppe passt zur Suche.'
                : 'Noch keine Lerngruppen vorhanden.',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: Text(
            'Erstelle eine neue Gruppe im Karten-Tab.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
          ),
        ),
      ],
    );
  }
}
