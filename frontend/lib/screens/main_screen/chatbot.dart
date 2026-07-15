import 'package:flutter/material.dart';
import 'package:frontend/UI/formatter.dart';
import 'package:frontend/controller/auth_controller.dart';
import 'package:frontend/controller/event_controller.dart';
import 'package:frontend/di/app_di.dart';
import 'package:frontend/entity/event.dart';
import 'package:frontend/screens/main_screen/map/event_popup_components/event_popup.dart';
import 'package:frontend/screens/main_screen/map/event_popup_components/event_popup_comment_input.dart';
import 'package:frontend/screens/main_screen/study_groups/study_group_status.dart';
import 'package:frontend/services/ai_service.dart';

enum _Mode { none, general, ai }

class _ChatMessage {
  final String text;
  final bool fromBot;
  final bool loading;
  final String notes;
  final List<Event> results;
  final List<String> suggestions;

  _ChatMessage({
    required this.fromBot,
    this.text = '',
    this.loading = false,
    this.notes = '',
    this.results = const [],
    this.suggestions = const [],
  });
}

/// Assistant with two modes:
/// - general: on-device rule-based helper over the loaded study groups.
/// - ai: real generative answers via the backend (/ai/chat), using the OCR
///   text of the selected groups' PDF documents.
class ChatbotTab extends StatefulWidget {
  ChatbotTab({
    super.key,
    required this.commentDrafts,
    required this.setEventDraft,
    required this.createEvent,
  })  : eventController = AppDI.instance.eventController,
        authController = AppDI.instance.authController,
        aiService = AppDI.instance.aiService;

  final EventController eventController;
  final AuthController authController;
  final AiService aiService;
  final List<CommentDraft> commentDrafts;
  final void Function(EventDraft) setEventDraft;
  final void Function() createEvent;

  @override
  State<ChatbotTab> createState() => _ChatbotTabState();
}

