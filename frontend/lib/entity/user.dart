
import 'package:frontend/dto/user_dto.dart';

class User {

  final String _id;
  String get id => _id;

  String _username;
  String get username => _username;

  String _displayname;
  String get displayname => _displayname;

  String _role;
  String get role => _role;

  User(UserDTO dto)
  : _id = dto.id,
    _username = dto.username,
    _displayname = dto.displayname,
    _role = dto.role;

  void modifyUser(UserDTO dto) {
    _username = dto.username;
    _displayname = dto.displayname;
    _role = dto.role;
  }
}