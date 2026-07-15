package com.fhsocial.backend.Repositories;

import org.springframework.data.jpa.repository.JpaRepository;

import com.fhsocial.backend.Entities.UserEntity;

import java.util.List;
import java.util.UUID;

public interface UserRepository extends JpaRepository<UserEntity, UUID> {
    List<UserEntity> findAllByEvents_Id(UUID eventId);
    boolean existsByUsername(String username);
}