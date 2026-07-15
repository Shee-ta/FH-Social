package com.fhsocial.backend.Init;

import java.time.Duration;
import java.time.Instant;
import java.time.ZoneId;
import java.time.ZonedDateTime;
import java.time.temporal.ChronoUnit;
import java.util.ArrayList;
import java.util.List;

import org.springframework.boot.CommandLineRunner;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Component;

import com.fhsocial.backend.Entities.EventEntity;
import com.fhsocial.backend.Entities.UserEntity;
import com.fhsocial.backend.Repositories.AuthRepository;
import com.fhsocial.backend.Repositories.EventRepository;
import com.fhsocial.backend.Repositories.UserRepository;

@Component
public class PostgresInit implements CommandLineRunner {

    private final UserRepository userRepository;
    private final AuthRepository authRepository;
    private final EventRepository eventRepository;
    private final PasswordEncoder passwordEncoder;

    private static final ZoneId ZONE = ZoneId.of("Europe/Berlin");

    public PostgresInit(
        UserRepository userRepository,
        AuthRepository authRepository,
        EventRepository eventRepository
    ) {
        this.userRepository = userRepository;
        this.authRepository = authRepository;
        this.eventRepository = eventRepository;
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

    /** ISO-8601 UTC string for a given day offset and Berlin wall-clock time. */
    private String isoAt(int dayOffset, int hour, int minute) {
        ZonedDateTime zdt = ZonedDateTime.now(ZONE)
            .plusDays(dayOffset)
            .withHour(hour)
            .withMinute(minute)
            .withSecond(0)
            .withNano(0);
        return zdt.toInstant().toString();
    }

    /** ISO-8601 UTC string relative to the current moment (for "live" demo). */
    private String isoFromNow(long minutesOffset) {
        return Instant.now()
            .plus(Duration.ofMinutes(minutesOffset))
            .truncatedTo(ChronoUnit.SECONDS)
            .toString();
    }

    private void generateEvent(
        String creatorUsername,
        List<String> memberUsernames,
        String title,
        String start,
        String end,
        String location,
        String description,
        String recommendation,
        double latitude,
        double longitude,
        List<String> days,
        List<String> tags
    ) {
        UserEntity creator = authRepository.findByUsername(creatorUsername).orElse(null);
        if (creator == null) {
            return;
        }

        EventEntity event = new EventEntity();
        event.setCreator(creator);
        event.setTitle(title);
        event.setIso8601startDateTime(start);
        event.setIso8601endDateTime(end);
        event.setLocation(location);
        event.setDescription(description);
        event.setRecommendation(recommendation);
        event.setLatitude(latitude);
        event.setLongitude(longitude);
        event.setDays(new ArrayList<>(days));
        event.setTags(new ArrayList<>(tags));

        for (String memberUsername : memberUsernames) {
            authRepository.findByUsername(memberUsername).ifPresent(event::addMember);
        }

        eventRepository.save(event);
    }

    private void seedExampleEvents() {
        if (eventRepository.count() > 0) {
            return;
        }

        // Läuft gerade (Demo für den "Live"-Status)
        generateEvent(
            "trish",
            List.of("angel", "sky"),
            "Datenbanken – Übung",
            isoFromNow(-60),
            isoFromNow(60),
            "A.E.0.4",
            "Wir gehen gemeinsam die SQL-Übungsblätter durch und bereiten uns auf die Abgabe vor.",
            "Teilt die Aufgaben im Team auf und vergleicht am Ende eure Lösungen.",
            51.4940, 7.4210,
            List.of(),
            List.of("Datenbanken", "SQL", "Übung")
        );

        // Heute, startet in 2 Stunden
        generateEvent(
            "elise",
            List.of("sky", "trish"),
            "Programmieren 2",
            isoAt(0, 16, 0),
            isoAt(0, 18, 0),
            "A.E.0.1",
            "Vorbereitung auf die Klausur: Vererbung, Interfaces und ein paar alte Prüfungsaufgaben.",
            "Bildet kleine Teams und lasst euch gegenseitig den Code erklären.",
            51.4939, 7.4200,
            List.of(),
            List.of("Programmierung", "Java", "Klausur")
        );

        // Wöchentlich Montag & Mittwoch
        generateEvent(
            "angel",
            List.of("elise"),
            "Mathe 4 – Analysis",
            isoAt(0, 10, 0),
            isoAt(0, 11, 30),
            "B.E.1.10",
            "Wiederholung von Reihen und Konvergenz. Bringt eure Fragen aus der Vorlesung mit.",
            "Rechnet vorab je eine Aufgabe, damit wir gezielt Unklarheiten besprechen können.",
            51.4942, 7.4205,
            List.of("Mo", "We"),
            List.of("Mathematik", "Analysis")
        );

        // Morgen Nachmittag
        generateEvent(
            "sky",
            List.of("lily", "trish"),
            "Statistik 1",
            isoAt(1, 14, 0),
            isoAt(1, 15, 30),
            "Bibliothek – Gruppenraum 2",
            "Deskriptive Statistik und erste Wahrscheinlichkeitsrechnung mit Beispielaufgaben.",
            "Nutzt eine gemeinsame Formelsammlung und teilt sie vor dem Treffen.",
            51.4936, 7.4192,
            List.of(),
            List.of("Statistik", "Mathematik")
        );
    }

    @Override
    public void run(String... args) throws Exception {
        generateUser("lily", "Lily Lavender", "admin", "123");
        generateUser("elise", "Elise Lavender", "student", "123");
        generateUser("angel", "Angel", "admin", "123");
        generateUser("sky", "Sky", "student", "123");
        generateUser("trish", "Trishums", "student", "123");

        seedExampleEvents();
    }
}
