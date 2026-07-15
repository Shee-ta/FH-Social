
import 'package:flutter/material.dart';
import 'package:frontend/UI/constants.dart';
import 'package:frontend/entity/event.dart';

class LocationNameField extends StatelessWidget {
  const LocationNameField({
    super.key,
    required this.locationController,
    required this.draft,
  });

  final TextEditingController locationController;
  final EventDraft draft;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: locationController,
      onChanged: (value) => draft.location = value,
      decoration: const InputDecoration(
        labelText: 'Ortsname *',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(
            Radius.circular(Const.textFieldRadius),
          ),
        ),
      ),
      validator: (locationName) {
        final isLocationNameEmpty = locationName == null || locationName.trim().isEmpty;
        final isCoordinatesEmpty = draft.coordinates == null;
        if (isLocationNameEmpty && isCoordinatesEmpty) {
          return 'Bitte einen Ortsnamen eingeben und einen Ort wählen';
        } else if (isCoordinatesEmpty) {
          return 'Bitte einen Ort auf der Karte wählen oder deinen aktuellen Standort verwenden';
        } else if (isLocationNameEmpty) {
          return 'Bitte einen Ortsnamen eingeben';
        }
        return null;
      },
    );
  }
}