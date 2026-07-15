
import 'package:frontend/dto/file_preview_dto.dart';

class FilePreview {
  final String _id;
  String get id => _id;

  final String _fileName;
  String get fileName => _fileName;

  final int _size;
  int get size => _size;

  final String _createdAt;
  String get createdAt => _createdAt;

  FilePreview(FilePreviewDTO dto)
  : _id = dto.id,
    _fileName = dto.originalFileName,
    _size = dto.size,
    _createdAt = dto.createdAt;
}