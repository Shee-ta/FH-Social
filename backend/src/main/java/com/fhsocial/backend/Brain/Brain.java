package com.fhsocial.backend.Brain;

import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.LinkedHashSet;
import java.util.stream.Collectors;
import java.util.stream.Stream;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.ai.chat.client.ChatClient;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.fhsocial.backend.Entities.EventEntity;
import com.fhsocial.backend.Entities.FilePreviewEntity;
import com.fhsocial.backend.Repositories.EventRepository;

import reactor.core.publisher.Flux;

@Service
public class Brain {

    private static final int MAX_RECOMMENDATION_LENGTH = 600;
    private static final int MAX_TAG_LENGTH = 255;
    private static final int MAX_TAG_COUNT = 10;

    private Map<Request, String> contextMap = new HashMap<>();

    private final ChatClient chatClient;
    private final EventRepository eventRepository;
    
    Logger logger = LoggerFactory.getLogger(Brain.class);

    private static String systemPrompt = """
        You are an assistant for the app FH Social.
        The app's purpose is for students to schedule meetings with locations to study together.
        Answer questions about meetings and documents related to the meetings.
        The documents can be lessons, excercise sheets or something else.
    """;

    private String promptBuilder(EventEntity event, List<FilePreviewEntity> files, List<String> tags) {
        StringBuilder stringBuilder = new StringBuilder();
        stringBuilder.append("Event data: ");
        stringBuilder.append(event.toString());

        for(FilePreviewEntity file : files) {
            stringBuilder.append("\n\nFile data of: " +  file.getOriginalFileName() + "\n\n");
            stringBuilder.append(file.toString());
        }
        if(tags != null && !tags.isEmpty()) {
            stringBuilder.append("\n\nExisting tags: " + String.join(", ", tags));
        }
        stringBuilder.append("\n\n");
        return stringBuilder.toString();
    }

    private Flux<String> getAnswerStream(String context, String prompt) {

        String userPrompt = context + prompt;

        return chatClient.prompt()
            .system(systemPrompt)
            .user(userPrompt)
            .stream()
            .content();
    }

    public Brain(ChatClient.Builder builder, EventRepository eventRepository) {
        this.eventRepository = eventRepository;
        this.chatClient = builder.build();

        contextMap.put(Request.DEFAULT_CONTEXT,
            "Analyse the contents of the file(s) (if they exist) and the fields of the meetup-event (if they exist) and ");
        contextMap.put(Request.RECOMMENDATION,
            contextMap.get(Request.DEFAULT_CONTEXT) + """
            write a study plan that explains how students can learn the tasks efficiently, and what is learnt
            today, for example: 
            "Topics for today's session
            ────────────────────────

            ✓ Graph representations
            ✓ Dijkstra

            Recommended order:
            1. Review graph basics (15 min)
            2. Solve Tasks 1–2 (30 min)
            3. Discuss Task 3 (20 min)
            and then adding a one-sentence learn recommendation like: "You study most efficiently by
            forming a small teams and dividing the work clearly by <include how to divide work>. Keep it all short and precise with no more than 400 chars. 
            """);
         contextMap.put(Request.TAGS,
            contextMap.get(Request.DEFAULT_CONTEXT) + """
            generate relevant tags (around five or less) in English for this event based on the topics in the file 
            content (if existing) and event content if given and if you consider them relevant (e.g. "Algebra / Mathe 3" as title -> "Mathematik"-tag), 
            separated by commas, for example: \"UX/UI Design, Mathematics 4, Python\". 
            Do not use any extra text or formatting. Tags must be very short and concise, no more than 20 characters each.
            If a list of tags is given in the prompt and the tags you would generate are very similar or
            abbrevations of them, use the relevant ones in the list rather than generating new ones.
            """);
        contextMap.put(Request.CHAT, """
            answer the user's question using the
            provided document contents and event data below. The documents are OCR/extracted text of
            PDF learning materials. If the answer is not contained in the provided material, say so
            briefly instead of inventing facts. Answer in the same language as the user's question.
            Be concise, clear and helpful. Do not mention that
            you received the text as context.
            """);
    }

    public String answerFileQuestion(List<FilePreviewEntity> files, String userPrompt) {
        try {
            StringBuilder context = new StringBuilder(contextMap.get(Request.CHAT));
            context.append("\n\n");

            if (files == null || files.isEmpty()) {
                context.append("No document contents were provided. Answer generally and, if helpful, "
                    + "point out that no documents were selected.\n\n");
            } else {
                for (FilePreviewEntity file : files) {
                    context.append("Document \"").append(file.getOriginalFileName()).append("\":\n");
                    context.append(file.getPreprocessedContent()).append("\n\n");
                }
            }

            Flux<String> responseStream = getAnswerStream(context.toString(), userPrompt);

            String response = responseStream
                .filter(line -> line != null && !line.equals("[DONE]"))
                .collect(Collectors.joining())
                .block();

            return response == null ? "" : response.trim();
        } catch (Exception e) {
            logger.warn("Error while answering file question", e);
            return null;
        }
    }

    @Transactional
    public boolean generateRecommendation(Request request, List<FilePreviewEntity> files, EventEntity event, List<String> tags) {
        try {
            String prompt = promptBuilder(event, files, tags);
            Flux<String> responseStream = getAnswerStream(contextMap.get(request), prompt);

            String response = responseStream
                .filter(line -> line != null && !line.equals("[DONE]"))
                .collect(Collectors.joining())
                .block();

            event.setRecommendation(sanitizeRecommendation(response));

            eventRepository.save(event);
            eventRepository.flush();

            return true;
        }
        catch (Exception e) {
            logger.warn("Error while generating recommendation for event with id={}", event.getId(), e);
            return false;
        }
    }

    @Transactional
    public boolean generateTags(Request request, EventEntity event, List<FilePreviewEntity> files, List<String> tags) {

        try {
            String prompt = promptBuilder(event, files, tags);
            Flux<String> responseStream = getAnswerStream(contextMap.get(request), prompt);

            String response = responseStream
                .filter(line -> line != null && !line.equals("[DONE]"))
                .collect(Collectors.joining())
                .block();

            List<String> generatedTags = List.of();

            if (response != null && !response.isBlank()) {
                String[] tagsArray = response.split(",");
                generatedTags = Stream.of(tagsArray)
                    .map(String::trim)
                    .filter(tag -> !tag.isEmpty())
                    .map(this::sanitizeTag)
                    .filter(tag -> !tag.isEmpty())
                    .collect(Collectors.collectingAndThen(
                        Collectors.toCollection(LinkedHashSet::new),
                        uniqueTags -> uniqueTags.stream().limit(MAX_TAG_COUNT).toList()
                    ));
            }

            event.getTags().clear();
            event.getTags().addAll(generatedTags);

            eventRepository.save(event);
            eventRepository.flush();

            return true;
        } 
        catch (Exception e) {
            logger.warn("Error while generating tags for event with id={}", event.getId(), e);
            return false;
        }
    }

    private String sanitizeRecommendation(String recommendation) {
        if (recommendation == null) {
            return "";
        }
        String normalized = recommendation.trim();
        if (normalized.length() <= MAX_RECOMMENDATION_LENGTH) {
            return normalized;
        }
        return normalized.substring(0, MAX_RECOMMENDATION_LENGTH);
    }

    private String sanitizeTag(String tag) {
        if (tag == null) {
            return "";
        }
        String normalized = tag.trim();
        if (normalized.length() <= MAX_TAG_LENGTH) {
            return normalized;
        }
        return normalized.substring(0, MAX_TAG_LENGTH);
    }
}

