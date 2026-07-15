
import 'package:flutter/material.dart';
import 'package:frontend/di/app_di.dart';
import 'package:frontend/services/settings_service.dart';

class AccessabilityMenu extends StatelessWidget {
  AccessabilityMenu(
    {super.key}
  )
  : settingsService = AppDI.instance.settingsService;

  final SettingsService settingsService;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: ListenableBuilder(
        listenable: settingsService,
        builder: (context, _) {
          return Column(
            children: [
              ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                tileColor: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
                style: ListTileStyle.drawer,
                title: Text('Symbol-Schaltflächen'),
                subtitle: Text('Wenn aktiviert, zeigen Schaltflächen Symbole.'),
                leading: Icon(Icons.radio_button_checked),
                trailing: Switch(
                  value: settingsService.iconButtonsActive,
                  onChanged: (value) {
                    settingsService.setIconButtonsActive(value);
                  },
                ),
                onTap: () {
                  settingsService.setIconButtonsActive(!settingsService.iconButtonsActive);
                }
              ),
            ]
          );
        }
      )
    );
  }
}