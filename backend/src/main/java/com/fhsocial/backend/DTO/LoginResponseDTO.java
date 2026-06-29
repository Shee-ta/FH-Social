package com.fhsocial.backend.DTO;

public record LoginResponseDTO(
    String token,
    UserDTO user
) {}
