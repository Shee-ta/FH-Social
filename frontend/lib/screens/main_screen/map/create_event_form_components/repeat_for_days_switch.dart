import 'dart:math';

import 'package:flutter/material.dart';
import 'package:frontend/UI/constants.dart';

class RepeatForDaysSwitch extends StatelessWidget {
  const RepeatForDaysSwitch({
    super.key,
    required this.repeatedForDays,
    required this.setSwitchToggle,
  });

  final bool repeatedForDays;
  final ValueChanged<bool> setSwitchToggle;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return FractionallySizedBox(
      widthFactor: screenWidth > 600 ? 0.45 : max(300.0 / screenWidth, 1),
      child: SwitchListTile(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Const.textFieldRadius),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 8),
        title: const Text('Repeat for days', softWrap: false),
        value: repeatedForDays,
        onChanged: (value) {
          setSwitchToggle(value);
        },
      ),
    );
  }
}