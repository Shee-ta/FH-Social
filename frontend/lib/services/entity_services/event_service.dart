import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:frontend/dto/event_dto.dart';
import 'package:frontend/services/connection_services/http_retry.dart';
import 'package:http/http.dart' as http;

class EventService {

  String _baseUrl;

  EventService(
    this._baseUrl
  );

  void setBaseUrl(String baseUrl) {
    _baseUrl = baseUrl;
  }

  Future<bool> uploadEvent(EventDTO event, String? accessToken) async {

    if (accessToken == null || accessToken.isEmpty) {
      return false;
    }

    try {
      final url = Uri.parse('$_baseUrl/upload/event');
    
      final payload = {
        'id': event.id,
        'title': event.title,
        'iso8601startDateTime': event.iso8601startDateTime,
        'iso8601endDateTime': event.iso8601endDateTime,
        'location': event.location,
        'description': event.description,
        'recommendation': event.recommendation,
        'latitude': event.latitude,
        'longitude': event.longitude,
        'days': event.days,
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
      debugPrint('Error sending event: $error');
      return false;
    } 
  }

  Future<bool> deleteEvent(String eventId, String? accessToken) async {

    if (accessToken == null || accessToken.isEmpty) {
      return false;
    }

    try {
      final url = Uri.parse('$_baseUrl/delete/event').replace(
        queryParameters: {'eventIdStr': eventId},
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
      debugPrint('Error deleting event: $error');
      return false;
    } 
  }

  Future<List<EventDTO>> getEventsAll() async {
    final url = Uri.parse('$_baseUrl/events/all');
    final response = await retryHttpRequest(() => http.get(url), retryOnFailure: true);

    return response.statusCode >= 200 && response.statusCode < 300 
    ? (jsonDecode(response.body) as List)
      .map((e) => EventDTO.fromJson(e))
      .toList()
    : [];
  }

  Future<EventDTO?> getEventById(String eventId) async {
    final url = Uri.parse('$_baseUrl/events/by-id').replace(
      queryParameters: {'eventIdStr': eventId},
    );
    
    final response = await retryHttpRequest(() => http.get(url), retryOnFailure: true);

    return response.statusCode >= 200 && response.statusCode < 300
        ? EventDTO.fromJson(jsonDecode(response.body))
        : null;
  }
}
