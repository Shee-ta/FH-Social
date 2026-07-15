package com.fhsocial.backend.Services;

import org.slf4j.Logger;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.nio.file.StandardCopyOption;
import java.util.List;
import java.util.Map;
import java.util.UUID;

import org.springframework.core.io.Resource;
import org.springframework.core.io.UrlResource;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

import com.fhsocial.backend.DTO.IdWithEventIdDTO;
import com.fhsocial.backend.DTO.IdWithFilePreviewDTO;
import com.fhsocial.backend.DTO.ProcessedFileDTO;
import com.fhsocial.backend.DTO.SseDTO;
import com.fhsocial.backend.DTO.EntityDTO.FilePreviewDTO;
import com.fhsocial.backend.Entities.EventEntity;
import com.fhsocial.backend.Entities.FilePreviewEntity;
import com.fhsocial.backend.Enums.SseType;
import com.fhsocial.backend.Repositories.EventRepository;
import com.fhsocial.backend.Repositories.FileRepository;

import tools.jackson.databind.ObjectMapper;

import org.slf4j.LoggerFactory;

@Service
public class FileService {

    private static final Path UPLOAD_DIR = Paths.get("/app/uploads");

    private FileRepository fileRepository;
    private FileProcessorService fileProcessorService;
    private EventRepository eventRepository;
    private ObjectMapper objectMapper;
    private SseService sseService;

    private Logger logger = LoggerFactory.getLogger(FileService.class);

    private boolean saveFileInSystem(MultipartFile file, String savedFileName) {

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

    private boolean removeFileFromSystem(String savedFileName) {
        try {
            Path targetPath = UPLOAD_DIR.resolve(savedFileName);
            return Files.deleteIfExists(targetPath);
        } catch (IOException e) {
            logger.error("Failed to delete file: {}", savedFileName, e);
            return false;
        }
    }

    public FileService(FileRepository fileRepository, FileProcessorService fileProcessorService, EventRepository eventRepository, ObjectMapper objectMapper, SseService sseService) {
        this.fileRepository = fileRepository;
        this.fileProcessorService = fileProcessorService; 
        this.eventRepository = eventRepository;
        this.objectMapper = objectMapper;
        this.sseService = sseService;
    }
    
    @Transactional
    public ResponseEntity<Map<String, String>> uploadFile(MultipartFile file, UUID eventId, UUID authenticatedUserId) {
        try {
            EventEntity event = eventRepository.findById(eventId).orElseThrow();
            if (!event.getUserId().equals(authenticatedUserId)) {
                logger.warn("User with id={} attempted to upload file for event with id={} without permission", authenticatedUserId, eventId);
                return ResponseEntity.status(403).body(Map.of("error", "Insufficient privileges"));
            }

            FilePreviewEntity fileEntity = new FilePreviewEntity();
            fileEntity.setEvent(event);
            fileEntity.setOriginalFileName(file.getOriginalFilename());
            fileEntity.setSavedFileName(eventId + "_" + file.getOriginalFilename());
            fileEntity.setSize(file.getSize());

            boolean success = saveFileInSystem(file, fileEntity.getSavedFileName());
            if (!success) {
                logger.error("Failed to save file for event with id={}", eventId);
                return ResponseEntity.badRequest().body(Map.of("error", "Failed to save file"));
            }

            try {
                ProcessedFileDTO processed = fileProcessorService.process(file);
                String processedFileStr = objectMapper.writeValueAsString(processed);
                fileEntity.setPreprocessedContent(processedFileStr);
            } catch (Exception e) {
                removeFileFromSystem(fileEntity.getSavedFileName());
                logger.warn("Failed to process file for event with id={}", eventId, e);
                return ResponseEntity.badRequest().body(Map.of("error", "Failed to process file"));
            }

            fileRepository.save(fileEntity);
            fileRepository.flush();

            sseService.sendSseEvent(new SseDTO<IdWithFilePreviewDTO>(
                SseType.ADD_FILE_PREVIEW,
                new IdWithFilePreviewDTO(eventId.toString(), fileEntity.toDto())
            ));

            logger.info("Saved file with id={} for event with id={}", fileEntity.getId(), fileEntity.getEventId());
            return ResponseEntity.ok(Map.of("status", "saved", "fileId", fileEntity.getId().toString()));
        } catch (Exception e) {
            logger.error("Error while uploading file for event with id={}", eventId, e);
            return ResponseEntity.badRequest().body(Map.of("error", "Failed to upload file"));
        }
    }

    @Transactional
    public ResponseEntity<Map<String, String>> deleteFile(UUID fileId, UUID authenticatedUserId) {

        try {
            FilePreviewEntity fileEntity = fileRepository.findById(fileId).orElseThrow();
            EventEntity eventEntity = fileEntity.getEvent();
            if(!eventEntity.getUserId().equals(authenticatedUserId)) {
                logger.warn("User with id={} attempted to delete file with id={} without permission", authenticatedUserId, fileId);
                return ResponseEntity.status(403).body(Map.of("error", "Insufficient privileges"));
            }

            removeFileFromSystem(fileEntity.getSavedFileName());
            eventEntity.removeFilePreview(fileEntity);
            eventRepository.save(eventEntity);
            eventRepository.flush();

            sseService.sendSseEvent(new SseDTO<IdWithEventIdDTO>(
                SseType.REMOVE_FILE_PREVIEW,
                new IdWithEventIdDTO(fileId.toString(), eventEntity.getId().toString())
            ));

            logger.info("Deleted file with id={} for event with id={}", fileId, eventEntity.getId());

            return ResponseEntity.ok(Map.of("status", "deleted"));
        } catch (Exception e) {
            logger.error("Error processing file deletion request", e);
            return ResponseEntity.status(500).body(Map.of("error", "Internal server error"));
        }
    }

    @Transactional(readOnly = true)
    public ResponseEntity<List<FilePreviewDTO>> fetchFilePreviewsByEvent(UUID eventId) {
        try {
            List<FilePreviewDTO> filePreviews = fileRepository.findByEvent_Id(eventId).stream()
                .map(FilePreviewEntity::toDto)
                .toList();
            logger.info("Fetched {} file previews for event with id={}", filePreviews.size(), eventId);
            return ResponseEntity.ok(filePreviews);
        } catch (Exception e) {
            logger.warn("Error while retrieving file previews for event with id={}", eventId, e);
            return ResponseEntity.badRequest().body(null);
        }
    }

    @Transactional(readOnly = true)
    public ResponseEntity<FilePreviewDTO> fetchFilePreviewById(UUID fileId) {
        try {
            FilePreviewEntity filePreview = fileRepository.findById(fileId).orElseThrow();
            return ResponseEntity.ok(filePreview.toDto());
        } catch (Exception e) {
            logger.error("Error fetching file preview with id={}", fileId, e);
            return ResponseEntity.badRequest().body(null);
        }
    }

    @Transactional(readOnly = true)
    public ResponseEntity<Resource> downloadFile(UUID fileId, UUID authenticatedUserId) {
        try {
            FilePreviewEntity fileEntity = fileRepository.findById(fileId).orElseThrow();
            Path filePath = UPLOAD_DIR.resolve(fileEntity.getSavedFileName());
            if (!Files.exists(filePath)) {
                logger.error("File with id={} exists in database but not on filesystem: {}", fileId, filePath);
                return ResponseEntity.badRequest().body(null);
            }

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
            return ResponseEntity.badRequest().body(null);
        }
    }
}
