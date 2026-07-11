import 'package:flutter/material.dart';
import 'package:frontend/di/app_di.dart';
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
      child: ElevatedButton(
        style: settingsService.negativeButtonStyle(context),
        onPressed: () async {
          await authController.logout();

          if (!context.mounted) return;

          Navigator.pushReplacementNamed(context, LoginScreen.routeName);
        },
        child: const Text('Logout'),
      ),
    );
  }
}