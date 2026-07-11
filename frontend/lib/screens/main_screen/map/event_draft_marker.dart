import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class EventDraftMarker extends StatelessWidget {
  final LatLng coordinates;
  final VoidCallback onCreateEvent;

  const EventDraftMarker({
    super.key,
    required this.coordinates,
    required this.onCreateEvent,
  });

  @override
  Widget build(BuildContext context) {
    return MarkerLayer(
      markers: [
        Marker(
          point: coordinates,
          width: 40,
          height: 40,
          child: GestureDetector(
            onTap: onCreateEvent,
            child: const Icon(
              Icons.edit_location_alt,
              color: Colors.purple,
              size: 40,
            ),
          ),
        ),
      ],
    );
  }
}