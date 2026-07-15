
import 'dart:convert';
import 'package:file_saver/file_saver.dart';
import 'package:flutter/foundation.dart';

import 'package:frontend/dto/file_preview_dto.dart';
import 'package:frontend/services/connection_services/http_retry.dart';
import 'package:frontend/services/ui_feedback_service.dart';
import 'package:http/http.dart' as http;

class FileService {

  String _baseUrl;

  FileService(
    this._baseUrl
  );

  void setBaseUrl(String baseUrl) {
    _baseUrl = baseUrl;
  }

  Future<bool> uploadFile(http.MultipartFile file, String eventId, String? accessToken) async {

    if (accessToken == null || accessToken.isEmpty) {
      return false;
    }

    final url = Uri.parse('$_baseUrl/upload/file');

    final request = http.MultipartRequest('POST', url);
    request.headers['Authorization'] = 'Bearer $accessToken';
    request.files.add(file);
    request.fields['eventIdStr'] = eventId;

    try {
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        debugPrint('Error uploading file: ${response.body}');
        return false;
      }
      return true;
    } catch (error) {
      debugPrint('Error during file upload: $error');
      return false;
    }
  }

  Future<bool> deleteFile(String fileId, String? accessToken) async {

    if (accessToken == null || accessToken.isEmpty) {
      return false;
    }

    final url = Uri.parse('$_baseUrl/delete/file').replace(
      queryParameters: {'fileIdStr': fileId}
    );
    final response = await retryHttpRequest(() {
      return http.post(
        url,
        headers: {'Authorization': 'Bearer $accessToken'},
      );
    });

    return response.statusCode >= 200 && response.statusCode < 300;
  }

  Future<List<FilePreviewDTO>> fetchEventFilePreviews(String eventId) async {

    final url = Uri.parse('$_baseUrl/file/previews/by-event').replace(
      queryParameters: {'eventIdStr': eventId}
    );

    final response = await retryHttpRequest(() => http.get(url), retryOnFailure: true);

    return response.statusCode >= 200 && response.statusCode < 300 
    ? (jsonDecode(response.body) as List)
      .map((f) => FilePreviewDTO.fromJson(f))
      .toList()
    : [];
  }

  Future<bool> downloadFile(String fileId, String fileName, String? accessToken) async {
    if (accessToken == null || accessToken.isEmpty) {
      return false;
    }

    final uri = Uri.parse('$_baseUrl/file/download').replace(
      queryParameters: {'fileIdStr': fileId},
    );

    final response = await retryHttpRequest(() {
      return http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $accessToken',
        },
      );
    });

    if (response.statusCode < 200 || response.statusCode >= 300) {
      return false;
    }

    debugPrint(response.statusCode.toString());
    debugPrint(response.headers['content-type']);
    debugPrint(response.bodyBytes.length.toString());
    try {
      final savedPath = await FileSaver.instance.saveAs(
        name: fileName,
        bytes: response.bodyBytes,
        mimeType: MimeType.custom,
        customMimeType: response.headers['content-type'] ?? 'application/octet-stream',
      );
      if (savedPath == null || savedPath.isEmpty) {
        UIfeedbackService.notification(
          message: 'Datei konnte nicht gespeichert werden.',
          type: NotificationType.error,
        );
        return false;
      }
      debugPrint('File saved to: $savedPath');
      UIfeedbackService.notification(
        message: 'Datei erfolgreich heruntergeladen.',
        type: NotificationType.success,
      );
      return true;
    } catch (e, s) {
      UIfeedbackService.notification(
      message: "Datei konnte nicht heruntergeladen werden.",
      type: NotificationType.error);
      debugPrint(e.toString());
      debugPrint(s.toString());
      return false;
    }
  }
}