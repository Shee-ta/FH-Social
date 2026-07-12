
import 'package:flutter/material.dart';
import 'package:frontend/di/app_di.dart';
import 'package:frontend/dto/change_member_dto.dart';
import 'package:frontend/dto/comment_dto.dart';
import 'package:frontend/entity/comment.dart';
import 'package:frontend/entity/event.dart';
import 'package:frontend/entity/file_preview.dart';
import 'package:frontend/entity/user.dart';
import 'package:frontend/services/ai_service.dart';
import 'package:frontend/services/auth_service.dart';
import 'package:frontend/services/entity_services/comment_service.dart';
import 'package:frontend/services/entity_services/file_service.dart';
import 'package:frontend/services/entity_services/user_service.dart';
import 'package:frontend/services/ui_feedback_service.dart';
import 'package:http/http.dart';

class EventEntitiesController extends ChangeNotifier {
  final AuthService authService;
  final UserService userService;
  final FileService fileService;
  final CommentService commentService;
  final AiService aiService;

  final Event event;

  EventEntitiesController({
    required this.event,
  })  : authService = AppDI.instance.authService,
        userService = AppDI.instance.userService,
        fileService = AppDI.instance.fileService,
        commentService = AppDI.instance.commentService,
        aiService = AppDI.instance.aiService;

  bool _isLoadingUsers = false;
  bool get isLoadingUsers => _isLoadingUsers;

  bool _isLoadingFiles = false;
  bool get isLoadingFiles => _isLoadingFiles;

  bool _isLoadingComments = false;
  bool get isLoadingComments => _isLoadingComments;

  bool _isUploadingFile = false;
  bool get isUploadingFile => _isUploadingFile;

  bool _isDeletingFile = false;
  bool get isDeletingFile => _isDeletingFile;

  bool _isUploadingComment = false;
  bool get isUploadingComment => _isUploadingComment;

  bool _isUploadingEditedComment = false;
  bool get isUploadingEditedComment => _isUploadingEditedComment;

  bool _isDeletingComment = false;
  bool get isDeletingComment => _isDeletingComment;

  bool _isAiGenerating = false;
  bool get isAiGenerating => _isAiGenerating;

  bool _isChangingMembership = false;
  bool get isChangingMembership => _isChangingMembership;

  bool _isDeleted = false;
  bool get isDeleted => _isDeleted;

  // --- STATUS SETTERS --- //
  void _setIsLoadingUsers(bool value) {
    if (_isLoadingUsers == value) {
      return;
    }
    _isLoadingUsers = value;
    notifyListeners();
  }

  void _setIsLoadingFiles(bool value) {
    if (_isLoadingFiles == value) {
      return;
    }
    _isLoadingFiles = value;
    notifyListeners();
  }

  void _setIsDeletingFile(bool value) {
    if (_isDeletingFile == value) {
      return;
    }
    _isDeletingFile = value;
    notifyListeners();
  }

  void _setIsUploadingFile(bool value) {
    if (_isUploadingFile == value) {
      return;
    }
    _isUploadingFile = value;
    notifyListeners();
  }

  void _setIsLoadingComments(bool value) {
    if (_isLoadingComments == value) {
      return;
    }
    _isLoadingComments = value;
    notifyListeners();
  }

  void setIsUploadingComment(bool value) {
    if (_isUploadingComment == value) {
      return;
    }
    _isUploadingComment = value;
    notifyListeners();
  }

  void _setIsUploadingEditedComment(bool value) {
    if (_isUploadingEditedComment == value) {
      return;
    }
    _isUploadingEditedComment = value;
    notifyListeners();
  }

  void setIsDeletingComment(bool value) {
    if (_isDeletingComment == value) {
      return;
    }
    _isDeletingComment = value;
    notifyListeners();
  }

  void _setIsAiGenerating(bool value) {
    if (_isAiGenerating == value) {
      return;
    }
    _isAiGenerating = value;
    notifyListeners();
  }

  void _setIsChangingMembership(bool value) {
    if (_isChangingMembership == value) {
      return;
    }
    _isChangingMembership = value;
    notifyListeners();
  }

  void setEventDeleted() {
    _isDeleted = true;
    notifyListeners();
  }

  // --- ASSEMBLY LOGIC --- //
  void addComment(Comment comment) {
    final index = event.comments.indexWhere((c) => c.id == comment.id); 
    if (index == -1) {
      event.comments.add(comment);
    }
    else {
      event.comments[index] = comment;
    }
    notifyListeners();
  }
  void removeComment(String id) {
    final index = event.comments.indexWhere((c) => c.id == id);
    if (index != -1) {
      event.comments.removeAt(index);
      notifyListeners();
    }
  }

  void addMember(User member) {
    final index = event.members.indexWhere((m) => m.id == member.id);
    if (index == -1) {
      event.members.add(member);
    }
    else {
      event.members[index] = member;
    }
    notifyListeners();
  }
  void removeMember(String id) {
    final index = event.members.indexWhere((m) => m.id == id);
    if (index != -1) {
      event.members.removeAt(index);
      notifyListeners();
    }
  }

  void addFilePreview(FilePreview file) {
    final index = event.filePreviews.indexWhere((f) => f.id == file.id);
    if (index == -1) {
      event.filePreviews.add(file);
    }
    else {
      event.filePreviews[index] = file;
    }
    notifyListeners();
  }
  
