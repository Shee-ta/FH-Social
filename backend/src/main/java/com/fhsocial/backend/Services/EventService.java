package com.fhsocial.backend.Services;

import org.slf4j.Logger;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.UUID;

import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.fhsocial.backend.DTO.IdDTO;
import com.fhsocial.backend.DTO.SseDTO;
import com.fhsocial.backend.DTO.EntityDTO.EventDTO;
import com.fhsocial.backend.Entities.EventEntity;
import com.fhsocial.backend.Entities.FilePreviewEntity;
import com.fhsocial.backend.Entities.UserEntity;
import com.fhsocial.backend.Enums.SseType;
import com.fhsocial.backend.Repositories.EventRepository;
import com.fhsocial.backend.Repositories.UserRepository;

import tools.jackson.databind.JsonNode;

import org.slf4j.LoggerFactory;

@Service
public class EventService {

    private EventRepository eventRepository;
    private UserRepository userRepository;
    private FileService fileService;
    private SseService sseService;

    private Logger logger = LoggerFactory.getLogger(EventService.class);

    public EventService(EventRepository eventRepository, UserRepository userRepository, FileService fileService, SseService sseService) {
        this.eventRepository = eventRepository;
        this.userRepository = userRepository;
        this.fileService = fileService;
        this.sseService = sseService;
    }

    private List<String> parseStringArray(JsonNode root, String fieldName) {
        List<String> values = new ArrayList<>();
        JsonNode arrayNode = root.get(fieldName);
        if (arrayNode != null && arrayNode.isArray()) {
            for (JsonNode itemNode : arrayNode) {
                values.add(itemNode.asString());
            }
        }
        return values;
    }
    
    public ResponseEntity<Map<String, String>> uploadEvent(JsonNode event, UUID authenticatedUserId) {
        try {
            List<String> days = parseStringArray(event, "days");

            String id = event.get("id").asString();

            EventEntity eventEntity;
            UserEntity creator = userRepository.findById(authenticatedUserId).orElse(null);
            if (creator == null) {
                logger.warn("Authenticated user with id={} not found while uploading event", authenticatedUserId);
                return ResponseEntity.status(401).body(Map.of("error", "Authentication invalid. Please log in again."));
            }

            if (id == null || id.isEmpty()) {
                eventEntity = new EventEntity();
                eventEntity.setCreator(creator);
            } else {
                UUID eventId = UUID.fromString(id);
                eventEntity = eventRepository.findById(eventId).orElseThrow();

                if (!eventEntity.getCreator().getId().equals(authenticatedUserId)) {
                    logger.warn("User with id={} attempted to edit event with id={} without permission", authenticatedUserId, eventId);
                    return ResponseEntity.status(403).body(Map.of("error", "Insufficient privileges"));
                }
            }

            eventEntity.setTitle(event.get("title").asString());
            eventEntity.setIso8601startDateTime(event.get("iso8601startDateTime").asString());
            eventEntity.setIso8601endDateTime(event.get("iso8601endDateTime").asString());
            eventEntity.setLocation(event.get("location").asString());
            eventEntity.setDescription(event.get("description").asString());
            eventEntity.setRecommendation(event.get("recommendation").asString());
            eventEntity.setLatitude(event.get("latitude").asDouble());
            eventEntity.setLongitude(event.get("longitude").asDouble());
            eventEntity.setDays(days);

            eventRepository.save(eventEntity);

            sseService.sendSseEvent(new SseDTO<EventDTO>(
                SseType.ADD_EVENT, 
                eventEntity.toDto()
            ));
            
            logger.info("Saved event with id={}", eventEntity.getId());

            return ResponseEntity.ok(Map.of("status", "saved"));

        } catch (Exception e) {
            logger.warn("Error while saving event", e);
            return ResponseEntity.badRequest().body(Map.of("error", "Error while saving event\""));
        }
    }

    @Transactional
    public ResponseEntity<Map<String, String>> deleteEvent(UUID eventId, UUID authenticatedUserId) {
        try {
            EventEntity eventEntity = eventRepository.findById(eventId).orElseThrow();

            if (!eventEntity.getCreator().getId().equals(authenticatedUserId)) {
                logger.warn("User with id={} attempted to delete event with id={} without permission", authenticatedUserId, eventId);
                return ResponseEntity.status(403).body(Map.of("error", "Insufficient privileges"));
            }

            List<UUID> fileIdsToDelete = eventEntity.getFilePreviews().stream().map(FilePreviewEntity::getId).toList();
            for (UUID fileId : fileIdsToDelete) {
                fileService.deleteFile(fileId, authenticatedUserId);
            }

            eventEntity.getMembers().forEach(member -> member.removeMemberOfEvent(eventEntity));
            eventEntity.getMembers().clear();
            eventEntity.getCreator().getEvents().removeIf(event -> event.getId().equals(eventId));

            eventRepository.delete(eventEntity);
            eventRepository.flush();

            if (eventRepository.existsById(eventId)) {
                logger.warn("Event with id={} still exists after delete attempt", eventId);
                return ResponseEntity.badRequest().body(Map.of("error", "Error while deleting event"));
            }

            sseService.sendSseEvent(new SseDTO<IdDTO>(
                SseType.REMOVE_EVENT, 
                new IdDTO(eventEntity.getId().toString())
            ));

            logger.info("Deleted event with id={}", eventId);
            
            return ResponseEntity.ok(Map.of("status", "deleted"));

        } catch (Exception e) {
            logger.warn("Error while deleting event with id={}", eventId, e);
            return ResponseEntity.badRequest().body(Map.of("error", "Error while deleting event"));
        }
    }

    public ResponseEntity<List<EventDTO>> getEventsAll() {
        List<EventDTO> events = eventRepository.findAll().stream().map(EventEntity::toDto).toList();
        logger.info("Fetched {} events", events.size());
        return ResponseEntity.ok(events);
    }

    public ResponseEntity<EventDTO> getEventById(UUID eventId) {
        try {
            EventEntity event = eventRepository.findById(eventId).orElseThrow();
            EventDTO eventDTO = event.toDto();

            logger.info("Fetched event with id={}", eventId);

            return ResponseEntity.ok(eventDTO);

        } catch (Exception e) {
            logger.warn("Error while fetching event with id={}", eventId, e);
            return ResponseEntity.badRequest().body(null);
        }
    }
}
