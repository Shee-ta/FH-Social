package com.fhsocial.backend.DTO;

import com.fhsocial.backend.DTO.EntityDTO.FilePreviewDTO;

public record IdWithFilePreviewDTO (
    String eventId, 
    FilePreviewDTO filePreview
) {}  
