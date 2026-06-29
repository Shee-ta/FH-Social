package com.fhsocial.backend.DTO;

import java.util.UUID;

public record CommentDTO(
    UUID id,
    UUID userId,
    UUID eventId,
    String content,
    String createdAt,
    String editedAt,
    boolean deleted
) {}
