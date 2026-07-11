
import 'package:flutter/material.dart';
import 'package:frontend/entity/comment.dart';
import 'package:frontend/entity/event.dart';
import 'package:frontend/screens/main_screen/map/event_popup_components/event_popup_comment.dart';

class EventPopupCommentList extends StatelessWidget {
  final List<Comment> comments;

  const EventPopupCommentList({
    super.key,
    required this.comments,
    required this.event,
  });

  final Event event;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: comments.map((comment) {
          return EventPopupComment(comment: comment, event: event);
        }).toList(),
      ),
    );
  }
}