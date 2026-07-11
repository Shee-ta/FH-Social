import 'package:flutter/material.dart';
import 'package:frontend/UI/constants.dart';
import 'package:frontend/entity/event.dart';

class DescriptionField extends StatelessWidget {
  const DescriptionField({
    super.key,
    required this.descriptionController,
    required this.draft,
  });

  final TextEditingController descriptionController;
  final EventDraft draft;

  @override
  Widget build(BuildContext context) {
    return StatefulBuilder(
      builder: (context, setState) {
        return TextField(
          controller: descriptionController,
          onChanged: (value) {
            draft.description = value;
            setState(() {});
          },
          maxLines: null,
          maxLength: 2000,
          decoration: InputDecoration(
            labelText: 'Description',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(Const.textFieldRadius)),
            ),
            counterText: '${descriptionController.text.length}/2000',
          ),
        );
      },
    );
  }
}