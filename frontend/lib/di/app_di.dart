import 'package:frontend/controller/auth_controller.dart';
import 'package:frontend/controller/event_controller.dart';
import 'package:frontend/environment/environment.dart';
import 'package:frontend/services/ai_service.dart';
import 'package:frontend/services/auth_service.dart';
import 'package:frontend/services/backend_url_service.dart';
import 'package:frontend/services/connection_services/sse_connection_service.dart';
import 'package:frontend/services/entity_services/comment_service.dart';
import 'package:frontend/services/entity_services/event_service.dart';
import 'package:frontend/services/entity_services/file_service.dart';
import 'package:frontend/services/entity_services/user_service.dart';
import 'package:frontend/services/connection_services/sse_listener_service.dart';
import 'package:frontend/services/settings_service.dart';

class AppDI {
  AppDI._();

  static final AppDI instance = AppDI._();

  bool _isInitialized = false;

  late String baseUrl;

  late final BackendUrlService backendUrlService;

  late final AuthService authService;
  late final EventService eventService;
  late final UserService userService;
  late final FileService fileService;
  late final CommentService commentService;
  late final AiService aiService;
  late final SettingsService settingsService;
  late final SseConnectionService sseConnectionService;

  late final AuthController authController;
  late final EventController eventController;
  late final SseListenerService sseListenerService;

  Future<void> init() async {
    if (_isInitialized) {
      return;
    }

    backendUrlService = BackendUrlService();
    await backendUrlService.init();
    baseUrl = backendUrlService.baseUrl.isEmpty
        ? Environment.getBaseUrl()
        : backendUrlService.baseUrl;

    authService = AuthService(baseUrl);
    eventService = EventService(baseUrl);
    userService = UserService(baseUrl);
    fileService = FileService(baseUrl);
    commentService = CommentService(baseUrl);
    aiService = AiService(baseUrl);
    settingsService = SettingsService();
    sseConnectionService = SseConnectionService(baseUrl);

    authController = AuthController();
    eventController = EventController();
    sseListenerService = SseListenerService();

    _isInitialized = true;
  }

  Future<void> applyBackendUrl(String newBaseUrl) async {
    await backendUrlService.setBaseUrl(newBaseUrl);
    await _applyActiveBaseUrl();
  }

  Future<void> resetBackendUrlToDefault() async {
    await backendUrlService.resetToDefault();
    await _applyActiveBaseUrl();
  }

  Future<void> _applyActiveBaseUrl() async {
    baseUrl = backendUrlService.baseUrl;

    authService.setBaseUrl(baseUrl);
    eventService.setBaseUrl(baseUrl);
    userService.setBaseUrl(baseUrl);
    fileService.setBaseUrl(baseUrl);
    commentService.setBaseUrl(baseUrl);
    aiService.setBaseUrl(baseUrl);
    sseConnectionService.setBaseUrl(baseUrl);

    await sseListenerService.stopListening();
    await sseListenerService.startListening();
    eventController.fetchAll();
  }
}

