package com.fhsocial.backend.Repositories;

import org.springframework.data.jpa.repository.JpaRepository;
import com.fhsocial.backend.Entities.FilePreviewEntity;

import java.util.List;
import java.util.UUID;

public interface FileRepository extends JpaRepository<FilePreviewEntity, UUID> {
    
    List<FilePreviewEntity> findByEvent_Id(UUID eventId);
}