
import 'package:flutter/material.dart';

class EventPopupTags extends StatelessWidget {
  final List<String> tags;

  const EventPopupTags({
    super.key,
    required this.tags
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8.0,
      runSpacing: 8.0,
      children: tags.map((tag) => ElevatedButton(
        onPressed: () {
          // Handle tag button press
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
          ),
        ),
        child: Text(
          tag,
          style: TextStyle(color: Theme.of(context).colorScheme.onTertiaryContainer)
        ),
      )).toList(),
    );
  }
}