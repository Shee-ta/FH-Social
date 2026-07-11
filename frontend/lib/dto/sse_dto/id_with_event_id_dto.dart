
class IdWithEventIdDTO {
  final String id;
  final String eventId;

  IdWithEventIdDTO({
    required this.id,
    required this.eventId,
  });

  static IdWithEventIdDTO fromJson(Map<String, dynamic> json) {
    return IdWithEventIdDTO(
      id: json['id'],
      eventId: json['eventId']
    );
  }
}