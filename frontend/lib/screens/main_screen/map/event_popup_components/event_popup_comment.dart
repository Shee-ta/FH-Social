import 'package:flutter/material.dart';
import 'package:frontend/UI/formatter.dart';
import 'package:frontend/controller/auth_controller.dart';
import 'package:frontend/di/app_di.dart';
import 'package:frontend/dto/comment_dto.dart';
import 'package:frontend/entity/comment.dart';
import 'package:frontend/entity/event.dart';
import 'package:frontend/services/settings_service.dart';

class EventPopupComment extends StatefulWidget {
  EventPopupComment({
    super.key,
    required this.comment,
    required this.event,
  })
      : authController = AppDI.instance.authController,
        settingsService = AppDI.instance.settingsService;

  final Comment comment;
  final Event event;
  final AuthController authController;
  final SettingsService settingsService;

  @override
  State<EventPopupComment> createState() => _EventPopupCommentState();
}

class _EventPopupCommentState extends State<EventPopupComment> {
  late final TextEditingController _editController;
  late final FocusNode _focusNode;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _editController = TextEditingController(text: widget.comment.content);
    _focusNode = FocusNode();
  }

  @override
  void didUpdateWidget(covariant EventPopupComment oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.comment.id != widget.comment.id) {
      _editController.text = widget.comment.content;
      _isEditing = false;
    }
  }

  @override
  void dispose() {
    _editController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _startEditing() {
    setState(() {
      _isEditing = true;
      _editController.text = widget.comment.content;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _focusNode.requestFocus();
      }
    });
  }

  void _cancelEditing() {
    setState(() {
      _isEditing = false;
      _editController.text = widget.comment.content;
    });
  }

  Future<void> _saveEditedComment() async {
    final commentDTO = CommentDTO(
      id: widget.comment.id,
      eventId: widget.event.id,
      content: _editController.text.trim(),
    );
    final success = await widget.event.controller.uploadComment(commentDTO, isEditing: true);
    if (success && mounted) {
      setState(() {
        _isEditing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final comment = widget.comment;
    final bool isEdited = DateTime.parse(comment.editedAt)
        .subtract(const Duration(seconds: 1))
        .isAfter(DateTime.parse(comment.createdAt));
    final dateTime = Formatter.deserialiseDateTime(
      isEdited ? comment.editedAt : comment.createdAt,
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CircleAvatar(
            child: Icon(Icons.person),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  comment.creator.displayname.isEmpty
                      ? 'Unknown user'
                      : comment.creator.displayname,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                if (_isEditing) ...[
                  TextField(
                    controller: _editController,
                    focusNode: _focusNode,
                    autofocus: true,
                    maxLines: null,
                    onSubmitted: (_) async {
                      await _saveEditedComment();
                    },
                  ),
                ] else ...[
                  Text(comment.content),
                  const SizedBox(height: 4),
                  Text(
                    '${isEdited ? "Edited at: " : ""}${dateTime.date} ${dateTime.time}',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: 12,
                      color: DefaultTextStyle.of(context)
                          .style
                          .color
                          ?.withValues(alpha: 0.8),
                    ),
                  ),
                ],
                if (_isEditing) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      ElevatedButton(
                        style: widget.settingsService.negativeButtonStyle(context),
                        onPressed: _cancelEditing,
                        child: Row(
                          spacing: 8,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (widget.settingsService.iconButtonsActive) ...[
                              const Icon(Icons.cancel),
                            ],
                            const Text('Cancel'),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        style: widget.settingsService.positiveButtonStyle(context),
                        onPressed: _saveEditedComment,
                        child: widget.event.controller.isUploadingEditedComment
                            ? const SizedBox(
                                height: 16,
                                width: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Row(
                                spacing: 8,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  if (widget.settingsService.iconButtonsActive) ...[
                                    const Icon(Icons.check),
                                  ],
                                  const Text('Save'),
                                ],
                              ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          if (widget.authController.userId == comment.creator.id && !_isEditing) ...[
            const SizedBox(width: 8),
            PopupMenuButton<String>(
              tooltip: 'Show comment options',
              color: Theme.of(context).colorScheme.primaryContainer,
              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                PopupMenuItem<String>(
                  value: 'edit',
                  child: Row(
                    spacing: 8,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (widget.settingsService.iconButtonsActive) ...[
                        const Icon(Icons.edit),
                      ],
                      const Text('Edit'),
                    ],
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'delete',
                  child: Row(
                    spacing: 8,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (widget.settingsService.iconButtonsActive) ...[
                        const Icon(Icons.delete),
                      ],
                      const Text('Delete'),
                    ],
                  ),
                ),
              ],
              child: Icon(
                Icons.more_vert,
                color: DefaultTextStyle.of(context).style.color?.withValues(alpha: 0.8),
              ),
              onSelected: (String value) {
                if (value == 'edit') {
                  _startEditing();
                } else if (value == 'delete') {
                  widget.event.controller.deleteComment(widget.event.id, widget.comment.id);
                }
              },
            ),
          ],
        ],
      ),
    );
  }
}
