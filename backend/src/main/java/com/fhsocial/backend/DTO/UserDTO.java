package com.fhsocial.backend.DTO;

import java.util.UUID;

public record UserDTO(
    UUID id,
    String username,
    String displayname,
    String role,
    boolean deleted
) {}
