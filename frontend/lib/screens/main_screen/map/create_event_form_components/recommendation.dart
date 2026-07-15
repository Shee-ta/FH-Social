import 'package:flutter/material.dart';
import 'package:frontend/UI/constants.dart';
import 'package:frontend/entity/event.dart';

class RecommendationField extends StatelessWidget {
  const RecommendationField({
    super.key,
    required this.recommendationController,
    required this.draft,
  });

  final TextEditingController recommendationController;
  final EventDraft draft;

  @override
  Widget build(BuildContext context) {
    return StatefulBuilder(
      builder:(context, setState) {
        return TextField(
          controller: recommendationController,
          onChanged: (value) {
            draft.recommendation = value;
            setState(() {});
          },
          maxLines: null,
          maxLength: 300,
          decoration: InputDecoration(
            labelText: 'Lerntipp',
            border: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(Const.textFieldRadius)),
            ),
            counterText: '${recommendationController.text.length}/300',
          ),
        );
      },
    );
  }
}