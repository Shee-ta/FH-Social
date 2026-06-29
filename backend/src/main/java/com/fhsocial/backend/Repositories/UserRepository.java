package com.fhsocial.backend.Repositories;

import org.springframework.data.jpa.repository.JpaRepository;

import com.fhsocial.backend.Entities.UserEntity;

import java.time.Instant;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface UserRepository extends JpaRepository<UserEntity, UUID> {
	Optional<UserEntity> findByUsername(String username);
	Optional<UserEntity> findById(UUID userId);
    List<UserEntity> findByCreatedAtAfterOrEditedAtAfter(Instant createdAt, Instant editedAt);

}