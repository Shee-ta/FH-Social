import 'package:flutter/material.dart';
import 'package:frontend/di/app_di.dart';
import 'package:frontend/environment/environment.dart';
import 'package:frontend/services/backend_url_service.dart';
import 'package:frontend/services/ui_feedback_service.dart';

class BackendUrlSettingsScreen extends StatefulWidget {
  const BackendUrlSettingsScreen({super.key});

  static const routeName = '/settings/backend-url';

  @override
  State<BackendUrlSettingsScreen> createState() => _BackendUrlSettingsScreenState();
}

class _BackendUrlSettingsScreenState extends State<BackendUrlSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _urlController = TextEditingController();

  final _di = AppDI.instance;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _urlController.text = _di.baseUrl;
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final raw = _urlController.text;
    final normalized = BackendUrlService.normalize(raw);

    try {
      await _di.applyBackendUrl(normalized);

      if (!mounted) {
        return;
      }

      UIfeedbackService.notification(
        message: 'Backend-URL geändert auf $normalized',
        type: NotificationType.success,
      );

      Navigator.pop(context);
    } catch (_) {
      UIfeedbackService.notification(
        message: 'Backend-URL konnte nicht geändert werden.',
        type: NotificationType.error,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _resetToDefault() async {
    setState(() {
      _isSaving = true;
    });

    try {
      await _di.resetBackendUrlToDefault();
      final fallback = Environment.getBaseUrl();
      _urlController.text = fallback;

      UIfeedbackService.notification(
        message: 'Backend-URL auf Standard zurückgesetzt.',
        type: NotificationType.success,
      );
    } catch (_) {
      UIfeedbackService.notification(
        message: 'Backend-URL konnte nicht zurückgesetzt werden.',
        type: NotificationType.error,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final defaultUrl = Environment.getBaseUrl();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Zurück',
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Text('Backend-URL'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Lege die Backend-URL fest, die diese App verwendet.\nBeispiel: http://192.168.1.42:3000',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _urlController,
                    enabled: !_isSaving,
                    keyboardType: TextInputType.url,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _save(),
                    decoration: const InputDecoration(
                      labelText: 'Backend-URL',
                    ),
                    validator: (value) {
                      final input = value?.trim() ?? '';
                      if (input.isEmpty) {
                        return 'Bitte eine URL eingeben.';
                      }
                      if (!BackendUrlService.isValid(input)) {
                        return 'Bitte eine gültige http:// oder https:// URL eingeben.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Standard: $defaultUrl',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: _isSaving ? null : _save,
                    icon: _isSaving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save),
                    label: const Text('Speichern & Übernehmen'),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: _isSaving ? null : _resetToDefault,
                    icon: const Icon(Icons.restore),
                    label: const Text('Auf Standard zurücksetzen'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
