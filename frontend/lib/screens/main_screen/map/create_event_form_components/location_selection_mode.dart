
import 'package:flutter/material.dart';
import 'package:frontend/UI/constants.dart';

class LocationSelectionMode extends StatelessWidget {
  const LocationSelectionMode({
    super.key,
    this.hasNoMap = false,
    required this.locationSelectMode,
    required this.setLocationSelectionMode,
  });

  final bool hasNoMap;
  final List<bool> locationSelectMode;
  final ValueChanged<int> setLocationSelectionMode;

  @override
  Widget build(BuildContext context) {
    if (hasNoMap) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setLocationSelectionMode(0);
      });
    }
    return ToggleButtons(
      borderRadius: const BorderRadius.all(Radius.circular(Const.textFieldRadius)),
      isSelected: hasNoMap ? [true, false] : locationSelectMode,
      onPressed: (index) {
        if (!hasNoMap) {
          setLocationSelectionMode(index);
        }
      },
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              const Icon(Icons.location_on),
              Const.spacing,
              const Text('Select place'),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              hasNoMap ? const Icon(Icons.location_disabled_rounded) : const Icon(Icons.map),
              Const.spacing,
              hasNoMap ? const Text('No map') : const Text('Pick location'),
            ],
          ),
        ),
      ],
    );
  }
}