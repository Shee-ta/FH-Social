import 'package:flutter/material.dart';

class DateTimeError extends StatelessWidget {
  const DateTimeError({
    super.key,
    required this.colorScheme,
    required this.message,
  });

  final ColorScheme colorScheme;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Text(
        message,
        style: TextStyle(color: colorScheme.error),
      ),
    );
  }
}