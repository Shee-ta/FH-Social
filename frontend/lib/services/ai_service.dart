
import 'dart:async';
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