package com.fhsocial.backend.Init;

import org.springframework.boot.CommandLineRunner;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Component;

import com.fhsocial.backend.Entities.UserEntity;
import com.fhsocial.backend.Repositories.UserRepository;

@Component
public class PostgresInit implements CommandLineRunner {

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;

    public PostgresInit(UserRepository userRepository) {
        this.userRepository = userRepository;
        this.passwordEncoder = new BCryptPasswordEncoder(12);
    }

    private void generateUser(String username, String displayName, String role, String password) {
        if (userRepository.existsByUsername(username)) {
            return;
        }

        UserEntity user = new UserEntity();
        user.setUsername(username);
        user.setDisplayname(displayName);
        user.setPasswordhash(passwordEncoder.encode(password));
        user.setRole(role);
        userRepository.save(user);
    }

    @Override
    public void run(String... args) throws Exception {
        generateUser("lily", "Lily Lavender", "admin", "123");
        generateUser("elise", "Elise Lavender", "student", "123");
        generateUser("angel", "Angel", "admin", "123");
        generateUser("sky", "Sky", "student", "123");
        generateUser("trish", "Trishums", "student", "123");
    }
}
