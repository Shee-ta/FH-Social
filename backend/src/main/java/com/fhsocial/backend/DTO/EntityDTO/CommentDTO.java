package com.fhsocial.backend.DTO.EntityDTO;

import java.util.UUID;

public record CommentDTO(
    UUID id,
    UUID eventId,
    UserDTO creator,
    String content,
    String createdAt,
    String editedAt
) {}
