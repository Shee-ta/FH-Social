package com.fhsocial.backend.Repositories;

import org.springframework.data.jpa.repository.JpaRepository;

import com.fhsocial.backend.Entities.UserSettingsEntity;

import java.util.UUID;

public interface UserSettingsRepository extends JpaRepository<UserSettingsEntity, UUID> {
    
}