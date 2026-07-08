package com.fhsocial.backend.Entities;

import java.time.Instant;
import java.util.UUID;

import org.hibernate.annotations.CreationTimestamp;
import org.springframework.data.domain.Persistable;

import com.fhsocial.backend.DTO.EntityDTO.FilePreviewDTO;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.PostLoad;
import jakarta.persistence.PostPersist;
import jakarta.persistence.Table;
import jakarta.persistence.Transient;

@Entity
@Table(name = "files")
public class FilePreviewEntity implements Persistable<UUID> {
    
    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @ManyToOne(fetch = FetchType.EAGER, optional = false)
    @JoinColumn(name = "event_entity_id", nullable = false)
    private EventEntity event;

    @Column(nullable = false)
    private String originalFileName;

    @Column(nullable = false, unique = true)
    private String savedFileName;

    @Column(nullable = false)
    private long size;

    @Column(nullable = false, columnDefinition = "TEXT")
    private String preprocessedContent;
    
    @CreationTimestamp
    private Instant createdAt;

    @Transient
    private boolean isNew = true;

    public FilePreviewEntity() {}

    public UUID getId() {
        return id;
    }

    public void setId(UUID id) {
        this.id = id;
    }

    public UUID getEventId() {
        return event != null ? event.getId() : null;
    }

    public EventEntity getEvent() {
        return event;
    }

    public void setEvent(EventEntity event) {
        this.event = event;
    }

    public String getOriginalFileName() {
        return originalFileName;
    }

    public void setOriginalFileName(String originalFileName) {
        this.originalFileName = originalFileName;
    }

    public String getSavedFileName() {
        return savedFileName;
    }

    public void setSavedFileName(String savedFileName) {
        this.savedFileName = savedFileName;
    }

    public long getSize() {
        return size;
    }

    public void setSize(long size) {
        this.size = size;
    }

    public String getPreprocessedContent() {
        return preprocessedContent;
    }

    public void setPreprocessedContent(String preprocessedContent) {
        this.preprocessedContent = preprocessedContent;
    }

    public Instant getCreatedAt() {
        return createdAt;
    }

     @Override
    public boolean isNew() {
        return isNew;
    }

    @PostLoad
    @PostPersist
    private void markNotNew() {
        this.isNew = false;
    }

    public FilePreviewDTO toDto() {
        return new FilePreviewDTO(
            this.getId(),
            this.getOriginalFileName(),
            this.getSavedFileName(),
            this.getSize(),
            this.getCreatedAt()
        );
    }

    @Override
    public String toString() {
        StringBuilder stringBuilder = new StringBuilder();
        stringBuilder.append("File name: " + originalFileName);
        stringBuilder.append("Content: " + preprocessedContent);
        return stringBuilder.toString();
    }
}