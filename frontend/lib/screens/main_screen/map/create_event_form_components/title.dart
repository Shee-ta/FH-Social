
import 'package:flutter/material.dart';
import 'package:frontend/UI/constants.dart';
import 'package:frontend/entity/event.dart';

class TitleField extends StatelessWidget {
  const TitleField({
    super.key,
    required this.titleController,
    required this.draft,
  });

  final TextEditingController titleController;
  final EventDraft draft;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: titleController,
      onChanged: (value) => draft.title = value,
      decoration: const InputDecoration(
        labelText: 'Title *',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(
            Radius.circular(Const.textFieldRadius),
          ),
        ),
      ),
      validator: (title) {
        if (title == null || title.trim().isEmpty) {
          return 'Please enter a title';
        }
        return null;
      },
    );
  }
}