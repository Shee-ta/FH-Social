package com.fhsocial.backend.DTO;

import com.fhsocial.backend.DTO.EntityDTO.UserDTO;

public record LoginResponseDTO(
    String token,
    UserDTO user
) {}
