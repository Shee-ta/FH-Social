
import 'package:flutter/material.dart';
import 'package:frontend/UI/constants.dart';
import 'package:frontend/di/app_di.dart';
import 'package:frontend/dto/comment_dto.dart';
import 'package:frontend/entity/event.dart';
import 'package:frontend/services/settings_service.dart';

class CommentDraft {
  Event event;
  String text = '';

  CommentDraft({
    required this.event,
    this.text = '',
  });
}

String a = '';

class EventPopupCommentInput extends StatelessWidget {
  EventPopupCommentInput({
    super.key,
    required this.event,
    required this.commentDrafts,
    required this.commentController,
    required this.setCommentDraft,
  })
  : settingsService = AppDI.instance.settingsService;

  final Event event;
  final List<CommentDraft> commentDrafts;
  final TextEditingController commentController;
  final SettingsService settingsService;
  final void Function(String value) setCommentDraft;

  CommentDraft? getCommentDraft() {
    for(final draft in commentDrafts) {
      if(event.id == draft.event.id) {
        return draft;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      child: ListenableBuilder(
        listenable: event.controller,
        builder: (context, _) => Column(
          children: [
            TextField(
              controller: commentController,
              maxLines: null,
              onChanged: (value) => setCommentDraft(value),
              decoration: const InputDecoration(
                labelText: 'Add a comment',
              ),
            ),
            Const.spacing,
            Row(children: [
              ElevatedButton(
                style: settingsService.positiveButtonStyle(context),
                onPressed: commentController.text.trim().isEmpty ? null : () async {
                  CommentDTO comment = CommentDTO(
                    eventId: event.id,
                    content: commentController.text.trim(),
                  );
                  event.controller.uploadComment(comment).then((success) {
                    if(success) {
                      setCommentDraft('');
                      commentController.clear();
                    }
                  });
                }, 
                child: event.controller.isUploadingComment 
                ? const CircularProgressIndicator() 
                : Row(
                    spacing: 8,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (settingsService.iconButtonsActive) ...[
                        const Icon(Icons.send),
                      ],
                      const Text('Submit')
                    ],
                  ),
              ),
              Const.spacing,
              ElevatedButton(
                style: settingsService.negativeButtonStyle(context),
                onPressed: commentController.text.trim().isEmpty ? null : () {
                  setCommentDraft('');
                  commentController.clear();
                }, 
                child: Row(
                  spacing: 8,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (settingsService.iconButtonsActive) ...[
                      const Icon(Icons.clear),
                    ],
                    const Text('Clear')
                  ],
                ),
              ),
            ],
            )
          ],
        ),
      ),
    );
  }
}