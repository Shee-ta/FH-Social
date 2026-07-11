
import 'package:flutter/material.dart';
import 'package:frontend/UI/constants.dart';
import 'package:frontend/appComponents/locations.dart';
import 'package:frontend/entity/event.dart';

class DropdownRooms extends StatelessWidget {
  const DropdownRooms({
    super.key,
    required this.draft,
    required this.setRoom,
  });

  final EventDraft draft;
  final ValueChanged<String?> setRoom;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: draft.room,
      decoration: InputDecoration(
        filled: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Const.textFieldRadius),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      borderRadius: BorderRadius.circular(Const.textFieldRadius),
      dropdownColor: Theme.of(context).colorScheme.primaryContainer,
      onChanged: (room) {
        setRoom(room);
      },
      items: [
        for (final location in Locations.rooms.keys)
          DropdownMenuItem(
            value: location,
            child: Text(location),
          ),
      ],
    );
  }
}