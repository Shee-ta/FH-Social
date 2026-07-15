package com.fhsocial.backend.DTO.EntityDTO;

import java.time.Instant;
import java.util.UUID;

public record FilePreviewDTO (
    UUID id,
    String originalFileName,
    String savedFileName,
    Long size,
    Instant createdAt
) {}

