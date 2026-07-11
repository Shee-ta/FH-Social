import 'package:flutter/material.dart';
import 'package:frontend/controller/auth_controller.dart';
import 'package:frontend/controller/event_controller.dart';
import 'package:frontend/di/app_di.dart';
import 'package:frontend/screens/main_screen/chatbot.dart';
import 'package:frontend/screens/main_screen/map.dart';
import 'package:frontend/screens/settings_screen.dart';
import 'package:frontend/services/settings_service.dart';

import 'login_screen.dart';

class MainScreen extends StatelessWidget {
  MainScreen({
    super.key,
  })  : authController = AppDI.instance.authController,
        eventController = AppDI.instance.eventController,
        settingsService = AppDI.instance.settingsService;

  final AuthController authController;
  final EventController eventController;
  final SettingsService settingsService;

  static const routeName = '/';

  List<Tab> get _tabs => const [
    Tab(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.map_outlined),
          SizedBox(width: 8),
          Text('Map'),
        ],
      ),
    ),
    Tab(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.chat_bubble_outline),
          SizedBox(width: 8),
          Text('Coming Soon'),
        ],
      ),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return AnimatedBuilder(
      animation: authController,
      builder: (context, _) => DefaultTabController(
        length: _tabs.length,
        child: Scaffold(
          appBar: AppBar(
            automaticallyImplyLeading: false,
            leading: IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () {
                SettingsScreen.index = 0;
                Navigator.pushNamed(context, SettingsScreen.routeName);
              },
              tooltip: 'Settings',
            ),
            title: const Text('FH Social'),
            bottom: TabBar(
              tabs: _tabs,
            ),
            actions: [
              authController.isLoading
                  ? const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Center(
                        child: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    )
                  : authController.isLoggedIn
                  ? PopupMenuButton<String>(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      tooltip: 'Account',
                      onSelected: (value) async {
                        if (value == 'Logout') {
                          await authController.logout();
                        }
                        if (value == 'Account Settings') {
                          if (!context.mounted) return;
                          SettingsScreen.index = 1;
                          Navigator.pushNamed(context, SettingsScreen.routeName);
                        }
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem<String>(
                          value: 'Logout',
                          child: Row(
                            spacing: 8,
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              if (settingsService.iconButtonsActive) ...[
                                Icon(Icons.logout),
                              ],
                              Text('Logout'),
                            ],
                          ),
                        ),
                        PopupMenuItem<String>(
                          value: 'Account Settings',
                          child: Row(
                            spacing: 8,
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              if (settingsService.iconButtonsActive) ...[
                                Icon(Icons.settings),
                              ],
                              Text('Account Settings'),
                            ],
                          ),
                        ),
                      ],
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            if (screenWidth > 500)
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8.0),
                              child: Text(
                                authController.displayname,
                                style: const TextStyle(fontSize: 16),
                              ),
                            ),
                            const Icon(Icons.account_circle_rounded),
                          ]
                        ),
                      )
                    )
                  : IconButton(
                      onPressed: () {
                        Navigator.pushNamedAndRemoveUntil(
                          context,
                          LoginScreen.routeName,
                          (_) => false,
                        );
                      },
                      tooltip: 'Log in',
                      icon: const Icon(Icons.login),
                    ),
            ],
          ),
          body: TabBarView(
            children: [
              MapTab(),
              ChatbotTab(),
            ],
          ),
        ),
      ),
    );
  }
}
