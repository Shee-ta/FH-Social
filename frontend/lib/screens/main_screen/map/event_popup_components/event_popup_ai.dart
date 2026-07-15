
import 'package:flutter/material.dart';
import 'package:frontend/UI/constants.dart';
import 'package:frontend/di/app_di.dart';
import 'package:frontend/entity/event.dart';
import 'package:frontend/services/settings_service.dart';

class EventPopupAiButton extends StatelessWidget {
  final Event event;

  EventPopupAiButton({
    super.key,
    required this.event,
  })
  : settingsService = AppDI.instance.settingsService;

  final SettingsService settingsService;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final screenWidth = MediaQuery.of(context).size.width;
    return Expanded(
      child: PopupMenuButton(
        tooltip: 'Show AI tools',
        color: Theme.of(context).colorScheme.primaryContainer,
        itemBuilder: (BuildContext context) => <PopupMenuEntry>[
          PopupMenuItem(
            onTap: event.controller.isAiGenerating ? null : ()  {
              event.controller.generateRecommendation(event.id);
            },
            value: 'recommendation',
            child: Row(
              children: [
                Icon(Icons.recommend),
                Const.spacing,
                Text('Generate study plan'),
              ]
            ),
          ),
          PopupMenuItem(
            onTap: event.controller.isAiGenerating ? null : ()  {
              event.controller.generateTags(event.id);
            },
            value: 'tags',
            child: Row(
              children: [
                Icon(Icons.tag),
                Const.spacing,
                Text('Generate tags'),
              ]
            ),
          ),
        ],
        onSelected: (value) async {
          
        },
        child: Material(
          elevation: 1,
          color: settingsService.aiButtonColor(context),
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Align(
              alignment: Alignment.center,
              child: event.controller.isAiGenerating 
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      color: colorScheme.onPrimaryContainer,
                      strokeWidth: 2,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (screenWidth > 500) ...[
                        Icon(Icons.auto_awesome_outlined, size: 18, color: colorScheme.onTertiaryContainer),
                        Const.spacing,
                      ],
                      Text(screenWidth > 500 ? 'Ask AI' : 'AI', style: TextStyle(color: colorScheme.onTertiaryContainer)),
                    ],
                  ),
              ),
          ),
        ),
      ),
    );
  }
}