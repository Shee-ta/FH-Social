
import 'package:frontend/dto/user_dto.dart';

class CommentDTO {
  final String? id;
  final String eventId;
  final UserDTO? creator;
  final String content;
  final String? createdAt;
  final String? editedAt;

  CommentDTO({
    this.id,
    required this.eventId,
    this.creator,
    required this.content,
    this.createdAt,
    this.editedAt,
  });

  static CommentDTO fromJson(Map<String, dynamic> json) {
    return CommentDTO(
      id: json['id'],
      eventId: json['eventId'],
      creator: UserDTO.fromJson(json['creator']),
      content: json['content'],
      createdAt: json['createdAt'],
      editedAt: json['editedAt'],
    );
  }
}