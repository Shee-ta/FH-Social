
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
        labelText: 'Location name *',
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
          return 'Please enter location name and pick a location';
        } else if (isCoordinatesEmpty) {
          return 'Please pick a location on the map or use your current location';
        } else if (isLocationNameEmpty) {
          return 'Please enter a location name';
        }
        return null;
      },
    );
  }
}