package com.fhsocial.backend.Services;

import java.util.List;
import java.util.Map;
import java.util.UUID;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.fhsocial.backend.Brain.Brain;
import com.fhsocial.backend.Brain.Request;
import com.fhsocial.backend.DTO.SseDTO;
import com.fhsocial.backend.DTO.EntityDTO.EventDTO;
import com.fhsocial.backend.Entities.EventEntity;
import com.fhsocial.backend.Entities.FilePreviewEntity;
import com.fhsocial.backend.Enums.SseType;
import com.fhsocial.backend.Repositories.EventRepository;
import com.fhsocial.backend.Repositories.FileRepository;

@Service
public class AiService {

    private EventRepository eventRepository;
    private FileRepository fileRepository;
    private SseService sseService;
    private Brain brain;

    private Logger logger = LoggerFactory.getLogger(AiService.class);

    public AiService(EventRepository eventRepository, FileRepository fileRepository, SseService sseService, Brain brain) {
        this.eventRepository = eventRepository;
        this.fileRepository = fileRepository;
        this.sseService = sseService;
        this.brain = brain;
    }
    
    @Transactional
    public ResponseEntity<Map<String, String>> generateRecommendation(UUID eventId, UUID authenticatedUserId) {
        EventEntity event = eventRepository.findById(eventId).orElse(null);
        if(event == null) {
            logger.warn("Failed generating recommendation, no eventEntity with UUID {}", eventId);
            return ResponseEntity.badRequest().body(Map.of("error", "Event not found"));
        }
        List<FilePreviewEntity> files = fileRepository.findByEvent_Id(eventId);
        List<String> tags = eventRepository.findAll().stream().map(EventEntity::getTags).flatMap(List::stream).distinct().toList();
        if(brain.generateRecommendation(Request.RECOMMENDATION, files, event, tags)) {
            sseService.sendSseEvent(new SseDTO<EventDTO>(
                SseType.ADD_EVENT,
                event.toDto()
            ));
            return ResponseEntity.ok(Map.of("message", "Recommendation generated successfully"));
        } else {
            return ResponseEntity.status(500).body(Map.of("error", "Failed to generate recommendation"));
        }
    }

    @Transactional
    public ResponseEntity<Map<String, String>> generateTags(UUID eventId, UUID authenticatedUserId) {
        EventEntity event = eventRepository.findById(eventId).orElse(null);
        if(event == null) {
            logger.warn("Failed generating tags, no eventEntity with UUID {}", eventId);
            return ResponseEntity.badRequest().body(Map.of("error", "Event not found"));
        }
        List<FilePreviewEntity> files = fileRepository.findByEvent_Id(eventId);
        List<String> tags = eventRepository.findAll().stream().map(EventEntity::getTags).flatMap(List::stream).distinct().toList();
        if(brain.generateTags(Request.TAGS, event, files, tags)) {
            logger.info("Sending Sse event for generated tags for event with id={}", event.getId());
            sseService.sendSseEvent(new SseDTO<EventDTO>(
                SseType.ADD_EVENT,
                event.toDto()
            ));
            return ResponseEntity.ok(Map.of("message", "Tags generated successfully"));
        } else {
            return ResponseEntity.status(500).body(Map.of("error", "Failed to generate tags"));
        }
    }
}
