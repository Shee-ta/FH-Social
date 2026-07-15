
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;


class AiService {

  String _baseUrl;

  AiService(
    this._baseUrl
  );

  void setBaseUrl(String baseUrl) {
    _baseUrl = baseUrl;
  }

  Future<bool> generateRecommendation(String eventId, String? accessToken) async {

    if (accessToken == null || accessToken.isEmpty) {
      return false;
    }

    final url = Uri.parse('$_baseUrl/ai/generate-recommendation').replace(
      queryParameters: {'eventIdStr': eventId}
    );

    try {
      final response = await http.post(
        url,
        headers: {'Authorization': 'Bearer $accessToken'},
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        debugPrint('Error generating recommendation: ${response.body}');
        return false;
      }
    } catch (error) {
      debugPrint('Error generating recommendation: $error');
      return false;
    }
    return true;
  }

  /// Free-form AI chat over the documents of the given events. Returns the answer
  /// and any backend notes (e.g. about missing or non-PDF files), or null on error.
  Future<({String answer, String notes})?> chat(
    String prompt,
    List<String> eventIds,
    List<String> fileNames,
    String? accessToken,
  ) async {
    final url = Uri.parse('$_baseUrl/ai/chat');

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          if (accessToken != null && accessToken.isNotEmpty)
            'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode({
          'prompt': prompt,
          'eventIds': eventIds,
          'fileNames': fileNames,
        }),
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        debugPrint('Error during AI chat: ${response.body}');
        return null;
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return (
        answer: (json['answer'] as String?) ?? '',
        notes: (json['notes'] as String?) ?? '',
      );
    } catch (error) {
      debugPrint('Error during AI chat: $error');
      return null;
    }
  }

  Future<bool> generateTags(String eventId, String? accessToken) async {

    if (accessToken == null || accessToken.isEmpty) {
      return false;
    }

    final url = Uri.parse('$_baseUrl/ai/generate-tags').replace(
      queryParameters: {'eventIdStr': eventId}
    );

    try {
      final response = await http.post(
        url,
        headers: {'Authorization': 'Bearer $accessToken'},
      );
      if (response.statusCode < 200 || response.statusCode >= 300) {
        debugPrint('Error generating tags: ${response.body}');
        return false;
      }
    } catch (error) {
      debugPrint('Error generating tags: $error');
      return false;
    }
    return true;
  }
}