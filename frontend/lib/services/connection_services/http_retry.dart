import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

bool _isSuccess(int statusCode) => statusCode >= 200 && statusCode < 300;

Future<http.Response> retryHttpRequest(
  Future<http.Response> Function() request,
  { int timeoutSeconds = 5,
    bool retryOnFailure = false }
) async {
  late http.Response response;
  int connectionAttempts = 0;
  while (true) {
    try {
      response = await request().timeout(Duration(seconds: timeoutSeconds),
      onTimeout: () => http.Response('Request timed out', 408));

      if (_isSuccess(response.statusCode)) {
        return response;
      }

      debugPrint('Request failed (${response.statusCode}): ${response.body}'); 

      if (!retryOnFailure) {
        return response;
      }
      
    }
    catch (error) {
      debugPrint('Error during HTTP request: $error');

      if (!retryOnFailure) {
        return http.Response(error.toString(), 500);
      }
    }
    connectionAttempts++;
    await Future.delayed(Duration(seconds: connectionAttempts == 0 ? 0 : min(30, pow(2, connectionAttempts).toInt())));
  }
}
