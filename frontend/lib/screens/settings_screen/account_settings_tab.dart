import 'package:flutter/material.dart';
import 'package:frontend/UI/formatter.dart';
import 'package:frontend/controller/auth_controller.dart';
import 'package:frontend/di/app_di.dart';
import 'package:frontend/dto/user_dto.dart';
import 'package:frontend/screens/backend_url_settings_screen.dart';
import 'package:frontend/screens/login_screen.dart';
import 'package:frontend/services/settings_service.dart';

class AccountSettingsTab extends StatefulWidget {
  AccountSettingsTab({super.key})
      : settingsService = AppDI.instance.settingsService;

  final SettingsService settingsService;

  @override
  State<AccountSettingsTab> createState() => _AccountSettingsTabState();
}

class _AccountSettingsTabState extends State<AccountSettingsTab> {
  UserDTO? _user;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final authController = AppDI.instance.authController;
    if (!authController.isLoggedIn || authController.userId.isEmpty) {
      setState(() => _loading = false);
      return;
    }
    try {
      final user =
          await AppDI.instance.userService.fetchUserById(authController.userId);
      if (mounted) {
        setState(() {
          _user = user;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _roleLabel(String role) {
    switch (role) {
      case 'admin':
        return 'Administrator';
      case 'professor':
        return 'Professor';
      case 'student':
        return 'Student';
      default:
        return role.isEmpty ? 'Unbekannt' : role;
    }
  }

  @override
  Widget build(BuildContext context) {
    final authController = AppDI.instance.authController;
    final scheme = Theme.of(context).colorScheme;
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (!authController.isLoggedIn)
            _notLoggedIn(context, scheme)
          else
            _accountCard(context, authController, scheme),
          const SizedBox(height: 20),
          Align(
            alignment: isMobile ? Alignment.center : Alignment.centerLeft,
            child: SizedBox(
              width: 300,
              child: ElevatedButton.icon(
                style: widget.settingsService.neutralButtonStyle(context),
                onPressed: () {
                  Navigator.pushNamed(context, BackendUrlSettingsScreen.routeName);
                },
                icon: const Icon(Icons.dns_outlined),
                label: const Text('Backend URL'),
              ),
            ),
          ),
          const SizedBox(height: 10),
          if (authController.isLoggedIn)
          Align(
            alignment: isMobile ? Alignment.center : Alignment.centerLeft,
            child: SizedBox(
              width: 300,
              child: ElevatedButton.icon(
                style: widget.settingsService.negativeButtonStyle(context),
                icon: const Icon(Icons.logout),
                onPressed: () async {
                  await authController.logout();
                  if (!context.mounted) return;
                  Navigator.pushReplacementNamed(context, LoginScreen.routeName);
                },
                label: const Text('Logout'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _accountCard(
    BuildContext context,
    AuthController authController,
    ColorScheme scheme,
  ) {
    final String displayname = _user?.displayname.isNotEmpty == true
        ? _user!.displayname
        : authController.displayname;
    final String username = _user?.username.isNotEmpty == true
        ? _user!.username
        : authController.username;
    final role = _user?.role ?? '';
    final memberSince = _user?.createdAt ?? '';
    final String userId = _user?.id ?? authController.userId;

    final initials = displayname.isNotEmpty
        ? displayname.substring(0, displayname.length >= 2 ? 2 : 1).toUpperCase()
        : '?';

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 500),
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: scheme.primaryContainer,
                    child: Text(
                      initials,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: scheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayname.isNotEmpty ? displayname : 'Unbekannt',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        Text(
                          '@$username',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 32),
              _infoRow(context, Icons.badge_outlined, 'Rolle', _roleLabel(role)),
              _infoRow(
                context,
                Icons.calendar_month_outlined,
                'Mitglied seit',
                memberSince.isEmpty
                    ? 'Unbekannt'
                    : Formatter.deserialiseDateTime(memberSince, rawDates: true)
                        .date,
              ),
              _infoRow(
                context,
                Icons.verified_user_outlined,
                'Status',
                authController.isLoggedIn ? 'Angemeldet' : 'Abgemeldet',
              ),
              _infoRow(
                context,
                Icons.fingerprint,
                'Nutzer-ID',
                userId.length >= 8 ? '${userId.substring(0, 8)}…' : userId,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRow(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: scheme.onSurfaceVariant),
          const SizedBox(width: 14),
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
          ),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _notLoggedIn(BuildContext context, ColorScheme scheme) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(Icons.person_off_outlined,
                size: 48, color: scheme.onSurfaceVariant),
            const SizedBox(height: 12),
            Text(
              'Nicht angemeldet',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              'Melde dich an, um deine Kontodaten zu sehen.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              style: widget.settingsService.positiveButtonStyle(context),
              icon: const Icon(Icons.login),
              onPressed: () {
                Navigator.pushReplacementNamed(context, LoginScreen.routeName);
              },
              label: const Text('Zum Login'),
            ),
          ],
        ),
      ),
    );
  }
}
