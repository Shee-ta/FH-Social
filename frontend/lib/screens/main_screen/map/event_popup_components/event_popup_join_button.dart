
import 'package:flutter/material.dart';
import 'package:frontend/di/app_di.dart';
import 'package:frontend/entity/event.dart';
import 'package:frontend/services/settings_service.dart';

class EventPopupJoinButton extends StatelessWidget {
  EventPopupJoinButton({
    super.key,
    required this.event,
    required this.isMember,
    required this.changeMember,
  })
  : settingsService = AppDI.instance.settingsService;

  final Event event;
  final bool isMember;
  final SettingsService settingsService;
  final void Function() changeMember;

  @override
  Widget build(BuildContext context) {
    return StatefulBuilder(
      builder: (context, setState) {
        return Expanded(
          child: ElevatedButton(
            style: isMember ? settingsService.negativeButtonStyle(context) : settingsService.positiveButtonStyle(context),
            onPressed: event.controller.isChangingMembership ? null : changeMember,
            child: event.controller.isChangingMembership
            ? SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              )
            : Row(
                spacing: 8,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (settingsService.iconButtonsActive) ...[
                    Icon(isMember ? Icons.transit_enterexit_outlined : Icons.add),
                  ],
                  Text(isMember ? 'Verlassen' : 'Beitreten')
                ],
              ),
          ),
        );
      },
    );
  }
}