import 'package:flutter/material.dart';
import 'package:frontend/di/app_di.dart';
import 'package:frontend/services/settings_service.dart';

class DashboardHeader extends StatelessWidget {
  DashboardHeader({
    super.key,
    required this.showWeeklySchedule,
    required this.onModeChanged,
  })
  : settingsService = AppDI.instance.settingsService;

  final bool showWeeklySchedule;
  final ValueChanged<bool> onModeChanged;
  final SettingsService settingsService;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Dashboard',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 10),
        Align(
          alignment: Alignment.centerLeft,
          child: ToggleButtons(
            fillColor: Theme.of(context).colorScheme.primary,
            selectedColor: Theme.of(context).colorScheme.primaryContainer,
            isSelected: settingsService.dashbordSelectedMode,
            onPressed: (index) => {
              onModeChanged(index == 1),
              settingsService.dashbordSelectedMode = [index == 0, index == 1]
            },
            borderRadius: BorderRadius.circular(10),
            constraints: const BoxConstraints(minHeight: 40, minWidth: 120),
            children: const [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Text('Overview'),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Text('Weekly Schedule'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
