package com.fhsocial.backend.Entities;

import java.time.Instant;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;
import org.springframework.data.domain.Persistable;

import com.fhsocial.backend.DTO.EntityDTO.UserDTO;

import jakarta.persistence.CascadeType;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.ManyToMany;
import jakarta.persistence.OneToMany;
import jakarta.persistence.OneToOne;
import jakarta.persistence.PostLoad;
import jakarta.persistence.PostPersist;
import jakarta.persistence.Table;
import jakarta.persistence.Transient;
import jakarta.validation.constraints.Pattern;

@Entity
@Table(name = "users")
public class UserEntity implements Persistable<UUID> {
    
    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @OneToMany(fetch = FetchType.EAGER, mappedBy = "creator")
    private List<EventEntity> events = new ArrayList<>();

    @ManyToMany(fetch = FetchType.EAGER, mappedBy = "members")
    private List<EventEntity> memberOfEvents = new ArrayList<>();

    @OneToMany(fetch = FetchType.EAGER, mappedBy = "creator")
    private List<CommentEntity> comments = new ArrayList<>();

    @OneToOne(fetch = FetchType.LAZY, mappedBy = "user", cascade = CascadeType.ALL, orphanRemoval = true, optional = false)
    private UserSettingsEntity userSettings;

    @Column(nullable = false, unique = true)
    private String username;

    @Column(nullable = true, unique = true)
    private String displayname;

    @Column(nullable = false)
    private String passwordhash;

    @Column(nullable = false)
    @Pattern(regexp = "student|professor|admin")
    private String role = "student";

    @CreationTimestamp
    private Instant createdAt;

    @UpdateTimestamp
    private Instant editedAt;

    @Transient
    private boolean isNew = true;

    public UserEntity() {
        this.userSettings = new UserSettingsEntity(this);
    }

    public UUID getId() {
        return id;
    }

    public void setId(UUID id) {
        this.id = id;
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

    public UserSettingsEntity getUserSettings() {
        return userSettings;
    }

    public void setUserSettings(UserSettingsEntity userSettings) {
        this.userSettings = userSettings;
    }

    public List<EventEntity> getEvents() {
        return events;
    }

    public void setEvents(List<EventEntity> events) {
        this.events = events;
    }

    public void addEvent(EventEntity event) {
        events.add(event);
    }

    public void removeEvent(EventEntity event) {
        events.remove(event);
    }

    public List<EventEntity> getMemberOfEvents() {
        return memberOfEvents;
    }

    public void setMemberOfEvents(List<EventEntity> memberOfEvents) {
        this.memberOfEvents = memberOfEvents;
    }

    public void addMemberOfEvent(EventEntity event) {
        memberOfEvents.add(event);
    }

    public void removeMemberOfEvent(EventEntity event) {
        memberOfEvents.remove(event);
    }

    public String getUsername() {
        return username;
    }

    public void setUsername(String username) {
        this.username = username;
    }

    public String getDisplayname() {
        return displayname;
    }

    public void setDisplayname(String displayname) {
        this.displayname = displayname;
    }

    public String getPasswordhash() {
        return passwordhash;
    }

    public void setPasswordhash(String passwordhash) {
        this.passwordhash = passwordhash;
    }

    public String getRole() {
        return role;
    }

    public void setRole(String role) {
        this.role = role;
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

    public UserDTO toDto() {
        return new UserDTO(
            this.getId(),
            this.getUsername(),
            this.getDisplayname(),
            this.getRole(),
            this.getCreatedAt().toString(),
            this.getEditedAt().toString()
        );
    }
}
