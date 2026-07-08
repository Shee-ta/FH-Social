package com.fhsocial.backend.Services;

import org.slf4j.Logger;

import java.util.List;
import java.util.Map;
import java.util.UUID;

import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Service;

import com.fhsocial.backend.DTO.IdWithEventIdDTO;
import com.fhsocial.backend.DTO.IdWithUserDTO;
import com.fhsocial.backend.DTO.SseDTO;
import com.fhsocial.backend.DTO.EntityDTO.UserDTO;
import com.fhsocial.backend.Entities.EventEntity;
import com.fhsocial.backend.Entities.UserEntity;
import com.fhsocial.backend.Enums.SseType;
import com.fhsocial.backend.Repositories.EventRepository;
import com.fhsocial.backend.Repositories.UserRepository;

import tools.jackson.databind.JsonNode;

import org.slf4j.LoggerFactory;

@Service
public class UserService {

    private UserRepository userRepository;
    private EventRepository eventRepository;
    private SseService sseService;

    private Logger logger = LoggerFactory.getLogger(UserService.class);

    public UserService(UserRepository userRepository, EventRepository eventRepository, SseService sseService) {
        this.userRepository = userRepository;
        this.eventRepository = eventRepository;
        this.sseService = sseService;
    }

    public ResponseEntity<Map<String, String>> uploadUser(JsonNode user, UUID authenticatedUserId) {
        try {
            UserEntity authenticatedUser = userRepository.findById(authenticatedUserId).orElseThrow();

            String id = user.get("id").asString();

            UserEntity userEntity;

            if (id == null || id.isEmpty()) {
                if (!authenticatedUser.getRole().equals("admin")) {
                    logger.warn("User with id={} attempted to create a new user without admin privileges", authenticatedUserId);
                    return ResponseEntity.status(403).body(Map.of("error", "Insufficient privileges"));
                }
                userEntity = new UserEntity();
            } else {
                UUID userId = UUID.fromString(id);
                userEntity = userRepository.findById(userId).orElseThrow();
            }

            userEntity.setUsername(user.get("username").asString());
            userEntity.setDisplayname(user.get("displayname").asString());
            userEntity.setRole(user.get("role").asString());

            userRepository.save(userEntity);

            logger.info("Saved user with id={}", userEntity.getId());

            return ResponseEntity.ok(Map.of("status", "saved"));

        } catch (Exception e) {
            logger.warn("Error while saving user", e);
            return ResponseEntity.badRequest().body(Map.of("error", "Error while saving user\""));
        }
    }

    public ResponseEntity<Map<String, String>> deleteUser(UUID userId, UUID authenticatedUserId) {
        try {
            UserEntity authenticatedUser = userRepository.findById(authenticatedUserId).orElseThrow();
            UserEntity userEntity = userRepository.findById(userId).orElseThrow();

            if (!authenticatedUser.getRole().equals("admin")) {
                logger.warn("User with id={} attempted to delete user with id={} without admin privileges", authenticatedUserId, userId);
                return ResponseEntity.status(403).body(Map.of("error", "Insufficient privileges"));
            }

            userRepository.delete(userEntity);

            logger.info("Deleted user with id={}", userId);

            sseService.sendSseEvent(new SseDTO<IdWithUserDTO>(
                SseType.REMOVE_USER, 
                new IdWithUserDTO(userEntity.getId().toString(), userEntity.toDto())
            ));

            return ResponseEntity.ok(Map.of("status", "deleted"));

        } catch (Exception e) {
            logger.warn("Error while deleting user", e);
            return ResponseEntity.badRequest().body(Map.of("error", "Error while deleting user\""));
        }
    }

    public ResponseEntity<Map<String, String>> changeMembership(JsonNode changeMemberRequest, UUID authenticatedUserId) {
        try {
            UUID eventId = UUID.fromString(changeMemberRequest.get("eventId").asString());
            boolean isAdded = changeMemberRequest.get("isAdded").asBoolean();

            EventEntity event = eventRepository.findById(eventId).orElseThrow();
            UserEntity user = userRepository.findById(authenticatedUserId).orElseThrow();

            if (isAdded) {
                event.addMember(user);
            } else {
                event.removeMember(user);
            }

            eventRepository.save(event);

            sseService.sendSseEvent(new SseDTO<>(
                isAdded ? SseType.ADD_MEMBER : SseType.REMOVE_MEMBER, 
                isAdded ? new IdWithUserDTO(event.getId().toString(), user.toDto()) : new IdWithEventIdDTO(user.getId().toString(), event.getId().toString())
            ));

            logger.info("Changed member status of event with id={} with user id={}", event.getId(), authenticatedUserId);

            return ResponseEntity.ok(Map.of("status", "saved"));

        } catch (Exception e) {
            logger.warn("Error while saving member status change for event with id={}", changeMemberRequest.get("eventId").asString(), e);
            return ResponseEntity.badRequest().body(Map.of("error", "Error while saving member status change for event with id=\"" + changeMemberRequest.get("eventId").asString() + "\""));
        }
    }

    public ResponseEntity<List<UserDTO>> fetchUsersByEvent(UUID eventId) {
        try {
            EventEntity eventEntity = eventRepository.findById(eventId).orElseThrow();
            List<UserDTO> users = eventEntity.getMembers().stream()
                .map(UserEntity::toDto)
                .toList();
            logger.info("Fetched {} users for event with id={}", users.size(), eventId);
            return ResponseEntity.ok(users);
        } catch (Exception e) {
            logger.warn("Error while retrieving users for event with id={}", eventId, e);
            return ResponseEntity.badRequest().body(null);
        }
    }

    public ResponseEntity<UserDTO> fetchUserById(UUID userId) {
        return userRepository.findById(userId)
            .map(UserEntity::toDto)
            .map(ResponseEntity::ok)
            .orElseGet(() -> {
                logger.warn("User with id={} not found", userId);
                return ResponseEntity.notFound().build();
            });
    }
}