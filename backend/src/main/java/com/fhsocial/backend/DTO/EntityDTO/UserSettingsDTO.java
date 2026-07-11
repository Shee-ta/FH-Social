package com.fhsocial.backend.DTO.EntityDTO;

public record UserSettingsDTO(
    String brightness,
    String themeColor,
    boolean iconButtons
) {}
