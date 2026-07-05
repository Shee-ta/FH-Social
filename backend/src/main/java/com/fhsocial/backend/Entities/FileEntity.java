package com.fhsocial.backend.Entities;

import java.time.Instant;
import java.util.UUID;

import org.hibernate.annotations.CreationTimestamp;
import org.springframework.data.domain.Persistable;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Lob;
import jakarta.persistence.PostLoad;
import jakarta.persistence.PostPersist;
import jakarta.persistence.Table;
import jakarta.persistence.Transient;

@Entity
@Table(name = "files")
public class FileEntity implements Persistable<UUID> {
    
    @Id
    private UUID id;

    @Column(nullable = false)
    private UUID eventId;

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

    @Column(nullable = false)
    private boolean deleted;

    @Transient
    private boolean isNew = true;

    public FileEntity() {}

    public UUID getId() {
        return id;
    }

    public void setId(UUID id) {
        this.id = id;
    }

    public UUID getEventId() {
        return eventId;
    }

    public void setEventId(UUID eventId) {
        this.eventId = eventId;
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

    public boolean isDeleted() {
        return deleted;
    }

    public void setDeleted(boolean deleted) {
        this.deleted = deleted;
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

    @Override
    public String toString() {
        StringBuilder stringBuilder = new StringBuilder();
        stringBuilder.append("File name: " + originalFileName);
        stringBuilder.append("Content: " + preprocessedContent);
        return stringBuilder.toString();
    }
}