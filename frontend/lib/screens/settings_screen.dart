
import 'package:flutter/material.dart';
import 'package:frontend/controller/auth_controller.dart';
import 'package:frontend/di/app_di.dart';
import 'package:frontend/screens/main_screen.dart';
import 'package:frontend/screens/settings_screen/account_settings_tab.dart';
import 'package:frontend/screens/settings_screen/appearance_settings_tab.dart';

class SettingsScreen extends StatefulWidget {
  SettingsScreen({
    super.key,
  }) : authController = AppDI.instance.authController;

  static int index = 0;
  static const routeName = '/settings';

  final AuthController authController;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const _breakpoint = 700.0;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= _breakpoint;

          return Scaffold(
            appBar: AppBar(
              automaticallyImplyLeading: false,
              title: const Text('Settings'),
              bottom: isWide
              ? null
              : const TabBar(
                  tabs: [
                    Tab(text: 'General'),
                    Tab(text: 'Account'),
                  ],
                ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, MainScreen.routeName);
                  },
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(0),
                    ),
                    foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: Text(
                            "Back to Main",
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                        const Icon(Icons.exit_to_app),
                      ]
                    ),
                  )
                ),
              ],
            ),
            body: isWide
            ? Row(
              children: [
                NavigationRail(
                  selectedIndex: SettingsScreen.index,
                  onDestinationSelected: (index) {
                    setState(() => SettingsScreen.index = index);
                  },
                  labelType: NavigationRailLabelType.all,
                  destinations: const [
                    NavigationRailDestination(
                      icon: Icon(Icons.brush_outlined),
                      label: Text('Appearance'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.person),
                      label: Text('Account'),
                    ),
                  ],
                ),
                const VerticalDivider(width: 1),
                Expanded(
                  child: IndexedStack(
                    index: SettingsScreen.index,
                    children: [
                      AppearanceSettingsTab(),
                      AccountSettingsTab(),
                    ],
                  ),
                ),
              ],
            )
            : TabBarView(
                children: [
                  AppearanceSettingsTab(),
                  AccountSettingsTab(),
                ],
              ),
          );
        },
      ),
    );
  }
}