
import 'package:frontend/dto/user_dto.dart';

class IdWithUserDTO {
  final String eventId;
  final UserDTO user;

  IdWithUserDTO({
    required this.eventId,
    required this.user,
  });

  static IdWithUserDTO fromJson(Map<String, dynamic> json) {
    return IdWithUserDTO(
      eventId: json['eventId'],
      user: UserDTO.fromJson(json['user']),
    );
  }
}