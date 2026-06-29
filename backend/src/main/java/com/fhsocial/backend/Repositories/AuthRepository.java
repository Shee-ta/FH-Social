package com.fhsocial.backend.Repositories;

import org.springframework.data.jpa.repository.JpaRepository;

import com.fhsocial.backend.Entities.UserEntity;
import java.util.Optional;
import java.util.UUID;

public interface AuthRepository extends JpaRepository<UserEntity, UUID> {
	Optional<UserEntity> findByUsername(String username);
}