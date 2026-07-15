
import 'package:flutter/material.dart';
import 'package:frontend/UI/constants.dart';
import 'package:frontend/di/app_di.dart';
import 'package:frontend/services/settings_service.dart';

class EventPopupEdit extends StatelessWidget {
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  EventPopupEdit({
    super.key,
    required this.onEdit,
    required this.onDelete,
  })
  : settingsService = AppDI.instance.settingsService;

  final SettingsService settingsService;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        ElevatedButton(
          onPressed: onEdit,
          style: settingsService.neutralButtonStyle(context),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.edit, size: 22),
              Const.spacing,
              const Text('Bearbeiten'),
            ]
          ),
        ),
        IconButton(
          onPressed: () {
            onDelete();
          },
          icon: const Icon(Icons.delete),
        ),
      ],
    );
  }
}