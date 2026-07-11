
import 'package:frontend/dto/comment_dto.dart';

class IdWithCommentDTO {
  final String eventId;
  final CommentDTO comment;

  IdWithCommentDTO({
    required this.eventId,
    required this.comment,
  });

  static IdWithCommentDTO fromJson(Map<String, dynamic> json) {
    return IdWithCommentDTO(
      eventId: json['eventId'],
      comment: CommentDTO.fromJson(json['comment']),
    );
  }
}