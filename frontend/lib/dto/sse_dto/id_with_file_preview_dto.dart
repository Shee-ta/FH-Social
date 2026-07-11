
import 'package:frontend/dto/file_preview_dto.dart';

class IdWithFilePreviewDTO {
  final String eventId;
  final FilePreviewDTO filePreview;

  IdWithFilePreviewDTO({
    required this.eventId,
    required this.filePreview,
  });

  static IdWithFilePreviewDTO fromJson(Map<String, dynamic> json) {
    return IdWithFilePreviewDTO(
      eventId: json['eventId'],
      filePreview: FilePreviewDTO.fromJson(json['filePreview']),
    );
  }
}