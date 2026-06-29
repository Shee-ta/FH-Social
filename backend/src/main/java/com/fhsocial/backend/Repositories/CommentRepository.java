package com.fhsocial.backend.Repositories;

import org.springframework.data.jpa.repository.JpaRepository;

import com.fhsocial.backend.Entities.CommentEntity;

import java.time.Instant;
import java.util.List;
import java.util.UUID;

public interface CommentRepository extends JpaRepository<CommentEntity, UUID> {
    
    List<CommentEntity> findByCreatedAtAfterOrEditedAtAfter(Instant createdAt, Instant editedAt);
}