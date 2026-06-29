package com.fhsocial.backend.Services;

import org.slf4j.Logger;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.nio.file.StandardCopyOption;
import java.time.Instant;
import java.util.List;
import java.util.Map;
import java.util.UUID;

import org.springframework.core.io.Resource;
import org.springframework.core.io.UrlResource;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import com.fhsocial.backend.DTO.FileDTO;
import com.fhsocial.backend.Entities.EventEntity;
import com.fhsocial.backend.Entities.FileEntity;
import com.fhsocial.backend.Repositories.EventRepository;
import com.fhsocial.backend.Repositories.FileRepository;

import org.slf4j.LoggerFactory;

@Service
public class FileService {

    private static final Path UPLOAD_DIR = Paths.get("/app/uploads");
    
    private static final int FILE_TIME_TO_LIVE = 3600;

    private FileRepository fileRepository;
    private EventRepository eventRepository;
    private Logger logger = LoggerFactory.getLogger(FileRepository.class);

    private FileDTO toDto(FileEntity fileEntity) {
        return new FileDTO(
            fileEntity.getId(),
            fileEntity.getEventId(),
            fileEntity.getOriginalFileName(),
            fileEntity.getSavedFileName(),
            fileEntity.getSize(),
            fileEntity.getCreatedAt(),
            fileEntity.isDeleted()
        );
    }

    private void pendFileDeletion(UUID fileId, int secondsUntilDeletion) {
        new Thread(() -> {
            try {
                Thread.sleep(secondsUntilDeletion * 1000L);
                FileEntity fileEntity = fileRepository.findById(fileId).orElse(null);
                if (fileEntity != null) {
                    Path filePath = UPLOAD_DIR.resolve(fileEntity.getSavedFileName());
                    try {
                        Files.deleteIfExists(filePath);
                        fileRepository.delete(fileEntity);
                        logger.info("Permanently deleted file with id={}", fileId);
                    } catch (Exception e) {
                        logger.error("Failed to delete file from filesystem: {}", filePath, e);
                    }
                }
            } catch (InterruptedException e) {
                logger.error("Error while waiting to delete file with id={}", fileId, e);
            }
        }).start();
    }

    private boolean saveFile(MultipartFile file, String savedFileName) {

        try {
            Files.createDirectories(UPLOAD_DIR);

            Path targetPath = UPLOAD_DIR.resolve(savedFileName);

            Files.copy(
                file.getInputStream(),
                targetPath,
                StandardCopyOption.REPLACE_EXISTING
            );
        } catch (IOException e) {
            logger.error("Failed to save file: {}", UPLOAD_DIR, e);
            return false;
        }
        return true;
    }

    public FileService(FileRepository fileRepository, EventRepository eventRepository) {
        this.fileRepository = fileRepository;
        this.eventRepository = eventRepository;
    }
    
    public ResponseEntity<Map<String, String>> uploadFile(MultipartFile file, UUID eventId, UUID authenticatedUserId) {
        UUID id = UUID.randomUUID();
        FileDTO fileDTO = new FileDTO(
            id,
            eventId,
            file.getOriginalFilename(),
            id + "_" + file.getOriginalFilename(),
            file.getSize(),
            Instant.now(),
            false
        );

        FileEntity fileEntity = new FileEntity();
        fileEntity.setId(fileDTO.id());
        fileEntity.setEventId(fileDTO.eventId());
        fileEntity.setOriginalFileName(fileDTO.originalFileName());
        fileEntity.setSavedFileName(fileDTO.savedFileName());
        fileEntity.setSize(fileDTO.size());

        boolean success = saveFile(file, fileDTO.savedFileName());
        if (success) {
            fileRepository.save(fileEntity);
            logger.info("Saved file with id={} for event with id={}", fileDTO.id(), fileDTO.eventId());
            return ResponseEntity.ok(Map.of("status", "saved", "fileId", fileDTO.id().toString()));
        } else {
            logger.error("Failed to save file with id={} for event with id={}", fileDTO.id(), fileDTO.eventId());
            return ResponseEntity.status(500).body(Map.of("error", "Failed to save file"));
        }
    }

    public ResponseEntity<Map<String, String>> deleteFile(UUID fileId, UUID authenticatedUserId) {

        try {
            FileEntity fileEntity = fileRepository.findById(fileId).orElse(null);
            if (fileEntity == null) {
                logger.warn("File with id={} not found for deletion request", fileId);
                return ResponseEntity.badRequest().body(Map.of("error", "File not found"));
            }
            EventEntity eventEntity = eventRepository.findById(fileEntity.getEventId()).orElse(null);
            if (eventEntity == null) {
                logger.warn("Event with id={} not found for file deletion request", fileEntity.getEventId());
                return ResponseEntity.badRequest().body(Map.of("error", "Event not found"));
            }
            if(!eventEntity.getUserId().equals(authenticatedUserId)) {
                logger.warn("User with id={} is not authorized to delete file with id={} for event with id={}", authenticatedUserId, fileId, eventEntity.getId());
                return ResponseEntity.status(403).body(Map.of("error", "Unauthorized"));
            }

            fileEntity.setDeleted(true);
            fileRepository.save(fileEntity);

            pendFileDeletion(fileId, FILE_TIME_TO_LIVE);
            return ResponseEntity.ok(Map.of("status", "deleted"));
        } catch (Exception e) {
            logger.error("Error processing file deletion request", e);
            return ResponseEntity.status(500).body(Map.of("error", "Internal server error"));
        }
    }

    public ResponseEntity<List<FileDTO>> getFilePreviews(UUID eventId, UUID authenticatedUserId) {
        List<FileDTO> files = fileRepository.findByEventIdAndDeletedFalse(eventId).stream()
            .map(this::toDto)
            .toList();
        logger.info("Fetched {} files for event with id={}", files.size(), eventId);
        return ResponseEntity.ok(files);
    }

    public ResponseEntity<Resource> downloadFile(UUID fileId, UUID authenticatedUserId) {
        FileEntity fileEntity = fileRepository.findById(fileId).orElse(null);
        if (fileEntity == null || fileEntity.isDeleted()) {
            logger.warn("File with id={} not found or is deleted", fileId);
            return ResponseEntity.notFound().build();
        }

        Path filePath = UPLOAD_DIR.resolve(fileEntity.getSavedFileName());
        if (!Files.exists(filePath)) {
            logger.error("File with id={} exists in database but not on filesystem: {}", fileId, filePath);
            return ResponseEntity.status(500).build();
        }

        try {
            UrlResource resource = new UrlResource(filePath.toUri());

            String contentType = Files.probeContentType(filePath);
                if (contentType == null) {
                    contentType = "application/octet-stream";
                }

            return ResponseEntity.ok()
                    .contentType(MediaType.parseMediaType(contentType))
                    .header(
                        "Content-Disposition",
                        "attachment; filename=\"" + fileEntity.getOriginalFileName() + "\""
                    )
                    .contentLength(fileEntity.getSize())
                    .body(resource);

        } catch (Exception e) {
            logger.error("Failed to load file {}", fileId, e);
            return ResponseEntity.internalServerError().build();
        }
    }
}
