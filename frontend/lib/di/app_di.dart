import 'package:frontend/controller/auth_controller.dart';
import 'package:frontend/controller/event_controller.dart';
import 'package:frontend/environment/environment.dart';
import 'package:frontend/services/ai_service.dart';
import 'package:frontend/services/auth_service.dart';
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

  late final String baseUrl;

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

  void init() {
    if (_isInitialized) {
      return;
    }

    baseUrl = Environment.getBaseUrl();

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
}
