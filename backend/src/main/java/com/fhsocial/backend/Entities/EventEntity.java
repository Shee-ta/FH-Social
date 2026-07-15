package com.fhsocial.backend.Entities;

import java.time.Instant;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;
import org.springframework.data.domain.Persistable;
import com.fhsocial.backend.DTO.EntityDTO.EventDTO;

import jakarta.persistence.CollectionTable;
import jakarta.persistence.Column;
import jakarta.persistence.ElementCollection;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.JoinTable;
import jakarta.persistence.ManyToMany;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.OneToMany;
import jakarta.persistence.PostLoad;
import jakarta.persistence.PostPersist;
import jakarta.persistence.CascadeType;
import jakarta.persistence.Table;
import jakarta.persistence.Transient;

@Entity
@Table(name = "events")
public class EventEntity implements Persistable<UUID> {
    
    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @ManyToOne(fetch = FetchType.EAGER, optional = false)
    @JoinColumn(name = "creator_user_entity_id", nullable = false)
    private UserEntity creator;

    @Column(nullable = false)
    private String title;

    @Column(nullable = false)
    private String iso8601startDateTime;

    @Column(nullable = false)
    private String iso8601endDateTime;

    @Column(nullable = false)
    private String location;

    @Column(nullable = false, length = 2000)
    private String description;

    @Column(nullable = false, length = 600)
    private String recommendation;

    @Column(nullable = false)
    private double latitude;

    @Column(nullable = false)
    private double longitude;

    @ElementCollection(fetch = FetchType.EAGER)
    @CollectionTable(name = "event_days", joinColumns = @JoinColumn(name = "event_id"))
    @Column(name = "event_day", nullable = false)
    private List<String> days = new ArrayList<>();

    @ElementCollection(fetch = FetchType.EAGER)
    @CollectionTable(name = "event_tags", joinColumns = @JoinColumn(name = "event_id"))
    @Column(name = "tag", nullable = false)
    private List<String> tags = new ArrayList<>();

    @ManyToMany(fetch = FetchType.EAGER)
    @JoinTable(
        name = "event_members",
        joinColumns = @JoinColumn(name = "event_id"),
        inverseJoinColumns = @JoinColumn(name = "user_id")
    )
    private List<UserEntity> members = new ArrayList<>();

    @OneToMany(fetch = FetchType.EAGER, mappedBy = "event", cascade = CascadeType.ALL, orphanRemoval = true)
    private List<CommentEntity> comments = new ArrayList<>();

    @OneToMany(fetch = FetchType.EAGER, mappedBy = "event", cascade = CascadeType.ALL, orphanRemoval = true)
    private List<FilePreviewEntity> filePreviews = new ArrayList<>();

    @CreationTimestamp
    private Instant createdAt;

    @UpdateTimestamp
    private Instant editedAt;

    @Transient
    private boolean isNew = true;

    public EventEntity() {}

    @Override
    public UUID getId() {
        return id;
    }

    public void setId(UUID id) {
        this.id = id;
    }

    public UUID getUserId() {
        return creator != null ? creator.getId() : null;
    }

    public UserEntity getCreator() {
        return creator;
    }

    public void setCreator(UserEntity creator) {
        this.creator = creator;
    }

    public String getTitle() {
        return title;
    }

    public void setTitle(String title) {
        this.title = title;
    }

    public String getIso8601startDateTime() {
        return iso8601startDateTime;
    }

    public void setIso8601startDateTime(String iso8601startDateTime) {
        this.iso8601startDateTime = iso8601startDateTime;
    }

    public String getIso8601endDateTime() {
        return iso8601endDateTime;
    }

    public void setIso8601endDateTime(String iso8601endDateTime) {
        this.iso8601endDateTime = iso8601endDateTime;
    }

    public String getLocation() {
        return location;
    }

    public void setLocation(String location) {
        this.location = location;
    }

    public String getDescription() {
        return description;
    }

    public void setDescription(String description) {
        this.description = description;
    }
    
    public String getRecommendation() {
        return recommendation;
    }

    public void setRecommendation(String recommendation) {
        this.recommendation = recommendation;
    }

    public double getLatitude() {
        return latitude;
    }

    public void setLatitude(double latitude) {
        this.latitude = latitude;
    }

    public double getLongitude() {
        return longitude;
    }

    public void setLongitude(double longitude) {
        this.longitude = longitude;
    }

    public List<String> getDays() {
        return days;
    }

    public List<String> getTags() {
        return tags;
    }

    public void setTags(List<String> tags) {
        this.tags = tags;
    }

    public void setDays(List<String> days) {
        this.days = days;
    }

    public List<UserEntity> getMembers() {
        return members;
    }

    public void setMembers(List<UserEntity> members) {
        this.members = members;
    }

    public void addMember(UserEntity member) {
        if (members.stream().noneMatch(existing -> existing.getId().equals(member.getId()))) members.add(member);
    }

    public void removeMember(UserEntity member) {
        members.removeIf(existing -> existing.getId().equals(member.getId()));
    }

    public List<CommentEntity> getComments() {
        return comments;
    }

    public void setComments(List<CommentEntity> comments) {
        this.comments = comments;
    }

    public void addComment(CommentEntity comment) {
        comments.add(comment);
    }

    public void removeComment(CommentEntity comment) {
        comments.remove(comment);
    }

    public List<FilePreviewEntity> getFilePreviews() {
        return filePreviews;
    }

    public void setFilePreviews(List<FilePreviewEntity> filePreviews) {
        this.filePreviews = filePreviews;
    }

    public void addFilePreview(FilePreviewEntity filePreview) {
        filePreviews.add(filePreview);
    }

    public void removeFilePreview(FilePreviewEntity filePreview) {
        filePreviews.remove(filePreview);
    }

    public Instant getCreatedAt() {
        return createdAt;
    }

    public Instant getEditedAt() {
        return editedAt;
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

    public EventDTO toDto() {
        return new EventDTO(
            this.getId(),
            this.getCreator().toDto(),
            this.getTitle(),
            this.getIso8601startDateTime(),
            this.getIso8601endDateTime(),
            this.getLocation(),
            this.getDescription(),
            this.getRecommendation(),
            this.getLatitude(),
            this.getLongitude(),
            this.getDays(),
            this.getTags(),
            this.getCreatedAt().toString(),
            this.getEditedAt().toString()
        );
    }

    @Override
    public String toString() {
        StringBuilder stringBuilder = new StringBuilder();
        stringBuilder.append("Title: " + title);
        stringBuilder.append("Start Time: " + iso8601startDateTime);
        stringBuilder.append("End Time: " + iso8601endDateTime);
        stringBuilder.append("Description: " + description);
        stringBuilder.append("Recommendation for learning: " + recommendation);
        stringBuilder.append("Location: " + location);
        stringBuilder.append("Days: " + days);
        stringBuilder.append("Tags: " + tags);
        return stringBuilder.toString();
    }
}
