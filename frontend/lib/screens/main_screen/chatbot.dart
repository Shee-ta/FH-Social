import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:frontend/UI/formatter.dart';
import 'package:frontend/controller/auth_controller.dart';
import 'package:frontend/controller/event_controller.dart';
import 'package:frontend/di/app_di.dart';
import 'package:frontend/entity/event.dart';
import 'package:frontend/screens/main_screen/event_card.dart';
import 'package:frontend/screens/main_screen/map/create_event_form_components/create_event_form.dart';
import 'package:frontend/screens/main_screen/map/event_popup_components/event_popup.dart';

class _ChatMessage {
  final String text;
  final bool fromBot;
  final List<Event> results;
  final List<String> suggestions;

  _ChatMessage({
    required this.text,
    required this.fromBot,
    this.results = const [],
    this.suggestions = const [],
  });
}

/// On-device assistant. Before chatting the user picks a context: a general
/// question, or one of the study groups they belong to. When a group is chosen
/// its full data is loaded and turned into a text context (a "toString") that
/// the assistant answers from — the exact payload a real LLM (Gemini/Ollama)
/// would receive once a chat endpoint exists.
class ChatbotTab extends StatefulWidget {
  ChatbotTab({
    super.key,
  })  : eventController = AppDI.instance.eventController,
        authController = AppDI.instance.authController;

  final EventController eventController;
  final AuthController authController;

  @override
  State<ChatbotTab> createState() => _ChatbotTabState();
}

