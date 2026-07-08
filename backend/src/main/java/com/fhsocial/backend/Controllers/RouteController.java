package com.fhsocial.backend.Controllers;

import com.fhsocial.backend.DTO.LoginRequestDTO;
import com.fhsocial.backend.DTO.EntityDTO.CommentDTO;
import com.fhsocial.backend.DTO.EntityDTO.EventDTO;
import com.fhsocial.backend.DTO.EntityDTO.FilePreviewDTO;
import com.fhsocial.backend.DTO.EntityDTO.UserDTO;
import com.fhsocial.backend.Services.AiService;
import com.fhsocial.backend.Services.AuthService;
import com.fhsocial.backend.Services.CommentService;
import com.fhsocial.backend.Services.EventService;
import com.fhsocial.backend.Services.FileService;
import com.fhsocial.backend.Services.UserService;

import tools.jackson.databind.JsonNode;

import org.springframework.core.io.Resource;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.CrossOrigin;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MultipartFile;

import java.security.Principal;
import java.util.List;
import java.util.Map;
import java.util.UUID;

@RestController
@CrossOrigin(origins = "*")
public class RouteController {

    private final EventService eventService;
    private final CommentService commentService;
    private final AuthService authService;
    private final UserService userService;
    private final FileService fileService;
    private final AiService aiService;

    public RouteController(EventService eventService, CommentService commentService, AuthService authService, UserService userService, FileService fileService, AiService aiService) {
        this.eventService = eventService;
        this.commentService = commentService;
        this.authService = authService;
        this.userService = userService;
        this.fileService = fileService;
        this.aiService = aiService;
    }

    // --- EVENT ENDPOINTS --- //
    @PostMapping("/upload/event")
    public ResponseEntity<Map<String, String>> receiveEvent(
        @RequestBody JsonNode event,
        Principal principal
    ) throws IllegalArgumentException {
        UUID authenticatedUserId = UUID.fromString(principal.getName());
        return eventService.uploadEvent(event, authenticatedUserId);
    }

    @PostMapping("/delete/event")
    public ResponseEntity<Map<String, String>> deleteEvent(
        @RequestParam String eventIdStr,
        Principal principal
    ) throws IllegalArgumentException {
        UUID authenticatedUserId = UUID.fromString(principal.getName());
        UUID eventId = UUID.fromString(eventIdStr);
        return eventService.deleteEvent(eventId, authenticatedUserId);
    }

    @GetMapping("/events/all")
    public ResponseEntity<List<EventDTO>> getEventsAll() {
        return eventService.getEventsAll();
    }

    @GetMapping("/events/by-id")
    public ResponseEntity<EventDTO> getEventById(
        @RequestParam String eventIdStr
    ) {
        UUID eventId = UUID.fromString(eventIdStr);
        return eventService.getEventById(eventId);
    }

    // --- COMMENT ENDPOINTS --- //
    @PostMapping("/upload/comment")
    public ResponseEntity<Map<String, String>> receiveComment(
        @RequestBody JsonNode comment,
        Principal principal
    ) throws IllegalArgumentException {
        UUID authenticatedUserId = UUID.fromString(principal.getName());
        return commentService.uploadComment(comment, authenticatedUserId);
    }

    @PostMapping("/delete/comment")
    public ResponseEntity<Map<String, String>> deleteComment(
        @RequestParam String eventIdStr,
        @RequestParam String commentIdStr,
        Principal principal
    ) throws IllegalArgumentException {
        UUID authenticatedUserId = UUID.fromString(principal.getName());
        UUID eventId = UUID.fromString(eventIdStr);
        UUID commentId = UUID.fromString(commentIdStr);
        return commentService.deleteComment(eventId, commentId, authenticatedUserId);
    }

    @GetMapping("/comments/by-event")
    public ResponseEntity<List<CommentDTO>> getCommentsByEvent(
        @RequestParam String eventIdStr
    ) {
        UUID eventId = UUID.fromString(eventIdStr);
        return commentService.fetchCommentsByEvent(eventId);
    }

    @GetMapping("/comments/by-id")
    public ResponseEntity<CommentDTO> getCommentById(
        @RequestParam String eventIdStr,
        @RequestParam String commentIdStr
    ) {
        UUID eventId = UUID.fromString(eventIdStr);
        UUID commentId = UUID.fromString(commentIdStr);
        return commentService.fetchCommentById(eventId, commentId);
    }

    // --- USER ENDPOINTS --- //
    @PostMapping("/upload/user")
    public ResponseEntity<Map<String, String>> receiveUser(
        @RequestBody JsonNode user,
        Principal principal
    ) throws IllegalArgumentException {
        UUID authenticatedUserId = UUID.fromString(principal.getName());
        return userService.uploadUser(user, authenticatedUserId);
    }

