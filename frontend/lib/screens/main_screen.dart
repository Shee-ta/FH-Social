import 'package:flutter/material.dart';
import 'package:frontend/controller/auth_controller.dart';
import 'package:frontend/controller/event_controller.dart';
import 'package:frontend/di/app_di.dart';
import 'package:frontend/entity/event.dart';
import 'package:frontend/screens/main_screen/chatbot.dart';
import 'package:frontend/screens/main_screen/map.dart';
import 'package:frontend/screens/main_screen/map/event_popup_components/event_popup_comment_input.dart';
import 'package:frontend/screens/main_screen/study_groups/my_groups_tab.dart';
import 'package:frontend/screens/main_screen/study_groups/study_groups_tab.dart';
import 'package:frontend/screens/settings_screen.dart';
import 'package:frontend/services/settings_service.dart';
import 'package:frontend/services/ui_feedback_service.dart';

import 'login_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  static const routeName = '/';

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final AuthController authController = AppDI.instance.authController;
  final EventController eventController = AppDI.instance.eventController;
  final SettingsService settingsService = AppDI.instance.settingsService;

  // Shared draft state so the detail popup can be opened from every tab.
  final List<CommentDraft> _commentDrafts = [];

  void _setEventDraft(EventDraft _) {}

  void _createEvent() {
    UIfeedbackService.notification(
      message: 'Zum Erstellen oder Bearbeiten bitte den Karten-Tab nutzen.',
      type: NotificationType.neutral,
    );
  }

  List<Widget> get _tabs => const [
        Tab(
          child: _TabLabel(icon: Icons.map_outlined, label: 'Karte'),
        ),
        Tab(
          child: _TabLabel(icon: Icons.groups_2_outlined, label: 'Lerngruppen'),
        ),
        Tab(
          child: _TabLabel(icon: Icons.bookmark_outline, label: 'Meine'),
        ),
        Tab(
          child: _TabLabel(icon: Icons.smart_toy_outlined, label: 'Assistent'),
        ),
      ];

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final scheme = Theme.of(context).colorScheme;

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
              tooltip: 'Einstellungen',
            ),
            title: const Text('FH Social'),
            bottom: TabBar(
              isScrollable: true,
              tabAlignment: TabAlignment.center,
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              indicator: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                color: scheme.primaryContainer,
              ),
              labelColor: scheme.onPrimaryContainer,
              unselectedLabelColor: scheme.onSurfaceVariant,
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
                          color: scheme.primaryContainer,
                          tooltip: 'Konto',
                          onSelected: (value) async {
                            if (value == 'Logout') {
                              await authController.logout();
                            }
                            if (value == 'Account Settings') {
                              if (!context.mounted) return;
                              SettingsScreen.index = 1;
                              Navigator.pushNamed(
                                  context, SettingsScreen.routeName);
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
                                    const Icon(Icons.logout),
                                  ],
                                  const Text('Abmelden'),
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
                                    const Icon(Icons.settings),
                                  ],
                                  const Text('Kontoeinstellungen'),
                                ],
                              ),
                            ),
                          ],
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ConstrainedBox(
                                  constraints: BoxConstraints(
                                    maxWidth: screenWidth > 500 ? 220 : 130,
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8.0),
                                    child: Text(
                                      authController.displayname,
                                      overflow: TextOverflow.ellipsis,
                                      softWrap: false,
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                  ),
                                ),
                                const Icon(Icons.account_circle_rounded),
                              ],
                            ),
                          ),
                        )
                      : IconButton(
                          onPressed: () {
                            Navigator.pushNamedAndRemoveUntil(
                              context,
                              LoginScreen.routeName,
                              (_) => false,
                            );
                          },
                          tooltip: 'Anmelden',
                          icon: const Icon(Icons.login),
                        ),
            ],
          ),
          body: TabBarView(
            children: [
              MapTab(),
              StudyGroupsTab(
                commentDrafts: _commentDrafts,
                setEventDraft: _setEventDraft,
                createEvent: _createEvent,
              ),
              MyGroupsTab(
                commentDrafts: _commentDrafts,
                setEventDraft: _setEventDraft,
                createEvent: _createEvent,
              ),
              ChatbotTab(
                commentDrafts: _commentDrafts,
                setEventDraft: _setEventDraft,
                createEvent: _createEvent,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TabLabel extends StatelessWidget {
  const _TabLabel({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 20),
        const SizedBox(width: 8),
        Text(label),
      ],
    );
  }
}
