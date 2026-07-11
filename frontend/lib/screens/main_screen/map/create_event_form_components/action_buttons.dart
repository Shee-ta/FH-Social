import 'package:flutter/material.dart';
import 'package:frontend/UI/constants.dart';
import 'package:frontend/controller/event_controller.dart';
import 'package:frontend/di/app_di.dart';
import 'package:frontend/dto/event_dto.dart';
import 'package:frontend/services/settings_service.dart';

class ActionButtons extends StatelessWidget {
  ActionButtons({
    super.key,
    required this.colorScheme,
    required this.checkTimeAndDate,
    required this.finishDraft,
    required this.resetDraft,
    required this.formKey,
    required this.isEditingExistingEvent,
    required this.sendEvent,
  }) : eventController = AppDI.instance.eventController,
       settingsService = AppDI.instance.settingsService;

  final SettingsService settingsService;

  final ColorScheme colorScheme;
  final bool Function() checkTimeAndDate;
  final EventDTO Function() finishDraft;
  final VoidCallback resetDraft;
  final GlobalKey<FormState> formKey;
  final EventController eventController;
  final bool isEditingExistingEvent;
  final VoidCallback sendEvent;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: eventController,
      builder: (context, _) {
        return Row(
          children: [
            Expanded(
              child: ElevatedButton(
                style: settingsService.positiveButtonStyle(context),
                onPressed: eventController.isUploadingEvent
                ? null
                : sendEvent,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12),
                  child: eventController.isUploadingEvent
                  ? SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: colorScheme.onPrimaryContainer,
                      ),
                    )
                  : Row(
                      spacing: 8,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (settingsService.iconButtonsActive) ...[
                          Icon(isEditingExistingEvent ? Icons.edit : Icons.send),
                        ],
                        Text(isEditingExistingEvent ? 'Update' : 'Send')
                      ],
                  ),
                ),
              ),
            ),
            Const.spacing,
            Expanded(
              child: ElevatedButton(
                style: settingsService.negativeButtonStyle(context),
                onPressed: eventController.isUploadingEvent ? null : resetDraft,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12),
                  child: Row(
                    spacing: 8,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (settingsService.iconButtonsActive) ...[
                        const Icon(Icons.cancel),
                      ],
                      const Text('Cancel')
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}