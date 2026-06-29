package com.fhsocial.backend.Services;

import java.util.Optional;
import java.util.Map;
import java.util.UUID;

import org.slf4j.LoggerFactory;
import org.slf4j.Logger;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

import com.fhsocial.backend.DTO.UserDTO;
import com.fhsocial.backend.Entities.UserEntity;
import com.fhsocial.backend.Repositories.AuthRepository;
import com.fhsocial.backend.Security.JwtService;

@Service
public class AuthService {

    private final AuthRepository authRepository;
    private final JwtService jwtService;
    private final PasswordEncoder passwordEncoder;
    private final Logger logger = LoggerFactory.getLogger(AuthService.class);

    public AuthService(AuthRepository authRepository, JwtService jwtService, PasswordEncoder passwordEncoder) {
        this.authRepository = authRepository;
        this.jwtService = jwtService;
        this.passwordEncoder = passwordEncoder;
    }

    private boolean passwordsMatch(String rawPassword, String storedPasswordHash) {
        if (storedPasswordHash == null || storedPasswordHash.isBlank()) {
            return false;
        }

        if (storedPasswordHash.startsWith("$2a$") || storedPasswordHash.startsWith("$2b$") || storedPasswordHash.startsWith("$2y$")) {
            return passwordEncoder.matches(rawPassword, storedPasswordHash);
        }

       return false;
    }

    public ResponseEntity<?> login(String username, String password) {
        if (username == null || username.isBlank() || password == null || password.isBlank()) {
            return ResponseEntity.badRequest().body(Map.of("error", "username and password are required"));
        }

        Optional<UserEntity> user = authRepository.findByUsername(username);
        if (user.isEmpty()) {
            logger.warn("Login failed for unknown username={}", username);
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(Map.of("error", "invalid credentials"));
        }

        UserEntity userEntity = user.get();
        if (!passwordsMatch(password, userEntity.getPasswordhash())) {
            logger.warn("Login failed due to invalid password for username={}", username);
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(Map.of("error", "invalid credentials"));
        }

        UUID userId = userEntity.getId();
        String accessToken = jwtService.generateAccessToken(userId, userEntity.getUsername());

        UserDTO userDTO = new UserDTO(
            userEntity.getId(),
            userEntity.getUsername(),
            userEntity.getDisplayname(),
            userEntity.getRole(),
            userEntity.getDeleted()
        );
        return ResponseEntity.ok(Map.of("accessToken", accessToken, "user", userDTO));
    }

    public ResponseEntity<Map<String, String>> logout() {
        return ResponseEntity.ok(Map.of("status", "logged out"));
    }
}