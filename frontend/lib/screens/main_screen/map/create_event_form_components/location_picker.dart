
import 'package:flutter/material.dart';
import 'package:frontend/UI/constants.dart';
import 'package:frontend/services/ui_feedback_service.dart';
import 'package:latlong2/latlong.dart';

class LocationPicker extends StatelessWidget {
  const LocationPicker({
    super.key,
    required this.setCoordinates,
    required this.useLocationForEvent,
    required this.setHasPickedLocation,
    required this.setPickingLocation,
  });

  final ValueChanged<LatLng?> setCoordinates;
  final Future<LatLng?> Function() useLocationForEvent;
  final ValueChanged<bool> setHasPickedLocation;
  final ValueChanged<bool> setPickingLocation;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: 'Click how to select location',
      borderRadius: BorderRadius.circular(Const.textFieldRadius),
      color: Theme.of(context).colorScheme.primaryContainer,
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'pick',
          child: Row(
            children: [
              const Text('Pick on map'),
              Const.spacing,
              const Icon(Icons.map),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'location',
          child: Row(
            children: [
              const Text('Use location'),
              Const.spacing,
              const Icon(Icons.location_on),
            ],
          ),
        ),
      ],
      onSelected: (value) async {
        if (value == 'pick') {
          setPickingLocation(true);
          Navigator.of(context).pop();
        } else if (value == 'location') {
          final coordinates = await useLocationForEvent();
          if (coordinates == null && context.mounted) {
            UIfeedbackService.notification(
              message: 'Location tracking is disabled. Please enable it to use your location for the event.',
              type: NotificationType.error,
            );
          }
          setCoordinates(coordinates);
          setHasPickedLocation(coordinates != null);
        }
      },
      child: Row(
        children: [
          Icon(
            color: Theme.of(context).colorScheme.primary,
            Icons.edit_location,
            size: 42,
          ),
          const Text('Select location *'),
        ],
      ),
    );
  }
}