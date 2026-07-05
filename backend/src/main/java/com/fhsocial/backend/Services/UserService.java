package com.fhsocial.backend.Services;

import org.slf4j.Logger;

import java.time.Instant;
import java.util.List;
import java.util.Map;
import java.util.UUID;

import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Service;

import com.fhsocial.backend.DTO.UserDTO;
import com.fhsocial.backend.Entities.UserEntity;
import com.fhsocial.backend.Repositories.UserRepository;

import tools.jackson.databind.JsonNode;

import org.slf4j.LoggerFactory;

@Service
public class UserService {

    private static final int USER_TIME_TO_LIVE = 60*60*24;

    private UserRepository userRepository;
    private Logger logger = LoggerFactory.getLogger(UserService.class);

    private UserDTO toDto(UserEntity userEntity) {
        return new UserDTO(
            userEntity.getId(),
            userEntity.getUsername(),
            userEntity.getDisplayname(),
            userEntity.getRole(),
            userEntity.getDeleted()
        );
    }

    private void pendUserDeletion(UUID userId, int secondsUntilDeletion) {
        new Thread(() -> {
            try {
                Thread.sleep(secondsUntilDeletion * 1000L);
                UserEntity userEntity = userRepository.findById(userId).orElse(null);
                if (userEntity != null && userEntity.getDeleted()) {
                    userRepository.delete(userEntity);
                    logger.info("Permanently deleted account with id={}", userId);
                }
            } catch (InterruptedException e) {
                logger.error("Error while waiting to delete account with id={}", userId, e);
            }
        }).start();
    }

    public UserService(UserRepository userRepository) {
        this.userRepository = userRepository;
    }

    public ResponseEntity<Map<String, String>> uploadUser(JsonNode user, UUID authenticatedUserId) {
        try {
            UserEntity authenticatedUserEntity = userRepository.findById(authenticatedUserId).orElseThrow(() -> new IllegalArgumentException("Authenticated user not found"));
            String authenticatedUserRole = authenticatedUserEntity.getRole();
            UUID userID = UUID.fromString(user.get("id").asString());

            if(authenticatedUserRole.equals("student")) {

                if(!userID.equals(authenticatedUserId)) {
                    logger.warn("User with id={} attempted to edit user with id={}", authenticatedUserId, userID);
                    return ResponseEntity.status(403).body(Map.of("error", "You can only edit your own account"));
                }

                UserEntity userEntity = userRepository.findById(userID).orElseThrow(() -> new IllegalArgumentException("User not found"));
                userEntity.setDisplayname(user.get("displayname").asString());

                logger.info("Updated displayname for user with id={} to '{}'", userID, userEntity.getDisplayname());
                userRepository.save(userEntity);

                return ResponseEntity.ok(Map.of("status", "updated displayname"));
            }
            else if (authenticatedUserRole.equals("admin")) {

                UserDTO userDTO = new UserDTO(
                    UUID.fromString(user.get("id").asString()),
                    user.get("username").asString(),
                    user.get("displayname").asString(),
                    user.get("role").asString(),
                    user.get("deleted").asBoolean()
                );
                if(userDTO.deleted()) {
                    logger.info("Deleted account with id={}, pending deletion in {} seconds", userID, USER_TIME_TO_LIVE);
                    pendUserDeletion(userID, USER_TIME_TO_LIVE);
                }

                UserEntity userEntity = userRepository.findById(userDTO.id()).orElseGet(UserEntity::new);
                userEntity.setId(userDTO.id());
                userEntity.setUsername(userDTO.username());
                userEntity.setDisplayname(userDTO.displayname());
                userEntity.setRole(userDTO.role());
                userEntity.setDeleted(userDTO.deleted());

                userRepository.save(userEntity);

                logger.debug("Mapped userDTO: {}", userDTO);
                logger.info("Saved user with id={}", userDTO.id());

                return ResponseEntity.ok(Map.of("status", "saved"));
            }

        } catch (IllegalArgumentException e) {
            logger.warn("Invalid UUID in user payload", e);
            return ResponseEntity.badRequest().body(Map.of("error", "Invalid UUID format"));
        }
        return ResponseEntity.status(403).body(Map.of("error", "Invalid role"));
    }

    public ResponseEntity<List<UserDTO>> getUsersAll() {
        List<UserDTO> users = userRepository.findAll().stream()
            .map(this::toDto)
            .toList();
        logger.info("Fetched {} users", users.size());
        return ResponseEntity.ok(users);
    }

    public ResponseEntity<List<UserDTO>> getUsersSince(Instant timeStamp) {
        List<UserDTO> users = userRepository.findByCreatedAtAfterOrEditedAtAfter(timeStamp, timeStamp).stream()
            .map(this::toDto)
            .toList();
        logger.info("Fetched {} users since {}", users.size(), timeStamp);
        return ResponseEntity.ok(users);
    }

    public ResponseEntity<UserDTO> getUserById(UUID userId) {
        return userRepository.findById(userId)
            .map(user -> {
                logger.info("Fetched user with id {}", userId);
                return ResponseEntity.ok(toDto(user));
            })
            .orElseGet(() -> {
                logger.warn("User with id {} not found", userId);
                return ResponseEntity.notFound().build();
            });
    }
}