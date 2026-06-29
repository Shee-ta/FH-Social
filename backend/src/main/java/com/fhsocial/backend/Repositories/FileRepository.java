package com.fhsocial.backend.Repositories;

import org.springframework.data.jpa.repository.JpaRepository;
import com.fhsocial.backend.Entities.FileEntity;

import java.util.List;
import java.util.UUID;

public interface FileRepository extends JpaRepository<FileEntity, UUID> {
    
    List<FileEntity> findByEventIdAndDeletedFalse(UUID eventId);
}