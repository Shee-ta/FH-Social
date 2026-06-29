package com.fhsocial.backend.DTO;

import java.time.Instant;
import java.util.UUID;

public record FileDTO (
    UUID id,
    UUID eventId,
    String originalFileName,
    String savedFileName,
    Long size,
    Instant createdAt,
    boolean deleted
) {}

