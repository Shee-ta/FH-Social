
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:frontend/controller/event_controller.dart';
import 'package:frontend/di/app_di.dart';
import 'package:frontend/dto/event_dto.dart';
import 'package:frontend/dto/sse_dto/id_dto.dart';
import 'package:frontend/dto/sse_dto/id_with_comment_dto.dart';
import 'package:frontend/dto/sse_dto/id_with_event_id_dto.dart';
import 'package:frontend/dto/sse_dto/id_with_file_preview_dto.dart';
import 'package:frontend/dto/sse_dto/id_with_user_dto.dart';
import 'package:frontend/enums/sse_type.dart';
import 'package:frontend/services/connection_services/sse_connection_service.dart';

class SseListenerService {
  final EventController eventController;

  late final SseConnectionService sse;
  StreamSubscription<Map<String, dynamic>>? _subscription;

  SseListenerService() 
  : eventController = AppDI.instance.eventController,
    sse = AppDI.instance.sseConnectionService;

  StreamSubscription<bool>? _connectionSubscription;

  void listenConnectionEstablished() {
    _connectionSubscription = sse.connectionStream.listen((connected) {
      if(connected) {
        eventController.fetchAll();
      }
    });
  }

  Future<void> stopListening() async {
    sse.dispose();
    await _connectionSubscription?.cancel();
    await _subscription?.cancel();
    _subscription = null;
  }

  Future<void> startListening() async {
    if(_subscription != null) {
      return;
    }
    _subscription = sse.connectToServer().listen(
      _handleEvent,
      onError: (Object error, StackTrace stackTrace) {
        debugPrint('Error in SSE stream: $error');
      },
      onDone: () {
        debugPrint('SSE stream closed');
      },
    );
    listenConnectionEstablished();
  }

  void _handleEvent(Map<String, dynamic> event) {

    final type = SseType.parse(event['event']);

    switch (type) {
      case SseType.addEvent:
        eventController.addEvent(EventDTO.fromJson(event['dto']));
        break;
      case SseType.removeEvent:
        eventController.removeEvent(IdDTO.fromJson(event['dto']));
        break;
      case SseType.addMember:
        eventController.addMemberToEvent(IdWithUserDTO.fromJson(event['dto']));
        break;
      case SseType.removeMember:
        eventController.removeMemberFromEvent(IdWithEventIdDTO.fromJson(event['dto']));
        break;
      case SseType.addComment:
        eventController.addCommentToEvent(IdWithCommentDTO.fromJson(event['dto']));
        break;
      case SseType.removeComment:
        eventController.removeCommentFromEvent(IdWithEventIdDTO.fromJson(event['dto']));
        break;
      case SseType.addFilePreview:
        eventController.addFilePreviewToEvent(IdWithFilePreviewDTO.fromJson(event['dto']));
        break;
      case SseType.removeFilePreview:
        eventController.removeFilePreviewFromEvent(IdWithEventIdDTO.fromJson(event['dto']));
        break;
      default:
        break;
    }
  }
}