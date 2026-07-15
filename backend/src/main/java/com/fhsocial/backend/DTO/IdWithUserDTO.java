package com.fhsocial.backend.DTO;

import com.fhsocial.backend.DTO.EntityDTO.UserDTO;

public record IdWithUserDTO(
    String eventId, 
    UserDTO user
) {}