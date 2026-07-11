
import 'dart:core';

import 'package:frontend/dto/event_dto.dart';
import 'package:frontend/dto/sse_dto/id_dto.dart';
import 'package:frontend/dto/sse_dto/id_with_comment_dto.dart';
import 'package:frontend/dto/sse_dto/id_with_event_id_dto.dart';
import 'package:frontend/dto/sse_dto/id_with_file_preview_dto.dart';
import 'package:frontend/dto/sse_dto/id_with_user_dto.dart';
import 'package:frontend/di/app_di.dart';
import 'package:frontend/entity/comment.dart';
import 'package:frontend/entity/event.dart';
import 'package:flutter/foundation.dart';
import 'package:frontend/entity/file_preview.dart';
import 'package:frontend/entity/user.dart';
import 'package:frontend/services/ai_service.dart';
import 'package:frontend/services/auth_service.dart';
import 'package:frontend/services/entity_services/comment_service.dart';
import 'package:frontend/services/entity_services/event_service.dart';
import 'package:frontend/services/entity_services/file_service.dart';
import 'package:frontend/services/entity_services/user_service.dart';
import 'package:frontend/services/ui_feedback_service.dart';

class EventController extends ChangeNotifier {

  final AuthService authService;
  final EventService eventService;
  final UserService userService;
  final FileService fileService;
  final CommentService commentService;
  final AiService aiService;

  final List<Event> _events = [];
  List<Event> get events => _events;

  late List<List<Event>> _eventsGroupedByLocation = [];
  List<List<Event>> get eventsGroupedByLocation => _eventsGroupedByLocation;

  late final Map<String, int> _tags = {};
  Map<String, int> get tags => _tags;

  bool _isUploadingEvent = false;
  bool get isUploadingEvent => _isUploadingEvent;

  bool _isDeletingEvent = false;
  bool get isDeletingEvent => _isDeletingEvent;

  EventController()
  : authService = AppDI.instance.authService,
    eventService = AppDI.instance.eventService,
    userService = AppDI.instance.userService,
    fileService = AppDI.instance.fileService,
    commentService = AppDI.instance.commentService,
    aiService = AppDI.instance.aiService
  {
    fetchAll();
  }

  void fetchAll() async {
    final eventDTOs = await eventService.getEventsAll();

    for (final eventDTO in eventDTOs) {
      final index = _events.indexWhere((e) => e.id == eventDTO.id);
      if (index != -1) {
        _events[index].updateFromDTO(eventDTO);
        _events[index].controller.notifyListeners();
      } else {
        _events.add(Event(eventDTO));
      }
    }
    for (final event in _events) {
      if (!eventDTOs.any((dto) => dto.id == event.id)) {
        removeEvent(IdDTO(id: event.id));
      }
    }
    updateEvents();
    notifyListeners();
  }

  void setIsUploadingEvent(bool value) {
    _isUploadingEvent = value;
    notifyListeners();
  }

  void setIsDeletingEvent(bool value) {
    _isDeletingEvent = value;
    notifyListeners();
  }

  // --- USER ACTIONS --- //
  Future<bool> uploadEvent(EventDTO eventDTO) async {
    setIsUploadingEvent(true);

    final accessToken = await authService.getAccessToken();
    final success = await eventService.uploadEvent(eventDTO, accessToken);

    if(!success) {
      UIfeedbackService.notification(
        message: "Failed to upload event",
        type: NotificationType.error
      );
    }
    setIsUploadingEvent(false);
    return success;
  }

  Future<bool> deleteEvent(String eventId) async {
    setIsDeletingEvent(true);

    final accessToken = await authService.getAccessToken();
    final success = await eventService.deleteEvent(eventId, accessToken);
    if(!success) {
      UIfeedbackService.notification(
        message: "Failed to delete event",
        type: NotificationType.error
      );
    }
    setIsDeletingEvent(false);
    return success;
  }

  // --- EVENT ASSEMBLY --- //
  void updateEvents() {
    final Map<String, List<Event>> groupedEvents = {};
    for (final event in _events) {
      final key = '${event.latitude},${event.longitude}';
      if (!groupedEvents.containsKey(key)) {
        groupedEvents[key] = [];
      }
      groupedEvents[key]!.add(event);
    }
    _eventsGroupedByLocation = groupedEvents.values.toList();
    _tags.clear();
    for (final event in _events) {
      for (final tag in event.tags) {
        _tags[tag] = (_tags[tag] ?? 0) + 1;
      }
    }
  }

  // --- EVENT MANAGEMENT --- //
  void addEvent(EventDTO eventDTO) {
    final index = _events.indexWhere((e) => e.id == eventDTO.id);
    if (index != -1) {
      _events[index].updateFromDTO(eventDTO);
      _events[index].controller.notifyListeners();
    } else {
      final event = Event(eventDTO);
      _events.add(event);
    }
    updateEvents();
    notifyListeners();
  }

  void removeEvent(IdDTO idDTO) {
    final index = _events.indexWhere((e) => e.id == idDTO.id);
    if (index == -1) {
      return;
    }
    _events[index].controller.setEventDeleted();
    _events.removeWhere((e) => e.id == idDTO.id);
    updateEvents();
    notifyListeners();
  }

  void addMemberToEvent(IdWithUserDTO idWithUserDTO) {
    final index = _events.indexWhere((e) => e.id == idWithUserDTO.eventId);
    if (index == -1) {
      return;
    }
    _events[index].controller.addMember(User(idWithUserDTO.user));
    notifyListeners();
  }

  void removeMemberFromEvent(IdWithEventIdDTO idWithEventIdDTO) {
    final index = _events.indexWhere((e) => e.id == idWithEventIdDTO.eventId);
    if (index == -1) {
      return;
    }
    _events[index].controller.removeMember(idWithEventIdDTO.id);
    notifyListeners();
  }

  void addCommentToEvent(IdWithCommentDTO idWithCommentDTO) {
    final index = _events.indexWhere((e) => e.id == idWithCommentDTO.eventId);
    if (index == -1) {
      return;
    }
    _events[index].controller.addComment(Comment(idWithCommentDTO.comment));
    _events[index].comments.sort((a, b) => DateTime.parse(a.createdAt).compareTo(DateTime.parse(b.createdAt)));
    notifyListeners();
  }

  void removeCommentFromEvent(IdWithEventIdDTO idWithEventIdDTO) {
    final index = _events.indexWhere((e) => e.id == idWithEventIdDTO.eventId);
    if (index == -1) {
      return;
    }
    _events[index].controller.removeComment(idWithEventIdDTO.id);
    notifyListeners();
  }

  void addFilePreviewToEvent(IdWithFilePreviewDTO idWithFilePreviewDTO) {
    final index = _events.indexWhere((e) => e.id == idWithFilePreviewDTO.eventId);
    if (index == -1) {
      return;
    }
    _events[index].controller.addFilePreview(FilePreview(idWithFilePreviewDTO.filePreview));
    notifyListeners();
  }

  void removeFilePreviewFromEvent(IdWithEventIdDTO idWithEventIdDTO) {
    final index = _events.indexWhere((e) => e.id == idWithEventIdDTO.eventId);
    if (index == -1) {
      return;
    }
    _events[index].controller.removeFilePreview(idWithEventIdDTO.id);
    notifyListeners();
  }
}