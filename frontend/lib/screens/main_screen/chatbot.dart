
import 'package:flutter/material.dart';
import 'package:frontend/controller/auth_controller.dart';
import 'package:frontend/di/app_di.dart';

class ChatbotTab extends StatelessWidget {
  ChatbotTab({
    super.key,
  }) : authController = AppDI.instance.authController;

  final AuthController authController;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          'Coming Soon',
          style: Theme.of(context).textTheme.headlineMedium,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}