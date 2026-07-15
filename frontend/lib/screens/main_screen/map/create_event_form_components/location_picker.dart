
import 'package:flutter/material.dart';
import 'package:frontend/UI/constants.dart';
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
      tooltip: 'Ort auswählen',
      borderRadius: BorderRadius.circular(Const.textFieldRadius),
      color: Theme.of(context).colorScheme.primaryContainer,
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'pick',
          child: Row(
            children: [
              const Text('Auf Karte wählen'),
              Const.spacing,
              const Icon(Icons.map),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'location',
          child: Row(
            children: [
              const Text('Standort verwenden'),
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
          const Text('Ort wählen *'),
        ],
      ),
    );
  }
}