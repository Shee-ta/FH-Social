import 'package:flutter/material.dart';
import 'package:frontend/UI/constants.dart';

class DaySelectionButtons extends StatelessWidget {
  const DaySelectionButtons({
    super.key,
    required this.daysSelected,
    required this.onPressed,
  });

  final List<bool> daysSelected;
  final ValueChanged<int> onPressed;

  @override
  Widget build(BuildContext context) {
    //Calculate width of the event creation form to set the padding of the day selection buttons
    final screenWidth = MediaQuery.of(context).size.width;
    final padding = screenWidth > 600 ? 20.0 : screenWidth < 400 ? 30.0 : (screenWidth - 200) / 14;
    return ToggleButtons(
      direction: screenWidth < 400 ? Axis.vertical : Axis.horizontal,
      borderRadius: const BorderRadius.all(Radius.circular(Const.textFieldRadius)),
      isSelected: daysSelected,
      onPressed: (index) {
        onPressed(index);
      },
      children: [
        for (final day in ['Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su'])
          Padding(
            padding: EdgeInsets.symmetric(horizontal: padding),
            child: Text(day),
          ),
      ],
    );
  }
}