package com.fhsocial.backend.DTO.EntityDTO;

import java.util.List;
import java.util.UUID;

public record EventDTO(
    UUID id,
    UserDTO creator,
    String title,
    String iso8601startDateTime,
    String iso8601endDateTime,
    String location,
    String description,
    String recommendation,
    double latitude,
    double longitude,
    List<String> days,
    List<String> tags,
    List<UserDTO> members,
    String createdAt,
    String editedAt
) {}