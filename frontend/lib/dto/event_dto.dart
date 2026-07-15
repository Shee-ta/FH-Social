
import 'package:frontend/dto/user_dto.dart';

class EventDTO {
  const EventDTO({
    this.id,
    this.creator,
    required this.title,
    required this.iso8601startDateTime,
    required this.iso8601endDateTime,
    required this.location,
    required this.description,
    required this.recommendation,
    required this.latitude,
    required this.longitude,
    required this.days,
    this.tags,
    this.members,
    this.createdAt,
    this.editedAt,
  });

  final String? id;
  final UserDTO? creator;
  final String title;
  final String iso8601startDateTime;
  final String iso8601endDateTime;
  final String location;
  final String description;
  final String recommendation;
  final double latitude;
  final double longitude;
  final List<String> days;
  final List<String>? tags;
  final List<UserDTO>? members;
  final String? createdAt;
  final String? editedAt;

  @override
  String toString() {
    return 'MapMeetEvent(id: $id, title: $title, location: $location, description: $description, recommendation: $recommendation, startDateTime: $iso8601startDateTime, endDateTime: $iso8601endDateTime, latitude: $latitude, longitude: $longitude, days: $days, tags: $tags, createdAt: $createdAt, editedAt: $editedAt)';
  }

  static EventDTO fromJson(Map<String, dynamic> json) {
    return EventDTO(
      id: json['id'],
      creator: UserDTO.fromJson(json['creator']),
      title: json['title'],
      iso8601startDateTime: json['iso8601startDateTime'],
      iso8601endDateTime: json['iso8601endDateTime'],
      location: json['location'],
      description: json['description'],
      recommendation: json['recommendation'],
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      days: List<String>.from(json['days']),
      tags: List<String>.from(json['tags']),
      members: json['members'] != null
          ? (json['members'] as List)
              .map((e) => UserDTO.fromJson(e as Map<String, dynamic>))
              .toList()
          : null,
      createdAt: json['createdAt'],
      editedAt: json['editedAt'],
    );
  }
}