  void removeFilePreview(String id) {
    final index = event.filePreviews.indexWhere((f) => f.id == id);
    if (index != -1) {
      event.filePreviews.removeAt(index);
      notifyListeners();
    }
  }

  // --- FETCH LOGIC --- //
  Future<void> fetchEventEntities(String eventId) async {
    Future.wait(
      [
        _fetchEventMembers(eventId),
        _fetchEventFiles(eventId),
        _fetchEventComments(eventId),
      ],
    ).whenComplete(() => notifyListeners());
  }

  Future<void> _fetchEventMembers(String eventId) async {
    _setIsLoadingUsers(true);
    await userService.fetchEventMembers(eventId).then(  
      (usersDTOs) {
        final users = usersDTOs.map((userDTO) => User(userDTO)).toList();
        event.members.clear();
        event.members.addAll(users);
        _setIsLoadingUsers(false);
      },
    ).whenComplete(() => _setIsLoadingUsers(false));
  }

  Future<void> _fetchEventFiles(String eventId) async {
    _setIsLoadingFiles(true);
    await fileService.fetchEventFilePreviews(eventId).then(
      (filesDTOs) {
        final files = filesDTOs.map((fileDTO) => FilePreview(fileDTO)).toList();
        event.filePreviews.clear();
        event.filePreviews.addAll(files);
      },
    ).whenComplete(() => _setIsLoadingFiles(false));
  }

  Future<void> _fetchEventComments(String eventId) async {
    _setIsLoadingComments(true);
    await commentService.fetchEventComments(eventId).then(
      (commentDTOs) {
        final comments = commentDTOs.map((commentDTO) => Comment(commentDTO)).toList();
        event.comments.clear();
        event.comments.addAll(comments);
      },
    ).whenComplete(() => _setIsLoadingComments(false));
  }

  // --- USER ACTIONS --- //
  Future<bool> downloadFile(String fileId, String fileName) async {
    _setIsLoadingFiles(true);

    final accessToken = await authService.getAccessToken();
    final success = await fileService.downloadFile(fileId, fileName, accessToken);
    
    _setIsLoadingFiles(false);
    return success;
  }

  Future<bool> changeEventMembership(ChangeMemberDTO changeMemberDTO) async {
    if (_isChangingMembership) {
      return false;
    }

    _setIsChangingMembership(true);

    final accessToken = await authService.getAccessToken();
    final success = await userService.changeEventMembership(changeMemberDTO, accessToken);

    if(!success) {
      UIfeedbackService.notification(
        message: "Failed to change event membership",
        type: NotificationType.error
      );
    }
    _setIsChangingMembership(false);
    return success;
  }

  Future<bool> uploadComment(CommentDTO commentDTO, {bool isEditing = false}) async {
    isEditing ? _setIsUploadingEditedComment(true) : setIsUploadingComment(true);
    final accessToken = await authService.getAccessToken();
    final success = await commentService.uploadComment(commentDTO, accessToken);

    if(!success) {
      UIfeedbackService.notification(
        message: "Failed to upload comment",
        type: NotificationType.error
      );
    }
    isEditing ? _setIsUploadingEditedComment(false) : setIsUploadingComment(false);
    return success;
  }

  Future<bool> deleteComment(String eventId, String commentId) async {
    setIsDeletingComment(true);

    final accessToken = await authService.getAccessToken();
    final success = await commentService.deleteComment(eventId, commentId, accessToken);

    if(!success) {
      UIfeedbackService.notification(
        message: "Failed to delete comment",
        type: NotificationType.error
      );
    }
    setIsDeletingComment(false);
    return success;
  }

  Future<bool> uploadFile(MultipartFile file, String eventId) async {
    _setIsUploadingFile(true);

    final accessToken = await authService.getAccessToken();
    final success = await fileService.uploadFile(file, eventId, accessToken);

    if(!success) {
      UIfeedbackService.notification(
        message: "Failed to upload file",
        type: NotificationType.error
      );
    }
    _setIsUploadingFile(false);
    return success;
  }

  Future<bool> deleteFile(String fileId) async {
    _setIsDeletingFile(true);
    final accessToken = await authService.getAccessToken();
    final success = await fileService.deleteFile(fileId, accessToken);

    if(!success) {
      UIfeedbackService.notification(
        message: "Failed to delete file",
        type: NotificationType.error
      );
    }
    _setIsDeletingFile(false);
    return success;
  }

  Future<void> generateRecommendation(String eventId) async {
    _setIsAiGenerating(true);

    final accessToken = await authService.getAccessToken();
    final success = await aiService.generateRecommendation(eventId, accessToken);

    if(!success) {
      UIfeedbackService.notification(
        message: "Failed to generate recommendation",
        type: NotificationType.error
      );
    }
    _setIsAiGenerating(false);
  }

  Future<void> generateTags(String eventId) async {
    _setIsAiGenerating(true);

    final accessToken = await authService.getAccessToken();
    final success = await aiService.generateTags(eventId, accessToken);

    if(!success) {
      UIfeedbackService.notification(
        message: "Failed to generate tags",
        type: NotificationType.error
      );
    }
    _setIsAiGenerating(false);
  }
}