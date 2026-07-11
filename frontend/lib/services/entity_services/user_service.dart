
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:frontend/dto/change_member_dto.dart';
import 'package:frontend/dto/user_dto.dart';
import 'package:frontend/services/connection_services/http_retry.dart';
import 'package:http/http.dart' as http;

class UserService {

  String _baseUrl;

  UserService(
    this._baseUrl
  );

  void setBaseUrl(String baseUrl) {
    _baseUrl = baseUrl;
  }

  Future<bool> uploadUser(UserDTO user, String? accessToken) async {

    if (accessToken == null || accessToken.isEmpty) {
      return false;
    }

    try {
      final url = Uri.parse('$_baseUrl/upload/user');
    
      final payload = {
        'id': user.id,
        'username': user.username,
        'displayname': user.displayname,
        'role': user.role,
      };

      await retryHttpRequest(() {
        return http.post(
          url,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $accessToken',
          },
          body: jsonEncode(payload),
        );
      });
      return true;
    } 
    catch (error) {
      debugPrint('Error sending user: $error');
      return false;
    } 
    finally {
    }
  }

  Future<bool> changeEventMembership(ChangeMemberDTO changeMemberRequest, String? accessToken) async {

    if (accessToken == null || accessToken.isEmpty) {
      return false;
    }

    try {
      final url = Uri.parse('$_baseUrl/upload/user/member-change');
    
      final payload = {
        'eventId': changeMemberRequest.eventId,
        'isAdded': changeMemberRequest.isAdded,
      };

      await retryHttpRequest(() {
        return http.post(
          url,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $accessToken',
          },
          body: jsonEncode(payload),
        );
      });
      return true;
    } 
    catch (error) {
      debugPrint('Error changing member status: $error');
      return false;
    } 
    finally {
    }
  }

  Future<List<UserDTO>> fetchEventMembers(String eventId) async {

    final url = Uri.parse('$_baseUrl/users/by-event').replace(
      queryParameters: {'eventIdStr': eventId},
    );

    final response = await retryHttpRequest(() => http.get(url), retryOnFailure: true);

    return (jsonDecode(response.body) as List)
    .map((e) => UserDTO.fromJson(e))
    .toList();
  }

  Future<UserDTO?> fetchUserById(String userId) async {
    final url = Uri.parse('$_baseUrl/users/by-id').replace(
      queryParameters: {'userIdStr': userId},
    );
    final response = await retryHttpRequest(() => http.get(url));

    return UserDTO.fromJson(jsonDecode(response.body));
  }
}