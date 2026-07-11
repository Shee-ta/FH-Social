
import 'package:flutter/material.dart';
import 'package:frontend/di/app_di.dart';
import 'package:frontend/screens/settings_screen/appearance_settings/accessability_menu.dart';
import 'package:frontend/screens/settings_screen/appearance_settings/brightness_switch.dart';
import 'package:frontend/screens/settings_screen/appearance_settings/color_wheel.dart';
import 'package:frontend/services/settings_service.dart';

class AppearanceSettingsTab extends StatelessWidget {
  AppearanceSettingsTab({
    super.key
  })
  : settingsService = AppDI.instance.settingsService;

  final SettingsService settingsService;

  @override
  Widget build(BuildContext context) {

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 830) {
          return SingleChildScrollView(
            child: Center(
              child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 700),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  "Accessability",
                                  style: Theme.of(context).textTheme.titleMedium,
                                ),
                                const SizedBox(height: 12),
                                AccessabilityMenu(),
                              ],
                            ),
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 420,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              "Theme",
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 12),
                            BrightnessSwitch(),
                            const SizedBox(height: 40),
                            Text(
                              "Accent color",
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 12),
                            ColorWheel(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          );
        } else {
          return _buildWideLayout(context);
        }
      },
    );
  }

  Widget _buildWideLayout(BuildContext context) {
    return SingleChildScrollView(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Theme",
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              BrightnessSwitch(),
              const SizedBox(height: 40),
              Text(
                "Accent color",
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              ColorWheel(),
              const SizedBox(height: 40),
              Divider(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.36),
                thickness: 1,
              ),
              const SizedBox(height: 12),
              Text(
                "Accessability",
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              AccessabilityMenu(),
            ],
          ),
        ),
      ),
    );
  }
}