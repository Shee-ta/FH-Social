package com.fhsocial.backend.DTO;

import java.util.List;

public record ProcessedFileDTO(
        List<FileChunkDTO> chunks,
        List<ProcessedImageDTO> images
) {}
