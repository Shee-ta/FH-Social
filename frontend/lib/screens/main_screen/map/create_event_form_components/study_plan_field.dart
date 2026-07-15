import 'package:flutter/material.dart';
import 'package:frontend/UI/constants.dart';
import 'package:frontend/entity/event.dart';

class StudyPlanField extends StatelessWidget {
  const StudyPlanField({
    super.key,
    required this.studyPlanController,
    required this.draft,
  });

  final TextEditingController studyPlanController;
  final EventDraft draft;

  @override
  Widget build(BuildContext context) {
    return StatefulBuilder(
      builder:(context, setState) {
        return TextField(
          controller: studyPlanController,
          onChanged: (value) {
            draft.recommendation = value;
            setState(() {});
          },
          maxLines: null,
          maxLength: 600,
          decoration: InputDecoration(
            labelText: 'Study plan',
            border: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(Const.textFieldRadius)),
            ),
            counterText: '${studyPlanController.text.length}/600',
          ),
        );
      },
    );
  }
}