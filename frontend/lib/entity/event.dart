
import 'package:flutter/material.dart';
import 'package:frontend/UI/formatter.dart';
import 'package:frontend/appComponents/locations.dart';
import 'package:frontend/controller/event_entities_controller.dart';
import 'package:frontend/dto/event_dto.dart';
import 'package:frontend/entity/comment.dart';
import 'package:frontend/entity/file_preview.dart';
import 'package:frontend/entity/user.dart';
import 'package:latlong2/latlong.dart';
class Event {

  late final EventEntitiesController _controller;
  EventEntitiesController get controller => _controller;

  final String _id;
  String get id => _id;

  User _creator;
  User get creator => _creator;

  String _title;
  String get title => _title;

  String _iso8601startDateTime;
  String get iso8601startDateTime => _iso8601startDateTime;

  String _iso8601endDateTime;
  String get iso8601endDateTime => _iso8601endDateTime;

  String _date;
  String get date => _date;

  String _location;
  String get location => _location;

  String _description;
  String get description => _description;

  String _recommendation;
  String get recommendation => _recommendation;

  double _latitude;
  double get latitude => _latitude;

  double _longitude;
  double get longitude => _longitude;

  final List<String> _days;
  List<String> get days => _days;

  final List<String> _tags;
  List<String> get tags => _tags;

  final List<User> _members;
  List<User> get members => _members;

  final List<FilePreview> _filePreviews;
  List<FilePreview> get filePreviews => _filePreviews;
  
  final List<Comment> _comments;
  List<Comment> get comments => _comments;

  Event(EventDTO dto) :
    _id = dto.id!,
    _creator = User(dto.creator!),
    _title = dto.title,
    _iso8601startDateTime = dto.iso8601startDateTime,
    _iso8601endDateTime = dto.iso8601endDateTime.isNotEmpty ? dto.iso8601endDateTime : '',
    _date = Formatter.deserialiseDateTime(dto.iso8601startDateTime).date,
    _location = dto.location,
    _description = dto.description,
    _recommendation = dto.recommendation,
    _latitude = dto.latitude,
    _longitude = dto.longitude,
    _days = List<String>.from(dto.days),
    _tags = List<String>.from(dto.tags ?? []),
    _members = [],
    _filePreviews = [],
    _comments = []
    {
      _controller = EventEntitiesController(event: this);
    }

  void updateFromDTO(EventDTO dto) {
    _creator = User(dto.creator!);
    _title = dto.title;
    _iso8601startDateTime = dto.iso8601startDateTime;
    _iso8601endDateTime = dto.iso8601endDateTime.isNotEmpty ? dto.iso8601endDateTime : '';
    _date = Formatter.deserialiseDateTime(dto.iso8601startDateTime).date;
    _location = dto.location;
    _description = dto.description;
    _recommendation = dto.recommendation;
    _latitude = dto.latitude;
    _longitude = dto.longitude;
    _days
      ..clear()
      ..addAll(dto.days);
    _tags
      ..clear()
      ..addAll(dto.tags ?? []);
  }

  EventDraft toDraft() {
    return EventDraft(
      id: _id,
      title: _title,
      room: Locations.rooms.containsKey(_location) ? _location : 'A.E.0.1',
      location: Locations.rooms.containsKey(_location) ? '' : _location,
      description: _description,
      recommendation: _recommendation,
      startTime: Formatter.iso8601StringToTimeOfDay(_iso8601startDateTime),
      endTime: _iso8601endDateTime.isNotEmpty ? Formatter.iso8601StringToTimeOfDay(_iso8601endDateTime) : null,
      date: Formatter.stringToDateTime(Formatter.deserialiseDateTime(_iso8601startDateTime, rawDates: true).date),
      coordinates: LatLng(_latitude, _longitude),
      days: _days,
    );
  }
}

class EventDraft {
  String? id;
  String? title;
  String? room;
  String? location;
  String? description;
  String? recommendation;
  TimeOfDay? startTime;
  TimeOfDay? endTime;
  DateTime? date;
  bool pickedLocation = false;
  LatLng? coordinates;
  List<String> days = [];

  EventDraft({
    this.id,
    this.title,
    this.location,
    this.room,
    this.description,
    this.recommendation,
    this.startTime,
    this.endTime,
    this.date,
    this.coordinates,
    this.days = const [],
  });

  @override
  String toString() {
    return 'EventDraft(id: $id, title: $title, room: $room,location: $location, description: $description, recommendation: $recommendation, startTime: $startTime, endTime: $endTime, date: $date, coordinates: $coordinates, days: $days)';
  }
}