    @PostMapping("/delete/user")
    public ResponseEntity<Map<String, String>> deleteUser(
        @RequestParam String userIdStr,
        Principal principal
    ) throws IllegalArgumentException {
        UUID authenticatedUserId = UUID.fromString(principal.getName());
        UUID userId = UUID.fromString(userIdStr);
        return userService.deleteUser(userId, authenticatedUserId);
    }

    @PostMapping("/upload/user/member-change")
    public ResponseEntity<Map<String, String>> changeMember(
        @RequestBody JsonNode changeMemberRequest,
        Principal principal
    ) throws IllegalArgumentException {
        UUID authenticatedUserId = UUID.fromString(principal.getName());
        return userService.changeMembership(changeMemberRequest, authenticatedUserId);
    }

     @GetMapping("/users/by-event")
    public ResponseEntity<List<UserDTO>> fetchUsersByEvent(
        @RequestParam String eventIdStr
    ) {
        UUID eventId = UUID.fromString(eventIdStr);
        return userService.fetchUsersByEvent(eventId);
    }

    @GetMapping("/users/by-id")
    public ResponseEntity<UserDTO> fetchUserById(
        @RequestParam String userIdStr
    ) {
        UUID userId = UUID.fromString(userIdStr);
        return userService.fetchUserById(userId);
    }

    // --- FILE ENDPOINTS --- //
    @PostMapping("/upload/file")
    public ResponseEntity<Map<String, String>> receiveFile(
        @RequestParam("file") MultipartFile file,
        @RequestParam("eventIdStr") String eventIdStr,
        Principal principal
    ) throws IllegalArgumentException {
        UUID authenticatedUserId = UUID.fromString(principal.getName());
        UUID eventId = UUID.fromString(eventIdStr);
        return fileService.uploadFile(file, eventId, authenticatedUserId);
    }

    @PostMapping("/delete/file")
    public ResponseEntity<Map<String, String>> deleteFile(
        @RequestParam String fileIdStr,
        Principal principal
    ) throws IllegalArgumentException {
        UUID authenticatedUserId = UUID.fromString(principal.getName());
        UUID fileId = UUID.fromString(fileIdStr);
        return fileService.deleteFile(fileId, authenticatedUserId);
    }

    @GetMapping("/file/previews/by-event")
    public ResponseEntity<List<FilePreviewDTO>> fetchFilePreviewsByEvent(
        @RequestParam String eventIdStr
    ) {
        UUID eventId = UUID.fromString(eventIdStr);
        return fileService.fetchFilePreviewsByEvent(eventId);
    }

    @GetMapping("/file/previews/by-id")
    public ResponseEntity<FilePreviewDTO> fetchFilePreviewById(
        @RequestParam String fileIdStr
    ) throws IllegalArgumentException {
        UUID fileId = UUID.fromString(fileIdStr);
        return fileService.fetchFilePreviewById(fileId);
    }

    @GetMapping("/file/download")
    public ResponseEntity<Resource> downloadFile(
        @RequestParam String fileIdStr,
        Principal principal
    ) throws IllegalArgumentException {
        UUID authenticatedUserId = UUID.fromString(principal.getName());
        UUID fileId = UUID.fromString(fileIdStr);
        return fileService.downloadFile(fileId, authenticatedUserId);
    }
    
    // --- AI ENDPOINTS --- //
    @PostMapping("/ai/generate-recommendation")
    public ResponseEntity<Map<String, String>> generateRecommendation(
        @RequestParam String eventIdStr,
        Principal principal
    ) throws IllegalArgumentException {
        UUID authenticatedUserId = principal != null ? UUID.fromString(principal.getName()) : null;
        UUID eventId = UUID.fromString(eventIdStr);
        return aiService.generateRecommendation(eventId, authenticatedUserId);
    }

    @PostMapping("/ai/generate-tags")
    public ResponseEntity<Map<String, String>> generateTags(
        @RequestParam String eventIdStr,
        Principal principal
    ) throws IllegalArgumentException {
        UUID authenticatedUserId = principal != null ? UUID.fromString(principal.getName()) : null;
        UUID eventId = UUID.fromString(eventIdStr);
        return aiService.generateTags(eventId, authenticatedUserId);
    }

    // --- AUTH ENDPOINTS --- //
    @PostMapping("/auth/login")
    public ResponseEntity<?> login(
        @RequestBody LoginRequestDTO request
    ) {
        return authService.login(request.username(), request.password());
    }

    @PostMapping("/auth/logout")
    public ResponseEntity<Map<String, String>> logout(
    ) {
        return authService.logout();
    }
}
