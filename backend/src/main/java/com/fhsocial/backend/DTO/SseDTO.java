package com.fhsocial.backend.DTO;

import com.fhsocial.backend.Enums.SseType;

public record SseDTO<T>(
    SseType type,
    T dto
) {}
