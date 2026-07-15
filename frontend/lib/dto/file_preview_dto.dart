
class FilePreviewDTO {
  final String id;
  final String originalFileName;
  final String savedFileName;
  final int size;
  final String createdAt;

  FilePreviewDTO({
    required this.id,
    required this.originalFileName,
    required this.savedFileName,
    required this.size,
    required this.createdAt,
  });

  static FilePreviewDTO fromJson(Map<String, dynamic> json) {
    return FilePreviewDTO(
      id: json['id'],
      originalFileName: json['originalFileName'],
      savedFileName: json['savedFileName'],
      size: json['size'],
      createdAt: json['createdAt'],
    );
  }
}