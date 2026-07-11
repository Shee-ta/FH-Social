import 'package:flutter/material.dart';
import 'package:frontend/di/app_di.dart';
import 'package:frontend/screens/backend_url_settings_screen.dart';
import 'package:frontend/screens/login_screen.dart';
import 'package:frontend/services/settings_service.dart';

class AccountSettingsTab extends StatelessWidget {
  AccountSettingsTab(
    {super.key}
    )
    : settingsService = AppDI.instance.settingsService;

  final SettingsService settingsService;

  @override
  Widget build(BuildContext context) {
    final authController = AppDI.instance.authController;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ElevatedButton.icon(
            style: settingsService.neutralButtonStyle(context),
            onPressed: () {
              Navigator.pushNamed(context, BackendUrlSettingsScreen.routeName);
            },
            icon: const Icon(Icons.dns_outlined),
            label: const Text('Backend URL'),
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            style: settingsService.negativeButtonStyle(context),
            onPressed: () async {
              await authController.logout();

              if (!context.mounted) return;

              Navigator.pushReplacementNamed(context, LoginScreen.routeName);
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}