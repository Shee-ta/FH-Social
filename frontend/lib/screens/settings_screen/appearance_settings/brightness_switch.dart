
import 'package:flutter/material.dart';
import 'package:frontend/di/app_di.dart';
import 'package:frontend/screens/settings_screen/appearance_settings/circle_button.dart';
import 'package:frontend/services/settings_service.dart';

class BrightnessSwitch extends StatelessWidget {
  BrightnessSwitch({
    super.key
  })
  : settingsService = AppDI.instance.settingsService;

  final SettingsService settingsService;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ...settingsService.themeColorToBrightness.entries.map((entry) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: CircleButton(
              color: entry.value,
            ),
          );
        })
      ],
    );
  }
}