class _ChatbotTabState extends State<ChatbotTab>
    with AutomaticKeepAliveClientMixin {
  static const Map<int, String> _weekdayCodeByInt = {
    DateTime.monday: 'Mo',
    DateTime.tuesday: 'Tu',
    DateTime.wednesday: 'We',
    DateTime.thursday: 'Th',
    DateTime.friday: 'Fr',
    DateTime.saturday: 'Sa',
    DateTime.sunday: 'Su',
  };

  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final List<_ChatMessage> _messages = [];

  bool _started = false;
  Event? _contextEvent;

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
    _contextEvent?.controller.removeListener(_onChanged);
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  List<Event> get _myGroups {
    final userId = widget.authController.userId;
    if (userId.isEmpty) return [];
    return Event.sortEventsByDate(
      widget.eventController.events
        .where((e) =>
            e.creator.id == userId || e.members.any((m) => m.id == userId))
        .toList()
    );
  }

  void _startChat(Event? event) {
    _contextEvent?.controller.removeListener(_onChanged);
    _contextEvent = event;
    _messages.clear();

    if (event == null) {
      _messages.add(
        _ChatMessage(
          fromBot: true,
          text: 'Allgemeiner Modus. Frag mich nach Lerngruppen, Themen oder '
              'Terminen.',
          suggestions: const [
            'Was läuft heute?',
            'Welche Gruppen gibt es?',
            'Hilfe',
          ],
        ),
      );
    } else {
      event.controller.addListener(_onChanged);
      event.controller.fetchEventEntities(event.id);
      _messages.add(
        _ChatMessage(
          fromBot: true,
          text: 'Kontext gesetzt: „${event.title}". Ich kenne jetzt Ort, Zeit, '
              'Mitglieder, Tags und Dokumente dieser Gruppe. Frag mich etwas dazu.',
          suggestions: const [
            'Wann und wo?',
            'Wer ist dabei?',
            'Worum geht es?',
            'Zusammenfassung',
          ],
        ),
      );
    }

    setState(() => _started = true);
    _scrollToBottom();
  }

  void _backToSelection() {
    _contextEvent?.controller.removeListener(_onChanged);
    setState(() {
      _started = false;
      _contextEvent = null;
      _messages.clear();
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  DateTime _nextStart(Event event) => Formatter.iso8601StringToDateTime(Formatter.calculateNextIso8601(event.iso8601startDateTime, event.days)).toLocal();

  bool _occursOnDay(Event event, DateTime day) {
    final target = DateTime(day.year, day.month, day.day);
    final initialStart = Formatter.iso8601StringToDateTime(event.iso8601startDateTime).toLocal();
    final initialStartDateOnly = DateTime(
      initialStart.year,
      initialStart.month,
      initialStart.day,
    );

    if (target.isBefore(initialStartDateOnly)) {
      return false;
    }

    if (event.days.isEmpty) {
      return initialStartDateOnly == target;
    }

    final dayCode = _weekdayCodeByInt[target.weekday];
    return dayCode != null && event.days.contains(dayCode);
  }

  int _eventMinutesOfDay(Event event) {
    final start = Formatter.iso8601StringToDateTime(event.iso8601startDateTime).toLocal();
    return (start.hour * 60) + start.minute;
  }

  void _send(String raw) {
    final text = raw.trim();
    if (text.isEmpty) return;
    setState(() {
      _messages.add(_ChatMessage(text: text, fromBot: false));
      _messages.add(
        _contextEvent == null
            ? _buildGeneralReply(text)
            : _buildGroupReply(text, _contextEvent!),
      );
      _controller.clear();
    });
    _scrollToBottom();
  }

  // --- Context string handed to the assistant (and later to the LLM). --- //
  String buildGroupContext(Event e) {
    final b = StringBuffer();
    b.writeln('Lerngruppe: ${e.title}');
    b.writeln(
        'Gastgeber: ${e.creator.displayname.isEmpty ? 'Unbekannt' : e.creator.displayname}');
    b.writeln('Ort: ${e.location}');
    final time = Formatter.deserialiseDateTime(e.iso8601startDateTime,
                rawDates: true)
            .time +
        (e.iso8601endDateTime.isEmpty
            ? ''
            : ' – ${Formatter.deserialiseDateTime(e.iso8601endDateTime, rawDates: true).time}');
    b.writeln('Uhrzeit: $time');
    if (e.days.isEmpty) {
      b.writeln('Datum: ${e.date}');
    } else {
      b.writeln(
          'Nächster Termin: ${Formatter.deserialiseDateTime(Formatter.calculateNextIso8601(e.iso8601startDateTime, e.days)).date}');
      b.writeln('Wiederholt sich: ${Formatter.deserialiseDays(e.days).join(', ')}');
    }
    b.writeln('Status: ${Event.getStatus(e)}');
    if (e.description.isNotEmpty) b.writeln('Beschreibung: ${e.description}');
    if (e.recommendation.isNotEmpty) b.writeln('Lerntipp: ${e.recommendation}');
    if (e.tags.isNotEmpty) b.writeln('Tags: ${e.tags.join(', ')}');
    b.writeln(e.members.isEmpty
        ? 'Mitglieder: keine'
        : 'Mitglieder (${e.members.length}): ${e.members.map((m) => m.displayname).join(', ')}');
    b.writeln(e.filePreviews.isEmpty
        ? 'Dokumente: keine'
        : 'Dokumente: ${e.filePreviews.map((f) => f.fileName).join(', ')}');
    if (e.comments.isNotEmpty) {
      b.writeln('Kommentare (${e.comments.length}):');
      for (final c in e.comments.take(5)) {
        b.writeln('- ${c.creator.displayname}: ${c.content}');
      }
    }
    return b.toString().trim();
  }

  _ChatMessage _buildGroupReply(String input, Event e) {
    final q = input.toLowerCase();

    if (_containsAny(q, ['hilfe', 'help', 'was kannst du'])) {
      return _ChatMessage(
        fromBot: true,
        text: 'Zu „${e.title}" kann ich dir sagen:\n'
            '• Wann und wo? • Wer ist dabei? • Welche Tags/Themen?\n'
            '• Welche Dokumente gibt es? • Worum geht es (Beschreibung)?\n'
            '• „Zusammenfassung" für alles auf einmal.',
      );
    }

    if (_containsAny(q, ['zusammenfassung', 'überblick', 'ueberblick', 'alles', 'details'])) {
      return _ChatMessage(fromBot: true, text: buildGroupContext(e));
    }

    if (_containsAny(q, ['wann', 'zeit', 'uhr', 'termin', 'datum', 'wo ', 'ort', 'raum'])) {
      final where = 'Ort: ${e.location}';
      final time = Formatter.deserialiseDateTime(e.iso8601startDateTime, rawDates: true).time;
      final when = e.days.isEmpty
          ? 'am ${e.date} um $time'
          : 'nächster Termin ${Formatter.deserialiseDateTime(Formatter.calculateNextIso8601(e.iso8601startDateTime, e.days)).date} um $time (${Formatter.deserialiseDays(e.days).join(', ')})';
      return _ChatMessage(
        fromBot: true,
        text: '„${e.title}" findet $when statt.\n$where',
      );
    }

    if (_containsAny(q, ['wer', 'mitglied', 'teilnehmer', 'dabei', 'leute', 'personen'])) {
      if (e.members.isEmpty) {
        return _ChatMessage(
          fromBot: true,
          text: 'Aktuell ist niemand als Mitglied eingetragen. Gastgeber ist '
              '${e.creator.displayname}.',
        );
      }
      return _ChatMessage(
        fromBot: true,
        text: '${e.members.length} dabei: '
            '${e.members.map((m) => m.displayname).join(', ')}.\n'
            'Gastgeber: ${e.creator.displayname}.',
      );
    }

    if (_containsAny(q, ['tag', 'thema', 'themen', 'fach'])) {
      return _ChatMessage(
        fromBot: true,
        text: e.tags.isEmpty
            ? 'Für diese Gruppe sind noch keine Tags hinterlegt.'
            : 'Themen/Tags: ${e.tags.join(', ')}.',
      );
    }

    if (_containsAny(q, ['datei', 'dokument', 'unterlage', 'pdf', 'material', 'skript'])) {
      return _ChatMessage(
        fromBot: true,
        text: e.filePreviews.isEmpty
            ? 'Es sind noch keine Dokumente hochgeladen.'
            : 'Dokumente (${e.filePreviews.length}): '
                '${e.filePreviews.map((f) => f.fileName).join(', ')}.',
      );
    }

    if (_containsAny(q, ['worum', 'beschreibung', 'info', 'inhalt', 'geht es'])) {
      return _ChatMessage(
        fromBot: true,
        text: e.description.isEmpty
            ? 'Für diese Gruppe gibt es keine Beschreibung.'
            : e.description,
      );
    }

    if (_containsAny(q, ['tipp', 'empfehlung', 'lernen', 'ratschlag'])) {
      return _ChatMessage(
        fromBot: true,
        text: e.recommendation.isEmpty
            ? 'Für diese Gruppe gibt es keinen Lerntipp.'
            : 'Lerntipp: ${e.recommendation}',
      );
    }

    if (_containsAny(q, ['kommentar', 'gesagt', 'geschrieben', 'diskussion'])) {
      return _ChatMessage(
        fromBot: true,
        text: e.comments.isEmpty
            ? 'Es gibt noch keine Kommentare in dieser Gruppe.'
            : 'Letzte Kommentare:\n${e.comments.take(5).map((c) => '• ${c.creator.displayname}: ${c.content}').join('\n')}',
      );
    }

    // Fallback: show the full context summary.
    return _ChatMessage(
      fromBot: true,
      text: 'Dazu habe ich in dieser Gruppe nichts Passendes. Hier alles, was '
          'ich über „${e.title}" weiß:\n\n${buildGroupContext(e)}',
      suggestions: const ['Wann und wo?', 'Wer ist dabei?', 'Welche Dokumente?'],
    );
  }

  _ChatMessage _buildGeneralReply(String input) {
    final q = input.toLowerCase();
    final events = widget.eventController.events;

    if (_containsAny(q, ['hallo', 'hey', 'moin', 'servus']) || q == 'hi') {
      return _ChatMessage(
        fromBot: true,
        text: 'Hi! Ich kenne aktuell '
            '${events.length} Lerngruppe${events.length == 1 ? '' : 'n'}.',
        suggestions: const ['Was läuft heute?', 'Welche Gruppen gibt es?'],
      );
    }

    if (_containsAny(q, ['hilfe', 'help', 'was kannst du', 'funktion'])) {
      return _ChatMessage(
        fromBot: true,
        text: 'Im allgemeinen Modus kann ich dir Lerngruppen suchen:\n'
            '• „Was läuft heute?" oder „morgen"\n'
            '• „Welche Gruppen gibt es?"\n'
            '• ein Thema wie „Mathe" oder „Statistik"\n'
            'Für Fragen zu einer bestimmten Gruppe: oben „Kontext wechseln".',
      );
    }

    if (_containsAny(q, ['wie viele', 'wieviele', 'anzahl'])) {
      return _ChatMessage(
        fromBot: true,
        text: 'Es gibt aktuell ${events.length} '
            'Lerngruppe${events.length == 1 ? '' : 'n'}.',
      );
    }

    if (q.contains('heute')) {
      final today = DateTime.now();
      final list = events.where((e) => _occursOnDay(e, today)).toList()
        ..sort((a, b) {
          final timeCompare = _eventMinutesOfDay(a).compareTo(_eventMinutesOfDay(b));
          if (timeCompare != 0) {
            return timeCompare;
          }
          return a.title.toLowerCase().compareTo(b.title.toLowerCase());
        });
      return _resultMessage(list,
          list.isEmpty ? 'Heute findet keine Lerngruppe statt.' : 'Heute geplant:');
    }

    if (q.contains('morgen')) {
      final tomorrow = DateTime.now().add(const Duration(days: 1));
      final list = events.where((e) => _occursOnDay(e, tomorrow)).toList()
        ..sort((a, b) {
          final timeCompare = _eventMinutesOfDay(a).compareTo(_eventMinutesOfDay(b));
          if (timeCompare != 0) {
            return timeCompare;
          }
          return a.title.toLowerCase().compareTo(b.title.toLowerCase());
        });
      return _resultMessage(list,
          list.isEmpty ? 'Morgen findet keine Lerngruppe statt.' : 'Morgen geplant:');
    }

    if (_containsAny(q, ['läuft', 'laeuft', 'jetzt', 'gerade', 'aktiv'])) {
      final live = events
          .where((e) => Event.getStatus(e) == 'Läuft gerade')
          .toList();
      return _resultMessage(
        live,
        live.isEmpty
            ? 'Gerade läuft keine Lerngruppe.'
            : 'Diese Gruppe${live.length == 1 ? '' : 'n'} läuft gerade:',
      );
    }

    if (_containsAny(q, ['alle', 'welche gruppen', 'liste', 'übersicht', 'uebersicht'])) {
      final list = List<Event>.from(events)
        ..sort((a, b) => _nextStart(a).compareTo(_nextStart(b)));
      return _resultMessage(list,
          list.isEmpty ? 'Es gibt noch keine Lerngruppen.' : 'Alle Lerngruppen:');
    }

    final tokens = q.split(RegExp(r'\s+')).where((t) => t.length > 2).toList();
    final matches = events.where((e) {
      final haystack =
          '${e.title} ${e.location} ${e.description} ${e.tags.join(' ')}'
              .toLowerCase();
      return tokens.any(haystack.contains) || haystack.contains(q);
    }).toList()
      ..sort((a, b) => _nextStart(a).compareTo(_nextStart(b)));

    if (matches.isNotEmpty) {
      return _resultMessage(matches, 'Das habe ich zu „$input" gefunden:');
    }

    return _ChatMessage(
      fromBot: true,
      text: 'Dazu habe ich nichts gefunden. Frag mich nach einem Thema oder '
          'z. B. „Was läuft heute?".',
      suggestions: const ['Welche Gruppen gibt es?', 'Hilfe'],
    );
  }

  _ChatMessage _resultMessage(List<Event> events, String text) =>
      _ChatMessage(fromBot: true, text: text, results: events.take(8).toList());

  bool _containsAny(String text, List<String> needles) =>
      needles.any(text.contains);

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final scheme = Theme.of(context).colorScheme;
    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth >= 1100;
    final horizontalPadding = isWide ? 24.0 : 12.0;

    return Container(
      color: scheme.primaryContainer,
      child: !_started
          ? SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                horizontalPadding,
                horizontalPadding,
                24,
              ),
              child: _selectionView(),
            )
          : Column(
              children: [
                _contextBar(horizontalPadding),
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: EdgeInsets.fromLTRB(
                      horizontalPadding,
                      12,
                      horizontalPadding,
                      12,
                    ),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) => _bubble(_messages[index]),
                  ),
                ),
                _inputBar(horizontalPadding),
              ],
            ),
    );
  }

  // --- Pre-chat selection --- //
  Widget _selectionView() {
    final scheme = Theme.of(context).colorScheme;
    final groups = Event.sortEventsByDate(_myGroups).reversed.toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'ChatBot',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 10),
        Text(
          'Worauf soll sich deine Frage beziehen?',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 20),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: scheme.secondaryContainer,
              child: Icon(Icons.public, color: scheme.onSecondaryContainer),
            ),
            title: const Text('Allgemeine Frage'),
            subtitle: const Text('Lerngruppen suchen, Termine, Themen'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _startChat(null),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Oder eine meiner Lerngruppen:',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: scheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 8),
        if (!widget.authController.isLoggedIn)
          _hintCard(scheme, 'Melde dich an, um deine Lerngruppen als Kontext zu nutzen.')
        else if (groups.isEmpty)
          _hintCard(scheme,
              'Du bist noch in keiner Lerngruppe. Tritt einer bei, um sie hier auszuwählen.')
        else
          _groupWrap(groups),
      ],
    );
  }

  Widget _groupWrap(List<Event> groups) {
    final scheme = Theme.of(context).colorScheme;
    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 12.0;
        final maxWidth = constraints.maxWidth;

        int columns;
        if (maxWidth >= 1300) {
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
          children: groups
              .map(
                (event) => SizedBox(
                  width: cardWidth,
                  child: Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: scheme.primaryContainer,
                        child: Icon(
                          Icons.groups_2_outlined,
                          color: scheme.onPrimaryContainer,
                        ),
                      ),
                      title: Text(event.title),
                      subtitle: Text(
                        event.location,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: Text(Event.getStatus(event)),
                      onTap: () => _startChat(event),
                    ),
                  ),
                ),
              )
              .toList(),
        );
      },
    );
  }

  Widget _hintCard(ColorScheme scheme, String text) {
    return Card(
      color: scheme.surfaceContainerHighest,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: scheme.onSurfaceVariant),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: TextStyle(color: scheme.onSurfaceVariant),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _contextBar(double horizontalPadding) {
    final scheme = Theme.of(context).colorScheme;
    final isGroup = _contextEvent != null;
    return Material(
      color: scheme.surfaceContainerHighest,
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.fromLTRB(horizontalPadding, 8, horizontalPadding - 6, 8),
        child: Row(
          children: [
            Icon(isGroup ? Icons.groups_2_outlined : Icons.public,
                size: 18, color: scheme.onSurfaceVariant),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                isGroup ? 'Kontext: ${_contextEvent!.title}' : 'Allgemeiner Modus',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            TextButton.icon(
              onPressed: _backToSelection,
              icon: const Icon(Icons.swap_horiz, size: 18),
              label: const Text('Kontext wechseln'),
              style: TextButton.styleFrom(
                backgroundColor: scheme.onPrimaryContainer,
                foregroundColor: scheme.primaryContainer,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bubble(_ChatMessage message) {
    final scheme = Theme.of(context).colorScheme;
    final isBot = message.fromBot;
    final width = MediaQuery.of(context).size.width;
    final maxBubbleWidth = isBot
        ? math.min(width * 0.95, 1120.0)
        : math.min(width * 0.82, 720.0);

    return Align(
      alignment: isBot ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: maxBubbleWidth,
        ),
        margin: EdgeInsets.fromLTRB(isBot ? 0 : 48, 4, isBot ? 48 : 0, 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color:
              isBot ? scheme.surfaceContainerHighest : scheme.onPrimaryContainer,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isBot ? 4 : 18),
            bottomRight: Radius.circular(isBot ? 18 : 4),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.text,
              style: TextStyle(
                color: isBot ? scheme.onSurface : scheme.primaryContainer,
              ),
            ),
            if (message.results.isNotEmpty) ...[
              const SizedBox(height: 10),
              _resultWrap(message.results),
            ],
            if (message.suggestions.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: message.suggestions
                    .map((s) => ActionChip(
                          label: Text(s),
                          onPressed: () => _send(s),
                        ))
                    .toList(),
              ),
            ],
          ],
        ),
      ),
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

  Widget _resultWrap(List<Event> results) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 10.0;
        final maxWidth = constraints.maxWidth;

        int columns;
        if (maxWidth >= 1000) {
          columns = 3;
        } else if (maxWidth >= 650) {
          columns = 2;
        } else {
          columns = 1;
        }

        final cardWidth = (maxWidth - (spacing * (columns - 1))) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: results
              .map(
                (event) => SizedBox(
                  width: cardWidth,
                  child: DashboardEventCard(
                    event: event,
                    onTap: () => eventPopup(
                      context,
                      event,
                      () => _openCreateEventForm(context),
                    ),
                  ),
                ),
              )
              .toList(),
        );
      },
    );
  }

  Widget _inputBar(double horizontalPadding) {
    final scheme = Theme.of(context).colorScheme;
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(horizontalPadding, 6, horizontalPadding, 10),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                textInputAction: TextInputAction.send,
                onSubmitted: _send,
                decoration: InputDecoration(
                  hintText: 'Frag den Assistenten …',
                  filled: true,
                  fillColor: scheme.surfaceContainerHighest,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              icon: const Icon(Icons.send),
              onPressed: () => _send(_controller.text),
            ),
          ],
        ),
      ),
    );
  }
}
