
import 'package:flutter/material.dart';
import 'package:frontend/UI/formatter.dart';
import 'package:frontend/controller/auth_controller.dart';
import 'package:frontend/di/app_di.dart';
import 'package:frontend/dto/comment_dto.dart';
import 'package:frontend/entity/comment.dart';
import 'package:frontend/entity/event.dart';
import 'package:frontend/services/settings_service.dart';

class EventPopupComment extends StatelessWidget {
  EventPopupComment({
    super.key,
    required this.comment,
    required this.event,
  })
  : authController =  AppDI.instance.authController,
    settingsService = AppDI.instance.settingsService;

  final Comment comment;
  final Event event;
  final AuthController authController;
  final SettingsService settingsService;
  final TextEditingController _editController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    bool isEditing = false;
    bool isEdited = DateTime.parse(comment.editedAt).subtract(const Duration(seconds: 1)).isAfter(DateTime.parse(comment.createdAt));
    final dateTime = Formatter.deserialiseDateTime(isEdited ? comment.editedAt : comment.createdAt);
    return ListenableBuilder(
      listenable: _editController,
      builder: (context, _) {
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
                      comment.creator.displayname.isEmpty ? 'Unknown user' : comment.creator.displayname,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    if (isEditing) ...[
                      TextField(
                        controller: _editController,
                        maxLines: null,
                        autofocus: true,
                        onSubmitted: (value) {
                          isEditing = false;
                          final commentDTO = CommentDTO(
                            id: comment.id,
                            eventId: event.id,
                            content: value,
                          );
                          event.controller.uploadComment(commentDTO, isEditing: true);
                        },
                      )
                    ]
                    else ...[
                      Text(comment.content),
                      const SizedBox(height: 4),
                      Text(
                        '${isEdited ? "Edited at: " : ""}${dateTime.date} ${dateTime.time}',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontSize: 12,
                          color: DefaultTextStyle.of(context).style.color?.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                    if (isEditing) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          ElevatedButton(
                            style: settingsService.negativeButtonStyle(context),
                            onPressed: () {
                              isEditing = false;
                              _editController.clear();
                            },
                            child: Row(
                              spacing: 8,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (settingsService.iconButtonsActive) ...[
                                  const Icon(Icons.cancel),
                                ],
                                const Text('Cancel')
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            style: settingsService.positiveButtonStyle(context),
                            onPressed: () {
                              isEditing = false;
                              final commentDTO = CommentDTO(
                                id: comment.id,
                                eventId: event.id,
                                content: _editController.text,
                              );
                              event.controller.uploadComment(commentDTO, isEditing: true);
                            },
                            child: event.controller.isUploadingEditedComment 
                            ? const CircularProgressIndicator() 
                            : Row(
                                spacing: 8,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  if (settingsService.iconButtonsActive) ...[
                                    const Icon(Icons.check),
                                  ],
                                  const Text('Save')
                                ],
                              ),
                          ),
                        ],
                      )
                    ]
                  ],
                ),
              ),
              if(authController.userId == comment.creator.id && !isEditing) ...[
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
                          if (settingsService.iconButtonsActive) ...[
                            const Icon(Icons.edit),
                          ],
                          const Text('Edit')
                        ],
                      ),
                    ),
                    PopupMenuItem<String>(
                      value: 'delete',
                      child: Row(
                        spacing: 8,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (settingsService.iconButtonsActive) ...[
                            const Icon(Icons.delete),
                          ],
                          const Text('Delete')
                        ],
                      ),
                    ),
                  ],
                  child: Icon(Icons.more_vert, color: DefaultTextStyle.of(context).style.color?.withValues(alpha: 0.8)),
                  onSelected: (String value) {
                    if (value == 'edit') {
                      isEditing = true;
                      _editController.text = comment.content;  
                    } else if (value == 'delete') {
                      event.controller.deleteComment(event.id, comment.id);
                    }
                  },
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}