
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:frontend/di/app_di.dart';
import 'package:frontend/services/settings_service.dart';
import 'package:frontend/screens/settings_screen/appearance_settings/circle_button.dart';

class ColorWheel extends StatelessWidget {
  ColorWheel({
    super.key}
  )
  : settingsService = AppDI.instance.settingsService
  {
    colors = settingsService.themeColorToColor.values.toList();
  }

  final SettingsService settingsService;

  late final List<Color> colors;

  final radius = 90.0;
  final buttonSize = 56.0;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: radius * 2 + buttonSize,
      height: radius * 2 + buttonSize,
      child: Stack(
        alignment: Alignment.center,
        children: [
          for (int i = 0; i < colors.length; i++)
            Builder(
              builder: (_) {
                final angle = (2 * pi * i) / colors.length - pi / 2;
                return Transform.translate(
                  offset: Offset(
                    radius * cos(angle),
                    radius * sin(angle),
                  ),
                  child: CircleButton(
                    color: colors[i],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}