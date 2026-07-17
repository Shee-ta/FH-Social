import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:frontend/UI/formatter.dart';
import 'package:frontend/controller/auth_controller.dart';
import 'package:frontend/controller/event_controller.dart';
import 'package:frontend/di/app_di.dart';
import 'package:frontend/entity/event.dart';
import 'package:frontend/screens/main_screen/map/create_event_form_components/create_event_form.dart';
import 'package:frontend/screens/main_screen/map/event_popup_components/event_popup.dart';
import 'package:frontend/services/ai_service.dart';

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

enum _Mode { none, general, ai }

class ChatbotTab extends StatefulWidget {
  ChatbotTab({super.key})
    : eventController = AppDI.instance.eventController,
      authController = AppDI.instance.authController,
      aiService = AppDI.instance.aiService;

  final EventController eventController;
  final AuthController authController;
  final AiService aiService;

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

  _Mode _mode = _Mode.none;
  final Set<String> _selectedEventIds = {};
  final Set<String> _selectedFileNames = {};
  String _conversationId = '';

  bool get _isWideLayout => MediaQuery.of(context).size.width >= 1100;

  EdgeInsets get _pagePadding => EdgeInsets.fromLTRB(
    _isWideLayout ? 24 : 12,
    _isWideLayout ? 24 : 12,
    _isWideLayout ? 24 : 12,
    24,
  );

  double _selectionPanelWidth(double availableWidth) {
    if (availableWidth >= 1200) return (availableWidth - 20) / 2;
    if (availableWidth >= 720) return math.min(560, availableWidth);
    return availableWidth;
  }

  double _groupCardWidth(double availableWidth) {
    if (availableWidth >= 1080) return (availableWidth - 24) / 3;
    if (availableWidth >= 720) return (availableWidth - 12) / 2;
    return availableWidth;
  }

