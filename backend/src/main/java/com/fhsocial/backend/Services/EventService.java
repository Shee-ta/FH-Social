package com.fhsocial.backend.Services;

import org.slf4j.Logger;

import java.time.Instant;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.UUID;

import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Service;

import com.fasterxml.jackson.databind.JsonNode;
import com.fhsocial.backend.DTO.EventDTO;
import com.fhsocial.backend.Entities.EventEntity;
import com.fhsocial.backend.Repositories.EventRepository;

import org.slf4j.LoggerFactory;

@Service
public class EventService {

    private static final int EVENT_TIME_TO_LIVE = 3600;

    private EventRepository eventRepository;
    private Logger logger = LoggerFactory.getLogger(EventService.class);

    private EventDTO toDto(EventEntity eventEntity) {
        return new EventDTO(
            eventEntity.getId(),
            eventEntity.getUserId(),
            eventEntity.getTitle(),
            eventEntity.getIso8601startDateTime(),
            eventEntity.getIso8601endDateTime(),
            eventEntity.getLocation(),
            eventEntity.getDescription(),
            eventEntity.getRecommendation(),
            eventEntity.getLatitude(),
            eventEntity.getLongitude(),
            eventEntity.getDays(),
            eventEntity.getMemberIDs(),
            eventEntity.getDeleted()
        );
    }

    private void pendEventDeletion(UUID eventId, int secondsUntilDeletion) {
        new Thread(() -> {
            try {
                Thread.sleep(secondsUntilDeletion * 1000L);
                EventEntity eventEntity = eventRepository.findById(eventId).orElse(null);
                if (eventEntity != null && eventEntity.getDeleted()) {
                    eventRepository.delete(eventEntity);
                    logger.info("Permanently deleted event with id={}", eventId);
                }
            } catch (InterruptedException e) {
                logger.error("Error while waiting to delete event with id={}", eventId, e);
            }
        }).start();
    }

    public EventService(EventRepository eventRepository) {
        this.eventRepository = eventRepository;
    }
    
    public ResponseEntity<Map<String, String>> uploadEvent(JsonNode event, UUID authenticatedUserId) {
        try {
            ArrayList<String> days = new ArrayList<>();
            JsonNode daysNode = event.get("days");
            if (daysNode != null && daysNode.isArray()) {
                for (JsonNode dayNode : daysNode) {
                    days.add(dayNode.asText());
                }
            }

            EventDTO eventDTO = new EventDTO(
                UUID.fromString(event.get("id").asText()),
                authenticatedUserId,
                event.get("title").asText(),
                event.get("iso8601startDateTime").asText(),
                event.get("iso8601endDateTime").asText(),
                event.get("location").asText(),
                event.get("description").asText(),
                event.get("recommendation").asText(),
                event.get("latitude").asDouble(),
                event.get("longitude").asDouble(),
                days,
                new ArrayList<String>(),
                event.get("deleted").asBoolean()
            );
            if(eventDTO.deleted()) {
                logger.info("Deleted event with id={}, pending deletion in {} seconds", eventDTO.id(), EVENT_TIME_TO_LIVE);
                pendEventDeletion(eventDTO.id(), EVENT_TIME_TO_LIVE);
            }

            EventEntity eventEntity = eventRepository.findById(eventDTO.id()).orElseGet(EventEntity::new);
            if (eventEntity.getId() == null) {
                eventEntity.setId(eventDTO.id());
                eventEntity.setMemberIDs(eventDTO.memberIDs());
            }
            eventEntity.setUserId(eventDTO.userId());
            eventEntity.setTitle(eventDTO.title());
            eventEntity.setIso8601startDateTime(eventDTO.iso8601startDateTime());
            eventEntity.setIso8601endDateTime(eventDTO.iso8601endDateTime());
            eventEntity.setLocation(eventDTO.location());
            eventEntity.setDescription(eventDTO.description());
            eventEntity.setRecommendation(eventDTO.recommendation());
            eventEntity.setLatitude(eventDTO.latitude());
            eventEntity.setLongitude(eventDTO.longitude());
            eventEntity.setDays(eventDTO.days());
            eventEntity.setDeleted(eventDTO.deleted());

            eventRepository.save(eventEntity);
            
            logger.debug("Mapped EventDTO: {}", eventDTO);
            logger.info("Saved event with id={}", eventDTO.id());

            return ResponseEntity.ok(Map.of("status", "saved"));

        } catch (IllegalArgumentException e) {
            logger.warn("Invalid UUID in event payload", e);
            return ResponseEntity.badRequest().body(Map.of("error", "Invalid UUID format"));
        }
    }

    public ResponseEntity<Map<String, String>> changeMember(JsonNode changeMemberRequest, UUID authenticatedUserId) {
        try {
            UUID userId = UUID.fromString(changeMemberRequest.get("userId").asText());
            UUID eventId = UUID.fromString(changeMemberRequest.get("eventId").asText());
            boolean isAdded = changeMemberRequest.get("isAdded").asBoolean();

            EventEntity eventEntity = eventRepository.findById(eventId).orElse(null);
            if (eventEntity == null) {
                logger.warn("Event with id={} not found for change member request", eventId);
                return ResponseEntity.badRequest().body(Map.of("error", "Event not found"));
            }

            List<String> memberIDs = eventEntity.getMemberIDs();
            String userIdStr = userId.toString();
            if (isAdded) {
                if (!memberIDs.contains(userIdStr)) {
                    memberIDs.add(userIdStr);
                    logger.info("Added user with id={} to event with id={}", userId, eventId);
                } else {
                    logger.info("User with id={} is already a member of event with id={}", userId, eventId);
                }
            } else {
                if (memberIDs.remove(userIdStr)) {
                    logger.info("Removed user with id={} from event with id={}", userId, eventId);
                } else {
                    logger.info("User with id={} was not a member of event with id={}", userId, eventId);
                }
            }
            eventEntity.setMemberIDs(memberIDs);
            eventRepository.save(eventEntity);
        } catch (IllegalArgumentException e) {
            logger.warn("Invalid UUID in change member request", e);
            return ResponseEntity.badRequest().body(Map.of("error", "Invalid UUID format"));
        }
        return ResponseEntity.ok(Map.of("status", "member changed"));
    }

    public ResponseEntity<List<EventDTO>> getEventsAll() {
        List<EventDTO> events = eventRepository.findAll().stream()
            .map(this::toDto)
            .toList();
        logger.info("Fetched {} events", events.size());
        return ResponseEntity.ok(events);
    }

    public ResponseEntity<List<EventDTO>> getEventsSince(Instant timeStamp) {
        List<EventDTO> events = eventRepository.findByCreatedAtAfterOrEditedAtAfter(timeStamp, timeStamp).stream()
            .map(this::toDto)
            .toList();
        logger.info("Fetched {} events since {}", events.size(), timeStamp);
        return ResponseEntity.ok(events);
    }
}
