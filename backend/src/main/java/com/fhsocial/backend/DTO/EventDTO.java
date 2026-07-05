package com.fhsocial.backend.DTO;

import java.util.List;
import java.util.UUID;

public record EventDTO(
    UUID id,
    UUID userId,
    String title,
    String iso8601startDateTime,
    String iso8601endDateTime,
    String location,
    String description,
    String recommendation,
    double latitude,
    double longitude,
    List<String> days,
    List<String> memberIDs,
    List<String> tags,
    boolean deleted
) {}