
import 'package:flutter/material.dart';
import 'package:frontend/entity/event.dart';

class CoordinatesLabel extends StatelessWidget {
  const CoordinatesLabel({
    super.key,
    required this.draft, 
  });

  final EventDraft draft;

  @override
  Widget build(BuildContext context) {
    return Text(
      'Coordinates: ${draft.coordinates!.latitude}, ${draft.coordinates!.longitude}',
      style: Theme.of(context).textTheme.bodyMedium,
    );
  }
}