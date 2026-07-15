package com.fhsocial.backend.DTO;

import java.util.UUID;

public record ChangeMemberDTO(
    UUID eventId,
    boolean isAdded
) {}
