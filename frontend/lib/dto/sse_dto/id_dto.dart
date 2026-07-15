
class IdDTO {
  final String id;

  IdDTO({
    required this.id,
  });

  static IdDTO fromJson(Map<String, dynamic> json) {
    return IdDTO(
      id: json['id'],
    );
  }
}