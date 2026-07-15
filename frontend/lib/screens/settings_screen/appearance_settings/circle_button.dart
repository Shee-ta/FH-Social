
import 'package:flutter/material.dart';
import 'package:frontend/di/app_di.dart';
import 'package:frontend/services/settings_service.dart';

class CircleButton extends StatelessWidget {
  CircleButton({
    super.key, 
    required this.color}
  )
  : settingsService = AppDI.instance.settingsService;

  final SettingsService settingsService;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
        onPressed: () {
          if (color == Colors.white || color == Colors.grey || color == Colors.black) {
            settingsService.setThemeBrightness(
              color == Colors.black ? Brightness.dark 
              : color == Colors.grey ? (ThemeMode.system == ThemeMode.dark ? Brightness.dark : Brightness.light) 
              : Brightness.light);
          } else {
            settingsService.setThemeColor(color);
          }
        },
        style: ElevatedButton.styleFrom(
          shape: CircleBorder(
            side: BorderSide(
              color: Theme.of(context).colorScheme.onPrimaryContainer.withValues(alpha: 0.5),
              width: 1,
            ),
          ),
          backgroundColor: color,
          foregroundColor: Colors.black,
          elevation: 8,
          fixedSize: const Size(56, 56),
          padding: EdgeInsets.zero,
        ),
        child: color == Colors.grey ? Text("System") : null,
      );
    }
}