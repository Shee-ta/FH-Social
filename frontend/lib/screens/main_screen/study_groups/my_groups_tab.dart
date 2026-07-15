
import 'package:flutter/material.dart';
import 'package:frontend/controller/auth_controller.dart';
import 'package:frontend/controller/event_controller.dart';
import 'package:frontend/di/app_di.dart';
import 'package:frontend/entity/event.dart';
import 'package:frontend/screens/main_screen/map/event_popup_components/event_popup_comment_input.dart';
import 'package:frontend/screens/main_screen/study_groups/study_group_card.dart';
import 'package:frontend/screens/main_screen/study_groups/study_group_status.dart';

/// Shows the study groups the current user created or joined.
class MyGroupsTab extends StatefulWidget {
  MyGroupsTab({
    super.key,
    required this.commentDrafts,
    required this.setEventDraft,
    required this.createEvent,
  })  : eventController = AppDI.instance.eventController,
        authController = AppDI.instance.authController;

  final EventController eventController;
  final AuthController authController;
  final List<CommentDraft> commentDrafts;
  final void Function(EventDraft) setEventDraft;
  final void Function() createEvent;

  @override
  State<MyGroupsTab> createState() => _MyGroupsTabState();
}

class _MyGroupsTabState extends State<MyGroupsTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    widget.eventController.addListener(_onChanged);
    widget.authController.addListener(_onChanged);
  }

  @override
  void dispose() {
    widget.eventController.removeListener(_onChanged);
    widget.authController.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  int _sort(Event a, Event b) =>
      studyGroupSortKey(a).compareTo(studyGroupSortKey(b));

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final scheme = Theme.of(context).colorScheme;
    final userId = widget.authController.userId;

    if (!widget.authController.isLoggedIn || userId.isEmpty) {
      return _message(
        scheme,
        Icons.lock_outline,
        'Melde dich an, um deine Lerngruppen zu sehen.',
      );
    }

    final created = widget.eventController.events
        .where((e) => e.creator.id == userId)
        .toList()
      ..sort(_sort);

    final joined = widget.eventController.events
        .where((e) =>
            e.creator.id != userId &&
            e.members.any((m) => m.id == userId))
        .toList()
      ..sort(_sort);

    if (created.isEmpty && joined.isEmpty) {
      return RefreshIndicator(
        onRefresh: () => widget.eventController.fetchAll(),
        child: _message(
          scheme,
          Icons.bookmark_border,
          'Du bist noch in keiner Lerngruppe.\nTritt einer Gruppe bei oder erstelle eine im Karten-Tab.',
          scrollable: true,
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => widget.eventController.fetchAll(),
      child: ListView(
        padding: const EdgeInsets.only(top: 8, bottom: 24),
        children: [
          if (joined.isNotEmpty) ...[
            _sectionHeader(scheme, 'Beigetreten', joined.length),
            ...joined.map(_card),
          ],
          if (created.isNotEmpty) ...[
            _sectionHeader(scheme, 'Von mir erstellt', created.length),
            ...created.map(_card),
          ],
        ],
      ),
    );
  }

  Widget _card(Event event) => ListenableBuilder(
        listenable: event.controller,
        builder: (context, _) => StudyGroupCard(
          event: event,
          commentDrafts: widget.commentDrafts,
          setEventDraft: widget.setEventDraft,
          createEvent: widget.createEvent,
          currentUserId: widget.authController.userId,
          highlightCreator: true,
        ),
      );

  Widget _sectionHeader(ColorScheme scheme, String title, int count) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
      child: Row(
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
            decoration: BoxDecoration(
              color: scheme.secondaryContainer,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: scheme.onSecondaryContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _message(
    ColorScheme scheme,
    IconData icon,
    String text, {
    bool scrollable = false,
  }) {
    final content = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (scrollable) const SizedBox(height: 120),
        Icon(icon, size: 64, color: scheme.onSurfaceVariant),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
          ),
        ),
      ],
    );
    if (scrollable) {
      return ListView(children: [content]);
    }
    return Center(child: content);
  }
}
