
class UserDTO {
  final String id;
  final String username;
  final String displayname;
  final String role;
  final String createdAt;
  final String editedAt;

  UserDTO({
    required this.id,
    required this.username,
    required this.displayname,
    required this.role,
    required this.createdAt,
    required this.editedAt,
  });

  static UserDTO fromJson(Map<String, dynamic> json) {
    return UserDTO(
      id: json['id'],
      username: json['username'],
      displayname: json['displayname'],
      role: json['role'],
      createdAt: json['createdAt'],
      editedAt: json['editedAt'],
    );
  }
}