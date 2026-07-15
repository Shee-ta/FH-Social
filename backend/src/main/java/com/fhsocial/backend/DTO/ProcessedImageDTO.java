package com.fhsocial.backend.DTO;

public record ProcessedImageDTO (
        int index,
        String container,
        String ocrText,
        String base64
) {}
