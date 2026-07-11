
import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class SseConnectionService {
  final String _baseUrl;
  http.Client client = http.Client();

  int _connectionAttempts = 0;

  bool _connect = true;

  final _connectionController = StreamController<bool>.broadcast();
  Stream<bool> get connectionStream => _connectionController.stream;

  SseConnectionService(
    this._baseUrl
  );

  void dispose() {
    _connect = false;
    client.close();
  }

  Stream<Map<String, dynamic>> connectToServer() async* {
    final url = Uri.parse('$_baseUrl/sse');
    _connectionAttempts = 0;
    _connect = true;
    client = http.Client();

    while(_connect) {
      await Future.delayed(Duration(seconds: _connectionAttempts == 0 ? 0 : min(30, pow(2, _connectionAttempts).toInt())));
      try {
        final request = http.Request('GET', url);
        request.headers['Accept'] = 'text/event-stream';
        request.headers['Cache-Control'] = 'no-cache';

        final response = await client.send(request);

        if (response.statusCode != 200) {
          debugPrint('Failed to connect to SSE server: ${response.statusCode}');
          _connectionController.add(false);
          _connectionAttempts++;
        }
        else {
          debugPrint('Connected to SSE server');
          _connectionController.add(true);
          _connectionAttempts = 0;

          final lines = response.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter());

          String? eventType;
          final dataBuffer = StringBuffer();

          await for (final line in lines) {
            if (line.startsWith('event:')) {
              eventType = line.substring(6).trim();
            } 
            else if (line.startsWith('data:')) {
              dataBuffer.writeln(
                line.substring(5).trimLeft(),
              );
            } 
            else if (line.isEmpty) {
              if (eventType != null && dataBuffer.isNotEmpty) {
                final dto = jsonDecode(
                  dataBuffer.toString(),
                ) as Map<String, dynamic>;

                yield {
                  'event': eventType,
                  'dto': dto,
                };
              }

              eventType = null;
              dataBuffer.clear();
            }
          }
        }
        debugPrint('SSE connection closed by server');
        _connectionController.add(false);
        _connectionAttempts++;
      } 
      catch (e) {
        debugPrint('Error connecting to SSE server: $e');
        _connectionController.add(false);
        _connectionAttempts++;
      }
    }
  }
}