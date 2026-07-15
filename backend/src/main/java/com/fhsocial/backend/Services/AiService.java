package com.fhsocial.backend.Services;

import java.util.ArrayList;
import java.util.HashMap;
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

import tools.jackson.databind.JsonNode;

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

    /**
     * Free-form chat over the documents of one or more events. The client sends the selected
     * event ids (and optionally specific file names). Only PDF files that were pre-processed on
     * upload carry usable text; anything else is reported back in "notes".
     */
    @Transactional(readOnly = true)
    public ResponseEntity<Map<String, String>> chat(JsonNode body) {
        if (body == null) {
            return ResponseEntity.badRequest().body(Map.of("error", "Invalid request body"));
        }

        JsonNode promptNode = body.get("prompt");
        String prompt = promptNode != null ? promptNode.asString().trim() : "";
        if (prompt.isEmpty()) {
            return ResponseEntity.badRequest().body(Map.of("error", "Prompt is required"));
        }

        List<UUID> eventIds = parseUuidArray(body, "eventIds");
        List<String> requestedFileNames = parseStringArray(body, "fileNames");

        // Collect the files of all selected events.
        List<FilePreviewEntity> availableFiles = new ArrayList<>();
        for (UUID eventId : eventIds) {
            availableFiles.addAll(fileRepository.findByEvent_Id(eventId));
        }

        List<FilePreviewEntity> targetFiles = new ArrayList<>();
        List<String> notes = new ArrayList<>();

        if (!requestedFileNames.isEmpty()) {
            for (String requested : requestedFileNames) {
                List<FilePreviewEntity> matches = availableFiles.stream()
                    .filter(file -> requested.equalsIgnoreCase(file.getOriginalFileName()))
                    .toList();

                if (matches.isEmpty()) {
                    notes.add("Die Datei \"" + requested + "\" wurde in den ausgewählten Lerngruppen nicht gefunden.");
                    continue;
                }
                for (FilePreviewEntity file : matches) {
                    if (!isPdf(file)) {
                        notes.add("Die Datei \"" + file.getOriginalFileName() + "\" ist keine PDF und kann nicht ausgewertet werden (nur PDFs werden unterstützt).");
                    } else if (!hasContent(file)) {
                        notes.add("Für die Datei \"" + file.getOriginalFileName() + "\" liegt kein auswertbarer Text vor.");
                    } else {
                        targetFiles.add(file);
                    }
                }
            }
        } else {
            for (FilePreviewEntity file : availableFiles) {
                if (!isPdf(file)) {
                    notes.add("Die Datei \"" + file.getOriginalFileName() + "\" ist keine PDF und wurde übersprungen.");
                } else if (hasContent(file)) {
                    targetFiles.add(file);
                }
            }
        }

        String answer = brain.answerFileQuestion(targetFiles, prompt);
        if (answer == null) {
            return ResponseEntity.status(500).body(Map.of("error", "Failed to generate answer"));
        }

        Map<String, String> result = new HashMap<>();
        result.put("answer", answer);
        result.put("notes", String.join("\n", notes));
        result.put("usedFiles", Integer.toString(targetFiles.size()));
        logger.info("AI chat answered using {} file(s) from {} event(s)", targetFiles.size(), eventIds.size());
        return ResponseEntity.ok(result);
    }

    private boolean isPdf(FilePreviewEntity file) {
        String name = file.getOriginalFileName();
        return name != null && name.toLowerCase().endsWith(".pdf");
    }

    private boolean hasContent(FilePreviewEntity file) {
        return file.getPreprocessedContent() != null && !file.getPreprocessedContent().isBlank();
    }

    private List<UUID> parseUuidArray(JsonNode root, String field) {
        List<UUID> values = new ArrayList<>();
        JsonNode arrayNode = root.get(field);
        if (arrayNode != null && arrayNode.isArray()) {
            for (JsonNode item : arrayNode) {
                try {
                    values.add(UUID.fromString(item.asString().trim()));
                } catch (Exception ignored) {
                    // Skip malformed ids.
                }
            }
        }
        return values;
    }

    private List<String> parseStringArray(JsonNode root, String field) {
        List<String> values = new ArrayList<>();
        JsonNode arrayNode = root.get(field);
        if (arrayNode != null && arrayNode.isArray()) {
            for (JsonNode item : arrayNode) {
                String value = item.asString();
                if (value != null && !value.isBlank()) {
                    values.add(value.trim());
                }
            }
        }
        return values;
    }
}
