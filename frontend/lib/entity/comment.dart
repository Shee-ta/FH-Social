
import 'package:frontend/dto/comment_dto.dart';
import 'package:frontend/entity/user.dart';

class Comment {

  final String _id;
  String get id => _id;

  final User _creator;
  User get creator => _creator;

  final String _content;
  String get content => _content;

  final String _createdAt;
  String get createdAt => _createdAt;

  final String _editedAt;
  String get editedAt => _editedAt;

  Comment(CommentDTO dto) 
  : _id = dto.id!,
    _creator = User(dto.creator!),
    _content = dto.content,
    _createdAt = dto.createdAt!,
    _editedAt = dto.editedAt!;
}