  double _resultCardWidth(double availableWidth) {
    if (availableWidth >= 920) return math.min(420, (availableWidth - 12) / 2);
    return availableWidth;
  }

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
        .where(
          (event) =>
              event.creator.id == userId ||
              event.members.any((m) => m.id == userId),
        )
        .toList()
      ..sort((a, b) {
        final aNext = a.days.isNotEmpty
            ? Formatter.calculateNextIso8601(a.iso8601startDateTime, a.days)
            : a.iso8601startDateTime;
        final bNext = b.days.isNotEmpty
            ? Formatter.calculateNextIso8601(b.iso8601startDateTime, b.days)
            : b.iso8601startDateTime;
        return aNext.compareTo(bNext);
      });
  }

  List<Event> get _selectedEvents => widget.eventController.events
      .where((event) => _selectedEventIds.contains(event.id))
      .toList();

  void _startGeneral() {
    _mode = _Mode.general;
    _conversationId = UniqueKey().toString();
    _messages
      ..clear()
      ..add(
        _ChatMessage(
          fromBot: true,
          text:
              'General mode. I answer schedule and group questions directly '
              'from the app, and use AI for open-ended questions.',
          suggestions: const [
            'What is happening today?',
            'Which groups are available?',
            'How many groups are there?',
          ],
        ),
      );
    setState(() {});
    _scrollToBottom();
  }

  void _startAi() {
    if (_selectedEventIds.isEmpty) return;
    _mode = _Mode.ai;
    _conversationId = UniqueKey().toString();
    _selectedFileNames.clear();
    for (final event in _selectedEvents) {
      event.controller.fetchEventEntities(event.id);
    }
    final names = _selectedEvents.map((event) => event.title).join(', ');
    _messages
      ..clear()
      ..add(
        _ChatMessage(
          fromBot: true,
          text:
              'AI chat for: $names. Ask questions about the PDF documents of '
              'these study groups. By default I use all documents; use the '
              'folder button to limit the selection.',
        ),
      );
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

  Future<void> _sendGeneral(String raw) async {
    final text = raw.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add(_ChatMessage(text: text, fromBot: false));
      _controller.clear();
    });

    final local = _tryLocalReply(text);
    if (local != null) {
      setState(() => _messages.add(local));
      _scrollToBottom();
      return;
    }

    setState(() => _messages.add(_ChatMessage(fromBot: true, loading: true)));
    _scrollToBottom();

    final token = await AppDI.instance.authService.getAccessToken();
    final result = await widget.aiService.chat(
      text,
      const [],
      const [],
      _conversationId,
      token,
    );

    if (!mounted) return;
    setState(() {
      _messages.removeWhere((message) => message.loading);
      if (result == null) {
        _messages.add(
          _ChatMessage(
            fromBot: true,
            text:
                'AI is currently unavailable. Is the backend running and is '
                'an AI model configured?',
          ),
        );
      } else {
        _messages.add(
          _ChatMessage(
            fromBot: true,
            text: result.answer.isEmpty
                ? 'I did not receive an answer for that.'
                : result.answer,
            notes: result.notes,
          ),
        );
      }
    });
    _scrollToBottom();
  }

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
      _conversationId,
      token,
    );

    if (!mounted) return;
    setState(() {
      _messages.removeWhere((message) => message.loading);
      if (result == null) {
        _messages.add(
          _ChatMessage(
            fromBot: true,
            text:
                'AI is currently unavailable. Is the backend running and is '
                'an AI model configured?',
          ),
        );
      } else {
        _messages.add(
          _ChatMessage(
            fromBot: true,
            text: result.answer.isEmpty
                ? 'I did not receive an answer for that.'
                : result.answer,
            notes: result.notes,
          ),
        );
      }
    });
    _scrollToBottom();
  }

  DateTime _nextStart(Event event) => event.days.isNotEmpty
      ? Formatter.iso8601StringToDateTime(
          Formatter.calculateNextIso8601(
            event.iso8601startDateTime,
            event.days,
          ),
        ).toLocal()
      : Formatter.iso8601StringToDateTime(event.iso8601startDateTime).toLocal();

  bool _isOnDay(Event event, DateTime day) {
    final target = DateTime(day.year, day.month, day.day);
    final start = Formatter.iso8601StringToDateTime(
      event.iso8601startDateTime,
    ).toLocal();
    final startDateOnly = DateTime(start.year, start.month, start.day);

    if (target.isBefore(startDateOnly)) {
      return false;
    }

    if (event.days.isEmpty) {
      return startDateOnly == target;
    }

    final dayCode = _weekdayCodeByInt[target.weekday];
    return dayCode != null && event.days.contains(dayCode);
  }

  _ChatMessage? _tryLocalReply(String input) {
    final q = input.toLowerCase();
    final events = widget.eventController.events;

    if (_containsAny(q, [
      'help',
      'what can you do',
      'functions',
      'hilfe',
      'was kannst du',
    ])) {
      return _ChatMessage(
        fromBot: true,
        text:
            'I can help in two ways:\n'
            '• I answer app-based questions directly, like "What is happening '
            'today?", "tomorrow", "Which groups are available?", or a topic '
            'such as "math".\n'
            '• I forward open-ended questions to the AI.\n'
            'For questions about group PDFs, switch modes at the top and open '
            'the AI chat for one or more study groups.',
      );
    }

    if (_containsAny(q, ['how many', 'count', 'wie viele', 'wieviele']) &&
        _containsAny(q, [
          'group',
          'groups',
          'study group',
          'gruppe',
          'lerngruppe',
          'event',
        ])) {
      return _ChatMessage(
        fromBot: true,
        text:
            'There ${events.length == 1 ? 'is' : 'are'} currently ${events.length} '
            'study group${events.length == 1 ? '' : 's'}.',
      );
    }

    if (_containsAny(q, [
          'running',
          'live',
          'active',
          'now',
          'läuft',
          'laeuft',
          'gerade',
        ]) &&
        _containsAny(q, [
          'group',
          'groups',
          'study group',
          'event',
          'gruppe',
          'lerngruppe',
          'treffen',
        ])) {
      final live = events
          .where((event) => Event.getStatus(event) == 'Ongoing')
          .toList();
      return _resultMessage(
        live,
        live.isEmpty
            ? 'No study group is running right now.'
            : 'Currently running study group${live.length == 1 ? '' : 's'}:',
      );
    }

    if (q.contains('today') || q.contains('heute')) {
      final today = DateTime.now();
      final list = events.where((event) => _isOnDay(event, today)).toList()
        ..sort((a, b) => _nextStart(a).compareTo(_nextStart(b)));
      return _resultMessage(
        list,
        list.isEmpty
            ? 'No study groups are scheduled for today.'
            : 'Scheduled for today:',
      );
    }

    if (q.contains('tomorrow') || q.contains('morgen')) {
      final tomorrow = DateTime.now().add(const Duration(days: 1));
      final list = events.where((event) => _isOnDay(event, tomorrow)).toList()
        ..sort((a, b) => _nextStart(a).compareTo(_nextStart(b)));
      return _resultMessage(
        list,
        list.isEmpty
            ? 'No study groups are scheduled for tomorrow.'
            : 'Scheduled for tomorrow:',
      );
    }

    if (_containsAny(q, [
      'all groups',
      'which groups',
      'group list',
      'overview',
      'alle gruppen',
      'welche gruppen',
    ])) {
      final list = List<Event>.from(events)
        ..sort((a, b) => _nextStart(a).compareTo(_nextStart(b)));
      return _resultMessage(
        list,
        list.isEmpty ? 'There are no study groups yet.' : 'All study groups:',
      );
    }

    final wordCount = q
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .length;
    if (wordCount <= 3) {
      final tokens = q
          .split(RegExp(r'\s+'))
          .where((token) => token.length > 2)
          .toList();
      final matches = events.where((event) {
        final haystack =
            '${event.title} ${event.location} ${event.tags.join(' ')}'
                .toLowerCase();
        return tokens.any(haystack.contains);
      }).toList()..sort((a, b) => _nextStart(a).compareTo(_nextStart(b)));
      if (matches.isNotEmpty) {
        return _resultMessage(matches, 'Here is what I found for "$input":');
      }
    }

    return null;
  }

  _ChatMessage _resultMessage(List<Event> events, String text) =>
      _ChatMessage(fromBot: true, text: text, results: events.take(8).toList());

  bool _containsAny(String text, List<String> needles) =>
      needles.any(text.contains);

  void _pruneSelectedFiles() {
    final allowed = _selectedEvents
        .expand((event) => event.filePreviews.map((file) => file.fileName))
        .toSet();
    _selectedFileNames.removeWhere((fileName) => !allowed.contains(fileName));
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final scheme = Theme.of(context).colorScheme;

    return Container(
      color: scheme.primaryContainer,
      child: _mode == _Mode.none ? _selectionView() : _chatView(),
    );
  }

  Widget _chatView() {
    return Padding(
      padding: _pagePadding,
      child: Column(
        children: [
          _contextBar(),
          const SizedBox(height: 12),
          Expanded(
            child: Material(
              elevation: 3,
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(24),
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(vertical: 16),
                itemCount: _messages.length,
                itemBuilder: (context, index) => _bubble(_messages[index]),
              ),
            ),
          ),
          const SizedBox(height: 12),
          _inputBar(),
        ],
      ),
    );
  }

  Widget _selectionView() {
    final scheme = Theme.of(context).colorScheme;
    final groups = _myGroups;

    return ListView(
      padding: _pagePadding,
      children: [
        Text('Assistant', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 8),
        Text(
          'Choose between quick app answers and document-aware AI chat for your study groups.',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final panelWidth = _selectionPanelWidth(constraints.maxWidth);
            return Wrap(
              spacing: 20,
              runSpacing: 20,
              children: [
                SizedBox(
                  width: panelWidth,
                  child: Material(
                    elevation: 3,
                    color: scheme.surface,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: scheme.secondaryContainer,
                                child: Icon(
                                  Icons.public,
                                  color: scheme.onSecondaryContainer,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'General assistant',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.titleMedium,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Search groups, check schedules, and escalate broader questions to AI.',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: scheme.onSurfaceVariant,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          FilledButton.icon(
                            onPressed: _startGeneral,
                            icon: const Icon(Icons.chevron_right),
                            label: const Text('Start general chat'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  width: panelWidth,
                  child: Material(
                    elevation: 3,
                    color: scheme.surface,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.auto_awesome,
                                size: 18,
                                color: scheme.primary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'AI for my study groups',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Select one or more groups and ask questions about their PDF documents.',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: scheme.onSurfaceVariant),
                          ),
                          const SizedBox(height: 12),
                          if (!widget.authController.isLoggedIn)
                            _hintCard(
                              scheme,
                              'Sign in to use AI with your study groups.',
                            )
                          else if (groups.isEmpty)
                            _hintCard(
                              scheme,
                              'You are not part of a study group yet. Join one to discuss its documents with AI.',
                            )
                          else ...[
                            LayoutBuilder(
                              builder: (context, innerConstraints) {
                                final groupCardWidth = _groupCardWidth(
                                  innerConstraints.maxWidth,
                                );
                                return Wrap(
                                  spacing: 12,
                                  runSpacing: 12,
                                  children: groups.map((event) {
                                    final selected = _selectedEventIds.contains(
                                      event.id,
                                    );
                                    return SizedBox(
                                      width: groupCardWidth,
                                      child: Card(
                                        margin: EdgeInsets.zero,
                                        elevation: selected ? 2 : 0,
                                        color: selected
                                            ? scheme.secondaryContainer
                                                  .withValues(alpha: 0.45)
                                            : scheme.surface,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            18,
                                          ),
                                          side: BorderSide(
                                            color: selected
                                                ? scheme.primary
                                                : scheme.outlineVariant,
                                            width: selected ? 1.5 : 1,
                                          ),
                                        ),
                                        child: CheckboxListTile(
                                          value: selected,
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                horizontal: 12,
                                                vertical: 6,
                                              ),
                                          onChanged: (checked) => setState(() {
                                            if (checked == true) {
                                              _selectedEventIds.add(event.id);
                                            } else {
                                              _selectedEventIds.remove(
                                                event.id,
                                              );
                                            }
                                            _pruneSelectedFiles();
                                          }),
                                          title: Text(event.title),
                                          subtitle: Text(
                                            event.location,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          secondary: Chip(
                                            backgroundColor:
                                                scheme.primaryContainer,
                                            label: Text(
                                              Event.getStatus(event),
                                              style: TextStyle(
                                                color:
                                                    scheme.onPrimaryContainer,
                                              ),
                                            ),
                                            visualDensity:
                                                VisualDensity.compact,
                                          ),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                );
                              },
                            ),
                            const SizedBox(height: 12),
                            FilledButton.icon(
                              onPressed: _selectedEventIds.isEmpty
                                  ? null
                                  : _startAi,
                              icon: const Icon(Icons.auto_awesome),
                              label: Text(
                                _selectedEventIds.isEmpty
                                    ? 'Select group(s)'
                                    : 'Start AI chat (${_selectedEventIds.length})',
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
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

  Widget _contextBar() {
    final scheme = Theme.of(context).colorScheme;
    final isAi = _mode == _Mode.ai;
    final label = isAi
        ? 'AI · ${_selectedEventIds.length} group${_selectedEventIds.length == 1 ? '' : 's'}'
              '${_selectedFileNames.isEmpty ? '' : ' · ${_selectedFileNames.length} file(s)'}'
        : 'General mode';

    return Material(
      elevation: 3,
      color: scheme.surface,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
        child: Row(
          children: [
            Icon(
              isAi ? Icons.auto_awesome : Icons.public,
              size: 18,
              color: scheme.onSurfaceVariant,
            ),
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
                tooltip: 'Choose documents',
                icon: const Icon(Icons.folder_open, size: 20),
                onPressed: _openFilePicker,
              ),
            TextButton.icon(
              onPressed: _backToSelection,
              icon: const Icon(Icons.swap_horiz, size: 18),
              label: const Text('Switch'),
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
            final hasFiles = events.any(
              (event) => event.filePreviews.isNotEmpty,
            );
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Documents for AI',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Nothing selected means all PDFs from the chosen groups. Only PDF files are supported.',
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
                            'No documents found in the selected groups.',
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
                                  padding: const EdgeInsets.fromLTRB(
                                    4,
                                    10,
                                    4,
                                    2,
                                  ),
                                  child: Text(
                                    event.title,
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelLarge
                                        ?.copyWith(
                                          color: scheme.onSurfaceVariant,
                                        ),
                                  ),
                                ),
                              ...event.filePreviews.map((file) {
                                final isPdf = file.fileName
                                    .toLowerCase()
                                    .endsWith('.pdf');
                                final selected = _selectedFileNames.contains(
                                  file.fileName,
                                );
                                return CheckboxListTile(
                                  dense: true,
                                  value: selected,
                                  onChanged: isPdf
                                      ? (checked) {
                                          setSheetState(() {});
                                          setState(() {
                                            if (checked == true) {
                                              _selectedFileNames.add(
                                                file.fileName,
                                              );
                                            } else {
                                              _selectedFileNames.remove(
                                                file.fileName,
                                              );
                                            }
                                          });
                                        }
                                      : null,
                                  title: Text(file.fileName),
                                  subtitle: isPdf
                                      ? null
                                      : const Text(
                                          'Not a PDF - cannot be used',
                                        ),
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
                          child: const Text('Clear selection'),
                        ),
                        const Spacer(),
                        FilledButton(
                          onPressed: () => Navigator.of(sheetContext).pop(),
                          child: const Text('Done'),
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
    final maxBubbleWidth = isBot
        ? math.min(MediaQuery.of(context).size.width * 0.95, 1120.0)
        : math.min(MediaQuery.of(context).size.width * 0.82, 720.0);

    return Align(
      alignment: isBot ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        constraints: BoxConstraints(maxWidth: maxBubbleWidth),
        margin: EdgeInsets.fromLTRB(isBot ? 12 : 48, 4, isBot ? 48 : 12, 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isBot
              ? scheme.surfaceContainerHighest
              : scheme.secondaryContainer,
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
                  Text(
                    'Thinking ...',
                    style: TextStyle(color: scheme.onSurfaceVariant),
                  ),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.text,
                    style: TextStyle(
                      color: isBot
                          ? scheme.onSurface
                          : scheme.onPrimaryContainer,
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
                          Icon(
                            Icons.info_outline,
                            size: 16,
                            color: scheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              message.notes,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: scheme.onSurfaceVariant),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (message.results.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final resultCardWidth = _resultCardWidth(
                          constraints.maxWidth,
                        );
                        return Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: message.results
                              .map(
                                (event) => SizedBox(
                                  width: resultCardWidth,
                                  child: _resultTile(event, scheme),
                                ),
                              )
                              .toList(),
                        );
                      },
                    ),
                  ],
                  if (message.suggestions.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: message.suggestions
                          .map(
                            (suggestion) => ActionChip(
                              label: Text(suggestion),
                              onPressed: () => _dispatchSend(suggestion),
                            ),
                          )
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
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () =>
            eventPopup(context, event, () => _openCreateEventForm(context)),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          event.title,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${event.location} · ${Formatter.deserialiseDateTime(event.days.isNotEmpty ? Formatter.calculateNextIso8601(event.iso8601startDateTime, event.days) : event.iso8601startDateTime).date}',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Chip(
                    backgroundColor: scheme.primaryContainer,
                    label: Text(
                      Event.getStatus(event),
                      style: TextStyle(color: scheme.onPrimaryContainer),
                    ),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
              if (event.tags.isNotEmpty) ...[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: event.tags
                      .map(
                        (tag) => Chip(
                          label: Text(tag),
                          visualDensity: VisualDensity.compact,
                          side: BorderSide.none,
                          backgroundColor: scheme.surfaceContainerHighest,
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

  void _openCreateEventForm(BuildContext context, {bool draftReset = false}) {
    createEventForm(
      context,
      () async => null,
      widget.eventController.events,
      draftReset,
      hasNoMap: true,
    );
  }

  Widget _inputBar() {
    final scheme = Theme.of(context).colorScheme;
    return SafeArea(
      top: false,
      child: Material(
        elevation: 3,
        color: scheme.surface,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  textInputAction: TextInputAction.send,
                  onSubmitted: _dispatchSend,
                  decoration: InputDecoration(
                    hintText: _mode == _Mode.ai
                        ? 'Ask about the selected documents ...'
                        : 'Ask the assistant ...',
                    filled: true,
                    fillColor: scheme.surfaceContainerHighest,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 0,
                    ),
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
      ),
    );
  }
}
