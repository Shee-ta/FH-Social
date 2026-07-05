package com.fhsocial.backend.Controllers;

import com.fhsocial.backend.DTO.CommentDTO;
import com.fhsocial.backend.DTO.EventDTO;
import com.fhsocial.backend.DTO.FileDTO;
import com.fhsocial.backend.DTO.LoginRequestDTO;
import com.fhsocial.backend.DTO.UserDTO;
import com.fhsocial.backend.Services.AiService;
import com.fhsocial.backend.Services.AuthService;
import com.fhsocial.backend.Services.CommentService;
import com.fhsocial.backend.Services.EventService;
import com.fhsocial.backend.Services.FileService;
import com.fhsocial.backend.Services.UserService;

import tools.jackson.databind.JsonNode;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
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
import java.time.Instant;
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

    private Logger logger = LoggerFactory.getLogger(RouteController.class);

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

    @PostMapping("/upload/event/changeMember")
    public ResponseEntity<Map<String, String>> changeMember(
        @RequestBody JsonNode changeMemberRequest,
        Principal principal
    ) throws IllegalArgumentException {
        UUID authenticatedUserId = UUID.fromString(principal.getName());
        return eventService.changeMember(changeMemberRequest, authenticatedUserId);
    }

    @GetMapping("/events/all")
    public ResponseEntity<List<EventDTO>> getEventsAll() {
        return eventService.getEventsAll();
    }

    @GetMapping("/events/since")
    public ResponseEntity<List<EventDTO>> getEventsSince(
        @RequestParam Instant timeStamp
    ) {
        return eventService.getEventsSince(timeStamp);
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

    @GetMapping("/comments/all")
    public ResponseEntity<List<CommentDTO>> getCommentsAll() {
        return commentService.getCommentsAll();
    }

    @GetMapping("/comments/since")
    public ResponseEntity<List<CommentDTO>> getCommentsSince(
        @RequestParam Instant timeStamp
    ) {
        return commentService.getCommentsSince(timeStamp);
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

    @GetMapping("/users/all")
    public ResponseEntity<List<UserDTO>> getUsersAll() {
        logger.info("Fetching all users");
        return userService.getUsersAll();
    }

    @GetMapping("/users/since")
    public ResponseEntity<List<UserDTO>> getUsersSince(
        @RequestParam Instant timeStamp
    ) {
        return userService.getUsersSince(timeStamp);
    }

    @GetMapping("/users/byId")
    public ResponseEntity<UserDTO> getUserById(
        @RequestParam UUID userId
    ) {
        return userService.getUserById(userId);
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

    @PostMapping("/file/delete")
    public ResponseEntity<Map<String, String>> deleteFile(
        @RequestParam String fileIdStr,
        Principal principal
    ) throws IllegalArgumentException {
        UUID authenticatedUserId = UUID.fromString(principal.getName());
        UUID fileId = UUID.fromString(fileIdStr);
        return fileService.deleteFile(fileId, authenticatedUserId);
    }

    @GetMapping("/file/previews")
    public ResponseEntity<List<FileDTO>> getFilePreviews(
        @RequestParam String eventIdStr,
        Principal principal
    ) throws IllegalArgumentException{
        UUID authenticatedUserId = UUID.fromString(principal.getName());
        UUID eventId = UUID.fromString(eventIdStr);
        return fileService.getFilePreviews(eventId, authenticatedUserId);
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
