package com.fhsocial.backend.DTO.EntityDTO;

import java.util.UUID;

public record UserDTO(
    UUID id,
    String username,
    String displayname,
    String role,
    String createdAt,
    String editedAt
) {}
