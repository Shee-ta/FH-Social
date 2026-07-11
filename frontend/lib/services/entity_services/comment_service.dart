import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:frontend/dto/comment_dto.dart';
import 'package:frontend/services/connection_services/http_retry.dart';
import 'package:http/http.dart' as http;

class CommentService {

  final String _baseUrl;

  CommentService(
    this._baseUrl
  );

  Future<bool> uploadComment(CommentDTO comment, String? accessToken) async {
    
    if (accessToken == null || accessToken.isEmpty) {
      return false;
    }

    try {
      final url = Uri.parse('$_baseUrl/upload/comment');
    
      final payload = {
        'id': comment.id,
        'eventId': comment.eventId,
        'content': comment.content,
      };

      final response = await retryHttpRequest(() {
        return http.post(
          url,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $accessToken',
          },
          body: jsonEncode(payload),
        );
      });
      return response.statusCode >= 200 && response.statusCode < 300;
    } 
    catch (error) {
      debugPrint('Error sending comment: $error');
      return false;
    } 
  }

  Future<bool> deleteComment(String eventId, String commentId, String? accessToken) async {
    
    if (accessToken == null || accessToken.isEmpty) {
      return false;
    }

    try {
      final url = Uri.parse('$_baseUrl/delete/comment').replace(
        queryParameters: {'eventIdStr': eventId, 'commentIdStr': commentId}
      );

      final response = await retryHttpRequest(() {
        return http.post(
          url,
          headers: {
            'Authorization': 'Bearer $accessToken',
          },
        );
      });
      return response.statusCode >= 200 && response.statusCode < 300;
    } 
    catch (error) {
      debugPrint('Error deleting comment: $error');
      return false;
    } 
  }

  Future<List<CommentDTO>> fetchEventComments(String eventId) async {

    final url = Uri.parse('$_baseUrl/comments/by-event').replace(
      queryParameters: {'eventIdStr': eventId}
    );

    final response = await retryHttpRequest(() => http.get(url), retryOnFailure: true);

    return response.statusCode >= 200 && response.statusCode < 300
    ? (jsonDecode(response.body) as List)
        .map((json) => CommentDTO.fromJson(json))
        .toList()
    : [];
  }

  Future<CommentDTO?> fetchCommentById(String eventId, String commentId) async {
    final url = Uri.parse('$_baseUrl/comments/by-id').replace(
      queryParameters: {'eventIdStr': eventId, 'commentIdStr': commentId}
    );
    final response = await retryHttpRequest(() => http.get(url), retryOnFailure: true);

    return response.statusCode >= 200 && response.statusCode < 300
        ? CommentDTO.fromJson(jsonDecode(response.body))
        : null;
  }
}
