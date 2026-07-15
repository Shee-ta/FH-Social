package com.fhsocial.backend.Repositories;

import org.springframework.data.jpa.repository.JpaRepository;

import com.fhsocial.backend.Entities.EventEntity;

import java.time.Instant;
import java.util.List;
import java.util.UUID;

public interface EventRepository extends JpaRepository<EventEntity, UUID> {
    
    List<EventEntity> findByCreatedAtAfterOrEditedAtAfter(Instant createdAt, Instant editedAt);
}
