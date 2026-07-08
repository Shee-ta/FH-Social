package com.fhsocial.backend.DTO;

import com.fhsocial.backend.DTO.EntityDTO.CommentDTO;

public record IdWithCommentDTO (
    String eventId, 
    CommentDTO comment
) {}
