package com.fhsocial.backend.Entities;

import java.time.Instant;
import java.util.List;
import java.util.UUID;

import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;
import org.springframework.data.domain.Persistable;

import jakarta.persistence.CollectionTable;
import jakarta.persistence.Column;
import jakarta.persistence.ElementCollection;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.PostLoad;
import jakarta.persistence.PostPersist;
import jakarta.persistence.Table;
import jakarta.persistence.Transient;

@Entity
@Table(name = "events")
public class EventEntity implements Persistable<UUID> {
    
    @Id
    private UUID id;

    @Column(nullable = false)
    private UUID userId;

    @Column(nullable = false)
    private String title;

    @Column(nullable = false)
    private String iso8601startDateTime;

    @Column(nullable = false)
    private String iso8601endDateTime;

    @Column(nullable = false)
    private String location;

    @Column(nullable = false, length = 66536)
    private String description;

    @Column(nullable = false, length = 1000)
    private String recommendation;

    @Column(nullable = false)
    private double latitude;

    @Column(nullable = false)
    private double longitude;

    @ElementCollection(fetch = FetchType.EAGER)
    @CollectionTable(name = "event_days", joinColumns = @JoinColumn(name = "event_id"))
    @Column(name = "event_day", nullable = false)
    private List<String> days;

    @ElementCollection(fetch = FetchType.EAGER)
    @CollectionTable(name = "event_memberIDs", joinColumns = @JoinColumn(name = "event_id"))
    @Column(name = "member_id", nullable = false)
    private List<String> memberIDs;

    @ElementCollection(fetch = FetchType.EAGER)
    @CollectionTable(name = "event_tags", joinColumns = @JoinColumn(name = "event_id"))
    @Column(name = "tag", nullable = false)
    private List<String> tags;

    @CreationTimestamp
    private Instant createdAt;

    @UpdateTimestamp
    private Instant editedAt;

    @Column(nullable = false)
    private boolean deleted = false;

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
        return userId;
    }

    public void setUserId(UUID userId) {
        this.userId = userId;
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

    public void setDays(List<String> days) {
        this.days = days;
    }

    public List<String> getMemberIDs() {
        return memberIDs;
    }

    public void setMemberIDs(List<String> memberIDs) {
        this.memberIDs = memberIDs;
    }

    public List<String> getTags() {
        return tags;
    }

    public void setTags(List<String> tags) {
        this.tags = tags;
    }

    public boolean getDeleted() {
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
