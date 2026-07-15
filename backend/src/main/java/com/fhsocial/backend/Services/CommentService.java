package com.fhsocial.backend.Services;

import org.slf4j.Logger;

import java.util.List;
import java.util.Map;
import java.util.UUID;

import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.fhsocial.backend.DTO.IdWithEventIdDTO;
import com.fhsocial.backend.DTO.IdWithCommentDTO;
import com.fhsocial.backend.DTO.SseDTO;
import com.fhsocial.backend.DTO.EntityDTO.CommentDTO;
import com.fhsocial.backend.Entities.CommentEntity;
import com.fhsocial.backend.Entities.EventEntity;
import com.fhsocial.backend.Entities.UserEntity;
import com.fhsocial.backend.Enums.SseType;
import com.fhsocial.backend.Repositories.CommentRepository;
import com.fhsocial.backend.Repositories.EventRepository;
import com.fhsocial.backend.Repositories.UserRepository;

import tools.jackson.databind.JsonNode;

import org.slf4j.LoggerFactory;

@Service
public class CommentService {

    private CommentRepository commentRepository;
    private EventRepository eventRepository;
    private UserRepository userRepository;
    private SseService sseService;

    private Logger logger = LoggerFactory.getLogger(CommentService.class);

    public CommentService(CommentRepository commentRepository, EventRepository eventRepository, UserRepository userRepository, SseService sseService) {
        this.commentRepository = commentRepository;
        this.eventRepository = eventRepository;
        this.userRepository = userRepository;
        this.sseService = sseService;
    }

    @Transactional
    public ResponseEntity<Map<String, String>> uploadComment(JsonNode comment, UUID authenticatedUserId) {
        try {
            String id = comment.get("id").asString();
            String eventId = comment.get("eventId").asString();

            CommentEntity commentEntity;

            UserEntity creator = userRepository.findById(authenticatedUserId).orElseThrow();
            EventEntity event = eventRepository.findById(UUID.fromString(eventId)).orElseThrow();

            if (id == null || id.isEmpty()) {
                commentEntity = new CommentEntity();
                commentEntity.setCreator(creator);
                commentEntity.setEvent(event);
            } else {
                commentEntity = commentRepository.findById(UUID.fromString(id)).orElseThrow();
                if (!commentEntity.getCreator().getId().equals(authenticatedUserId)) {
                    logger.warn("User with id={} attempted to edit comment with id={} without permission", authenticatedUserId, id);
                    return ResponseEntity.status(403).body(Map.of("error", "Insufficient privileges"));
                }
            }

            commentEntity.setContent(comment.get("content").asString());

            commentRepository.save(commentEntity);
            eventRepository.flush();

            sseService.sendSseEvent(new SseDTO<IdWithCommentDTO>(
                SseType.ADD_COMMENT,
                new IdWithCommentDTO(eventId, commentEntity.toDto())
            ));

            logger.info("Saved comment with id={}", commentEntity.getId());

            return ResponseEntity.ok(Map.of("status", "saved"));

        } catch (Exception e) {
            logger.warn("Error while saving comment", e);
            return ResponseEntity.badRequest().body(Map.of("error", "Error while saving comment"));
        }
    }

    @Transactional
    public ResponseEntity<Map<String, String>> deleteComment(UUID eventId, UUID commentId, UUID authenticatedUserId) {
        try {
            CommentEntity comment = commentRepository.findByIdAndEvent_Id(commentId, eventId).orElseThrow();

            if (!comment.getCreator().getId().equals(authenticatedUserId)) {
                logger.warn("User with id={} attempted to delete comment with id={} without permission", authenticatedUserId, commentId);
                return ResponseEntity.status(403).body(Map.of("error", "Insufficient privileges"));
            }

            EventEntity event = eventRepository.findById(eventId).orElseThrow();
            event.removeComment(comment);
            eventRepository.save(event);
            eventRepository.flush();

            sseService.sendSseEvent(new SseDTO<IdWithEventIdDTO>(
                SseType.REMOVE_COMMENT, 
                new IdWithEventIdDTO(commentId.toString(), eventId.toString())
            ));

            logger.info("Deleted comment with id={}", commentId);

            return ResponseEntity.ok(Map.of("status", "deleted"));

        } catch (Exception e) {
            logger.warn("Error while deleting comment with id={}", commentId, e);
            return ResponseEntity.badRequest().body(Map.of("error", "Error while deleting comment"));
        }
    }

    @Transactional(readOnly = true)
    public ResponseEntity<List<CommentDTO>> fetchCommentsByEvent(UUID eventId) {
        try {
            List<CommentDTO> comments = commentRepository.findByEvent_Id(eventId).stream()
                .map(CommentEntity::toDto)
                .toList();
            logger.info("Fetched {} comments for event with id={}", comments.size(), eventId);
            return ResponseEntity.ok(comments);
        } catch (Exception e) {
            logger.warn("Error while retrieving comments for event with id={}", eventId, e);
            return ResponseEntity.badRequest().body(null);
        }
    }

    @Transactional(readOnly = true)
    public ResponseEntity<CommentDTO> fetchCommentById(UUID eventId, UUID commentId) {
        try {
            CommentEntity comment = commentRepository.findByIdAndEvent_Id(commentId, eventId).orElseThrow();
            CommentDTO commentDTO = comment.toDto();
            return ResponseEntity.ok(commentDTO);
        } catch (Exception e) {
            logger.warn("Error while fetching comment with id={}", commentId, e);
            return ResponseEntity.badRequest().body(null);
        }
    }
}