class _ChatbotTabState extends State<ChatbotTab>
    with AutomaticKeepAliveClientMixin {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final List<_ChatMessage> _messages = [];

  _Mode _mode = _Mode.none;
  final Set<String> _selectedEventIds = {};
  final Set<String> _selectedFileNames = {};

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
    return widget.eventController.events
        .where((e) =>
            e.creator.id == userId || e.members.any((m) => m.id == userId))
        .toList()
      ..sort((a, b) => studyGroupSortKey(a).compareTo(studyGroupSortKey(b)));
  }

  List<Event> get _selectedEvents => widget.eventController.events
      .where((e) => _selectedEventIds.contains(e.id))
      .toList();

  void _startGeneral() {
    _mode = _Mode.general;
    _messages
      ..clear()
      ..add(_ChatMessage(
        fromBot: true,
        text: 'Allgemeiner Modus. Termine und Gruppen beantworte ich sofort aus '
            'der App, offene Fragen per KI.',
        suggestions: const [
          'Was läuft heute?',
          'Welche Gruppen gibt es?',
          'Erkläre mir binäre Suche',
        ],
      ));
    setState(() {});
    _scrollToBottom();
  }

  void _startAi() {
    if (_selectedEventIds.isEmpty) return;
    _mode = _Mode.ai;
    _selectedFileNames.clear();
    // Load documents/members of the selected events for the file picker.
    for (final event in _selectedEvents) {
      event.controller.fetchEventEntities(event.id);
    }
    final names = _selectedEvents.map((e) => e.title).join(', ');
    _messages
      ..clear()
      ..add(_ChatMessage(
        fromBot: true,
        text: 'KI-Chat zu: $names.\nIch beantworte Fragen zu den PDF-Dokumenten '
            'dieser Lerngruppe(n). Standardmäßig nutze ich alle Dokumente – über '
            'das Ordner-Symbol oben kannst du gezielt einzelne auswählen.',
      ));
    setState(() {});
    _scrollToBottom();
  }

  void _backToSelection() {
    setState(() {
      _mode = _Mode.none;
      _messages.clear();
      _selectedFileNames.clear();
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

  void _dispatchSend(String raw) {
    if (_mode == _Mode.ai) {
      _sendAi(raw);
    } else {
      _sendGeneral(raw);
    }
  }

  // --- General: instant local answers for app data, AI for the rest --- //
  Future<void> _sendGeneral(String raw) async {
    final text = raw.trim();
    if (text.isEmpty) return;
    setState(() {
      _messages.add(_ChatMessage(text: text, fromBot: false));
      _controller.clear();
    });

    // Fast, structured answers for questions the app can answer itself.
    final local = _tryLocalReply(text);
    if (local != null) {
      setState(() => _messages.add(local));
      _scrollToBottom();
      return;
    }

    // Everything else goes to the AI (no document context in general mode).
    setState(() => _messages.add(_ChatMessage(fromBot: true, loading: true)));
    _scrollToBottom();

    final token = await AppDI.instance.authService.getAccessToken();
    final result = await widget.aiService.chat(text, const [], const [], token);

    if (!mounted) return;
    setState(() {
      _messages.removeWhere((m) => m.loading);
      if (result == null) {
        _messages.add(_ChatMessage(
          fromBot: true,
          text: 'Die KI ist gerade nicht erreichbar. Läuft das Backend und ist '
              'ein KI-Modell konfiguriert?',
        ));
      } else {
        _messages.add(_ChatMessage(
          fromBot: true,
          text: result.answer.isEmpty
              ? 'Ich habe dazu keine Antwort erhalten.'
              : result.answer,
          notes: result.notes,
        ));
      }
    });
    _scrollToBottom();
  }

  // --- AI (backend) --- //
  Future<void> _sendAi(String raw) async {
    final text = raw.trim();
    if (text.isEmpty) return;
    setState(() {
      _messages.add(_ChatMessage(text: text, fromBot: false));
      _messages.add(_ChatMessage(fromBot: true, loading: true));
      _controller.clear();
    });
    _scrollToBottom();

    final token = await AppDI.instance.authService.getAccessToken();
    final result = await widget.aiService.chat(
      text,
      _selectedEventIds.toList(),
      _selectedFileNames.toList(),
      token,
    );

    if (!mounted) return;
    setState(() {
      _messages.removeWhere((m) => m.loading);
      if (result == null) {
        _messages.add(_ChatMessage(
          fromBot: true,
          text: 'Die KI ist gerade nicht erreichbar. Läuft das Backend und ist '
              'ein KI-Modell konfiguriert?',
        ));
      } else {
        _messages.add(_ChatMessage(
          fromBot: true,
          text: result.answer.isEmpty
              ? 'Ich habe dazu keine Antwort erhalten.'
              : result.answer,
          notes: result.notes,
        ));
      }
    });
    _scrollToBottom();
  }

  DateTime _nextStart(Event event) => studyGroupSortKey(event);

  bool _isOnDay(Event event, DateTime day) {
    final start = _nextStart(event);
    return start.year == day.year &&
        start.month == day.month &&
        start.day == day.day;
  }

  /// Returns an instant local answer for questions the app can answer from its
  /// own data (schedule, group lists). Returns null for everything else, so the
  /// caller can forward the question to the AI.
  _ChatMessage? _tryLocalReply(String input) {
    final q = input.toLowerCase();
    final events = widget.eventController.events;

    if (_containsAny(q, ['hilfe', 'help', 'was kannst du', 'funktion'])) {
      return _ChatMessage(
        fromBot: true,
        text: 'Ich beantworte hier zweierlei:\n'
            '• App-Fragen sofort – „Was läuft heute?", „morgen", „Welche Gruppen '
            'gibt es?", ein Thema wie „Mathe".\n'
            '• Alles andere per KI – stell einfach eine offene Frage.\n'
            'Für Fragen zu den PDF-Dokumenten einer Gruppe: oben „Wechseln" und '
            'die KI zu einer Lerngruppe wählen.',
      );
    }
    if (_containsAny(q, ['wie viele', 'wieviele', 'anzahl']) &&
        _containsAny(q, ['gruppe', 'lerngruppe', 'treffen'])) {
      return _ChatMessage(
        fromBot: true,
        text: 'Es gibt aktuell ${events.length} '
            'Lerngruppe${events.length == 1 ? '' : 'n'}.',
      );
    }
    if (_containsAny(q, ['läuft', 'laeuft', 'gerade', 'aktiv']) &&
        _containsAny(q, ['gruppe', 'lerngruppe', 'treffen', 'jetzt'])) {
      final live = events
          .where((e) => studyGroupStatus(e).status == StudyGroupStatus.live)
          .toList();
      return _resultMessage(
        live,
        live.isEmpty
            ? 'Gerade läuft keine Lerngruppe.'
            : 'Diese Gruppe${live.length == 1 ? '' : 'n'} läuft gerade:',
      );
    }
    if (q.contains('heute')) {
      final today = DateTime.now();
      final list = events.where((e) => _isOnDay(e, today)).toList()
        ..sort((a, b) => _nextStart(a).compareTo(_nextStart(b)));
      return _resultMessage(list,
          list.isEmpty ? 'Heute findet keine Lerngruppe statt.' : 'Heute geplant:');
    }
    if (q.contains('morgen')) {
      final tomorrow = DateTime.now().add(const Duration(days: 1));
      final list = events.where((e) => _isOnDay(e, tomorrow)).toList()
        ..sort((a, b) => _nextStart(a).compareTo(_nextStart(b)));
      return _resultMessage(list,
          list.isEmpty ? 'Morgen findet keine Lerngruppe statt.' : 'Morgen geplant:');
    }
    if (_containsAny(q, ['alle gruppen', 'welche gruppen', 'gruppen liste',
        'liste der gruppen', 'übersicht', 'uebersicht'])) {
      final list = List<Event>.from(events)
        ..sort((a, b) => _nextStart(a).compareTo(_nextStart(b)));
      return _resultMessage(list,
          list.isEmpty ? 'Es gibt noch keine Lerngruppen.' : 'Alle Lerngruppen:');
    }

    // Short topic queries: try to match study groups; longer ones go to the AI.
    final wordCount = q.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
    if (wordCount <= 3) {
      final tokens = q.split(RegExp(r'\s+')).where((t) => t.length > 2).toList();
      final matches = events.where((e) {
        final haystack =
            '${e.title} ${e.location} ${e.tags.join(' ')}'.toLowerCase();
        return tokens.any(haystack.contains);
      }).toList()
        ..sort((a, b) => _nextStart(a).compareTo(_nextStart(b)));
      if (matches.isNotEmpty) {
        return _resultMessage(matches, 'Das habe ich zu „$input" gefunden:');
      }
    }

    return null;
  }

  _ChatMessage _resultMessage(List<Event> events, String text) =>
      _ChatMessage(fromBot: true, text: text, results: events.take(8).toList());

  bool _containsAny(String text, List<String> needles) =>
      needles.any(text.contains);

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (_mode == _Mode.none) {
      return _selectionView();
    }
    return Column(
      children: [
        _contextBar(),
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.symmetric(vertical: 12),
            itemCount: _messages.length,
            itemBuilder: (context, index) => _bubble(_messages[index]),
          ),
        ),
        _inputBar(),
      ],
    );
  }

  // --- Selection --- //
  Widget _selectionView() {
    final scheme = Theme.of(context).colorScheme;
    final groups = _myGroups;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const SizedBox(height: 8),
        Icon(Icons.smart_toy_outlined, size: 48, color: scheme.primary),
        const SizedBox(height: 12),
        Text(
          'Wie möchtest du starten?',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium,
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
            subtitle: const Text('Lerngruppen suchen, Termine, Themen (lokal)'),
            trailing: const Icon(Icons.chevron_right),
            onTap: _startGeneral,
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Icon(Icons.auto_awesome, size: 18, color: scheme.primary),
            const SizedBox(width: 8),
            Text(
              'KI zu meinen Lerngruppen',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Wähle eine oder mehrere Gruppen – die KI erklärt dir ihre Dokumente.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 10),
        if (!widget.authController.isLoggedIn)
          _hintCard(scheme, 'Melde dich an, um die KI zu deinen Lerngruppen zu nutzen.')
        else if (groups.isEmpty)
          _hintCard(scheme,
              'Du bist noch in keiner Lerngruppe. Tritt einer bei, um ihre Dokumente mit der KI zu besprechen.')
        else ...[
          ...groups.map((event) {
            final selected = _selectedEventIds.contains(event.id);
            return Card(
              elevation: selected ? 3 : 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: selected ? scheme.primary : Colors.transparent,
                  width: 1.5,
                ),
              ),
              child: CheckboxListTile(
                value: selected,
                onChanged: (checked) => setState(() {
                  if (checked == true) {
                    _selectedEventIds.add(event.id);
                  } else {
                    _selectedEventIds.remove(event.id);
                  }
                }),
                title: Text(event.title),
                subtitle: Text(
                  event.location,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                secondary: StudyGroupStatusBadge(event: event, compact: true),
              ),
            );
          }),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _selectedEventIds.isEmpty ? null : _startAi,
            icon: const Icon(Icons.auto_awesome),
            label: Text(
              _selectedEventIds.isEmpty
                  ? 'Gruppe(n) auswählen'
                  : 'KI-Chat starten (${_selectedEventIds.length})',
            ),
          ),
        ],
      ],
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
              child: Text(text, style: TextStyle(color: scheme.onSurfaceVariant)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _contextBar() {
    final scheme = Theme.of(context).colorScheme;
    final isAi = _mode == _Mode.ai;
    final label = isAi
        ? 'KI · ${_selectedEventIds.length} Gruppe${_selectedEventIds.length == 1 ? '' : 'n'}'
            '${_selectedFileNames.isEmpty ? '' : ' · ${_selectedFileNames.length} Datei(en)'}'
        : 'Allgemeiner Modus';
    return Material(
      color: scheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 6, 6, 6),
        child: Row(
          children: [
            Icon(isAi ? Icons.auto_awesome : Icons.public,
                size: 18, color: scheme.onSurfaceVariant),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            if (isAi)
              IconButton(
                tooltip: 'Dokumente auswählen',
                icon: const Icon(Icons.folder_open, size: 20),
                onPressed: _openFilePicker,
              ),
            TextButton.icon(
              onPressed: _backToSelection,
              icon: const Icon(Icons.swap_horiz, size: 18),
              label: const Text('Wechseln'),
            ),
          ],
        ),
      ),
    );
  }

  void _openFilePicker() {
    final scheme = Theme.of(context).colorScheme;
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            final events = _selectedEvents;
            final hasFiles = events.any((e) => e.filePreviews.isNotEmpty);
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Dokumente für die KI',
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text(
                      'Nichts ausgewählt = alle PDFs der Gruppen. Es werden nur '
                      'PDFs unterstützt.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(height: 8),
                    if (!hasFiles)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Center(
                          child: Text(
                            'Keine Dokumente in den gewählten Gruppen.',
                            style: TextStyle(color: scheme.onSurfaceVariant),
                          ),
                        ),
                      )
                    else
                      Flexible(
                        child: ListView(
                          shrinkWrap: true,
                          children: [
                            for (final event in events) ...[
                              if (event.filePreviews.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(4, 10, 4, 2),
                                  child: Text(
                                    event.title,
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelLarge
                                        ?.copyWith(
                                            color: scheme.onSurfaceVariant),
                                  ),
                                ),
                              ...event.filePreviews.map((file) {
                                final isPdf =
                                    file.fileName.toLowerCase().endsWith('.pdf');
                                final selected =
                                    _selectedFileNames.contains(file.fileName);
                                return CheckboxListTile(
                                  dense: true,
                                  value: selected,
                                  onChanged: isPdf
                                      ? (checked) {
                                          setSheetState(() {});
                                          setState(() {
                                            if (checked == true) {
                                              _selectedFileNames
                                                  .add(file.fileName);
                                            } else {
                                              _selectedFileNames
                                                  .remove(file.fileName);
                                            }
                                          });
                                        }
                                      : null,
                                  title: Text(file.fileName),
                                  subtitle: isPdf
                                      ? null
                                      : const Text('Keine PDF – nicht auswertbar'),
                                  secondary: Icon(
                                    isPdf
                                        ? Icons.picture_as_pdf_outlined
                                        : Icons.insert_drive_file_outlined,
                                  ),
                                );
                              }),
                            ],
                          ],
                        ),
                      ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        TextButton(
                          onPressed: () {
                            setSheetState(() {});
                            setState(() => _selectedFileNames.clear());
                          },
                          child: const Text('Auswahl leeren'),
                        ),
                        const Spacer(),
                        FilledButton(
                          onPressed: () => Navigator.of(sheetContext).pop(),
                          child: const Text('Fertig'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _bubble(_ChatMessage message) {
    final scheme = Theme.of(context).colorScheme;
    final isBot = message.fromBot;

    return Align(
      alignment: isBot ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.82,
        ),
        margin: EdgeInsets.fromLTRB(isBot ? 12 : 48, 4, isBot ? 48 : 12, 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color:
              isBot ? scheme.surfaceContainerHighest : scheme.primaryContainer,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isBot ? 4 : 18),
            bottomRight: Radius.circular(isBot ? 18 : 4),
          ),
        ),
        child: message.loading
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text('Denkt nach …',
                      style: TextStyle(color: scheme.onSurfaceVariant)),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.text,
                    style: TextStyle(
                      color:
                          isBot ? scheme.onSurface : scheme.onPrimaryContainer,
                    ),
                  ),
                  if (message.notes.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: scheme.surface,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.info_outline,
                              size: 16, color: scheme.onSurfaceVariant),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              message.notes,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: scheme.onSurfaceVariant),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  for (final event in message.results)
                    _resultTile(event, scheme),
                  if (message.suggestions.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: message.suggestions
                          .map((s) => ActionChip(
                                label: Text(s),
                                onPressed: () => _dispatchSend(s),
                              ))
                          .toList(),
                    ),
                  ],
                ],
              ),
      ),
    );
  }

  Widget _resultTile(Event event, ColorScheme scheme) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: ListTile(
        dense: true,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Text(event.title,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(
          '${event.location} · ${Formatter.deserialiseDateTime(Formatter.calculateNextIso8601(event.iso8601startDateTime, event.days)).date}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: StudyGroupStatusBadge(event: event, compact: true),
        onTap: () => eventPopup(
          context,
          event,
          widget.commentDrafts,
          widget.setEventDraft,
          widget.createEvent,
        ),
      ),
    );
  }

  Widget _inputBar() {
    final scheme = Theme.of(context).colorScheme;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                textInputAction: TextInputAction.send,
                onSubmitted: _dispatchSend,
                decoration: InputDecoration(
                  hintText: _mode == _Mode.ai
                      ? 'Frag die KI zu den Dokumenten …'
                      : 'Frag den Assistenten …',
                  filled: true,
                  fillColor: scheme.surfaceContainerHighest,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              icon: const Icon(Icons.send),
              onPressed: () => _dispatchSend(_controller.text),
            ),
          ],
        ),
      ),
    );
  }
}
