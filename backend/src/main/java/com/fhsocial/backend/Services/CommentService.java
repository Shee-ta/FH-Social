package com.fhsocial.backend.Services;

import org.slf4j.Logger;

import java.time.Instant;
import java.util.List;
import java.util.Map;
import java.util.UUID;

import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Service;

import com.fhsocial.backend.DTO.CommentDTO;
import com.fhsocial.backend.Entities.CommentEntity;
import com.fhsocial.backend.Repositories.CommentRepository;

import tools.jackson.databind.JsonNode;

import org.slf4j.LoggerFactory;

@Service
public class CommentService {

    private static final int COMMENT_TIME_TO_LIVE = 3600;

    private CommentRepository commentRepository;
    private Logger logger = LoggerFactory.getLogger(CommentService.class);

    private CommentDTO toDto(CommentEntity commentEntity) {
        return new CommentDTO(
            commentEntity.getId(),
            commentEntity.getUserId(),
            commentEntity.getEventId(),
            commentEntity.getContent(),
            commentEntity.getCreatedAt().toString(),
            commentEntity.getEditedAt().toString(),
            commentEntity.getDeleted()
        );
    }

    private void pendCommentDeletion(UUID commentId, int secondsUntilDeletion) {
        new Thread(() -> {
            try {
                Thread.sleep(secondsUntilDeletion * 1000L);
                CommentEntity commentEntity = commentRepository.findById(commentId).orElse(null);
                if (commentEntity != null && commentEntity.getDeleted()) {
                    commentRepository.delete(commentEntity);
                    logger.info("Permanently deleted comment with id={}", commentId);
                }
            } catch (InterruptedException e) {
                logger.error("Error while waiting to delete comment with id={}", commentId, e);
            }
        }).start();
    }

    public CommentService(CommentRepository commentRepository) {
        this.commentRepository = commentRepository;
    }

    public ResponseEntity<Map<String, String>> uploadComment(JsonNode comment, UUID authenticatedUserId) {
        try {
            CommentDTO commentDTO = new CommentDTO(
                UUID.fromString(comment.get("id").asString()),
                authenticatedUserId,
                UUID.fromString(comment.get("eventId").asString()),
                comment.get("content").asString(),
                comment.get("createdAt").asString(),
                comment.get("editedAt").asString(),
                comment.get("deleted").asBoolean()
            );
            if(commentDTO.deleted()) {
                logger.info("Deleted comment with id={}, pending deletion in {} seconds", commentDTO.id(), COMMENT_TIME_TO_LIVE);
                pendCommentDeletion(commentDTO.id(), COMMENT_TIME_TO_LIVE);
            }


            CommentEntity commentEntity = commentRepository.findById(commentDTO.id()).orElseGet(CommentEntity::new);
            if (commentEntity.getId() == null) {
                commentEntity.setId(commentDTO.id());
            }
            commentEntity.setUserId(commentDTO.userId());
            commentEntity.setEventId(commentDTO.eventId());
            commentEntity.setContent(commentDTO.content());
            commentEntity.setDeleted(commentDTO.deleted());

            commentRepository.save(commentEntity);
            
            logger.debug("Mapped CommentDTO: {}", commentDTO);
            logger.info("Saved comment with id={}", commentDTO.id());

            return ResponseEntity.ok(Map.of("status", "saved"));

        } catch (IllegalArgumentException e) {
            logger.warn("Invalid UUID in comment payload", e);
            return ResponseEntity.badRequest().body(Map.of("error", "Invalid UUID format"));
        }
    }

    public ResponseEntity<List<CommentDTO>> getCommentsAll() {
        List<CommentDTO> comments = commentRepository.findAll().stream()
            .map(this::toDto)
            .toList();
        logger.info("Fetched {} comments", comments.size());
        return ResponseEntity.ok(comments);
    }

    public ResponseEntity<List<CommentDTO>> getCommentsSince(Instant timeStamp) {
        List<CommentDTO> comments = commentRepository.findByCreatedAtAfterOrEditedAtAfter(timeStamp, timeStamp).stream()
            .map(this::toDto)
            .toList();
        logger.info("Fetched {} comments since {}", comments.size(), timeStamp);
        return ResponseEntity.ok(comments);
    }
}
