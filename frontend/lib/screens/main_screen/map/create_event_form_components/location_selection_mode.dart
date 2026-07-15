
import 'package:flutter/material.dart';
import 'package:frontend/UI/constants.dart';

class LocationSelectionMode extends StatelessWidget {
  const LocationSelectionMode({
    super.key,
    required this.locationSelectMode,
    required this.setLocationSelectionMode,
  });

  final List<bool> locationSelectMode;
  final ValueChanged<int> setLocationSelectionMode;

  @override
  Widget build(BuildContext context) {
    return ToggleButtons(
      borderRadius: const BorderRadius.all(Radius.circular(Const.textFieldRadius)),
      isSelected: locationSelectMode,
      onPressed: (index) {
        setLocationSelectionMode(index);
      },
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              const Icon(Icons.location_on),
              Const.spacing,
              const Text('Ort eingeben'),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              const Icon(Icons.map),
              Const.spacing,
              const Text('Ort wählen'),
            ],
          ),
        ),
      ],
    );
  }
}