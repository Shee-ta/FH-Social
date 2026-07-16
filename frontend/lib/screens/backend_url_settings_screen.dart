import 'package:flutter/material.dart';
import 'package:frontend/di/app_di.dart';
import 'package:frontend/environment/environment.dart';
import 'package:frontend/screens/main_screen.dart';
import 'package:frontend/services/backend_url_service.dart';
import 'package:frontend/services/ui_feedback_service.dart';
import 'package:http/http.dart' as http;

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

    final respose = await http.get(Uri.parse(normalized));
    print('Response status: ${respose.statusCode}');

    try {
      await _di.applyBackendUrl(normalized);

      if (!mounted) {
        return;
      }

      UIfeedbackService.notification(
        message: 'Backend URL updated to $normalized',
        type: NotificationType.success,
      );

      Navigator.pop(context);
    } catch (_) {
      UIfeedbackService.notification(
        message: 'Failed to update backend URL.',
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
        message: 'Backend URL reset to default.',
        type: NotificationType.success,
      );
    } catch (_) {
      UIfeedbackService.notification(
        message: 'Failed to reset backend URL.',
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
        automaticallyImplyLeading: false,
        title: const Text('Backend URL'),
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
                    'Set the backend URL used by this app.\nExample: http://192.168.1.42:3000',
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
                      labelText: 'Backend URL',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      final input = value?.trim() ?? '';
                      if (input.isEmpty) {
                        return 'Please enter a URL.';
                      }
                      if (!BackendUrlService.isValid(input)) {
                        return 'Use a valid http:// or https:// URL.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Default: $defaultUrl',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: _isSaving ? null : () async {
                      await _save();
                      if(context.mounted) {
                        Navigator.pushNamed(context, MainScreen.routeName);
                      }
                    },
                    icon: _isSaving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save),
                    label: const Text('Save and Apply'),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: _isSaving ? null : _resetToDefault,
                    icon: const Icon(Icons.restore),
                    label: const Text('Reset to Default'),
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
