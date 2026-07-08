package com.fhsocial.backend.Brain;

import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;
import java.util.stream.Stream;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.ai.chat.client.ChatClient;
import org.springframework.stereotype.Service;

import com.fhsocial.backend.Entities.EventEntity;
import com.fhsocial.backend.Entities.FilePreviewEntity;
import com.fhsocial.backend.Repositories.EventRepository;

import reactor.core.publisher.Flux;

@Service
public class Brain {

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
            write a recommendation sentence that explains how students can learn the tasks efficiently, 
            for example by forming small teams or dividing the work clearly. Write one short sentence only. 
            Do not use bullets, headings, line breaks, or extra commentary. Keep the sentence natural and complete.
            """);
         contextMap.put(Request.TAGS,
            contextMap.get(Request.DEFAULT_CONTEXT) + """
            generate 3-6 relevant tags in German for this event based on the file 
            content (if existing) and event content if given and if you consider them relevant (e.g. "Algebra / Mathe 3" as title -> "Mathematik"-tag), separated by commas, for example: \"tag1, tag2, tag3\". 
            Do not use any extra text or formatting. 
            If a list of tags is given in the prompt and the tags you would generate are very similar or
            abbrevations of them, use the relevant ones in the list rather than generating new ones.
            """);
        contextMap.put(Request.DESCRIPTION, 
            contextMap.get(Request.DEFAULT_CONTEXT) + """   
            (re-)write a description of 200-3000 characters about the meetup-event
            """);
        contextMap.put(Request.EXPLAIN, 
            contextMap.get(Request.DEFAULT_CONTEXT) + """
            Explain the task in this file and consider the input of the user if given: 
            """);
        contextMap.put(Request.TASK, 
            contextMap.get(Request.DEFAULT_CONTEXT) + """
            Generate a task that is similar to the one in the file and consider the input of the user if given: 
            """);
    }

    public boolean generateRecommendation(Request request, List<FilePreviewEntity> files, EventEntity event, List<String> tags) {
        String prompt = promptBuilder(event, files, tags);
        Flux<String> responseStream = getAnswerStream(contextMap.get(request), prompt);

        String response = responseStream
            .collect(Collectors.joining())
            .block();

        event.setRecommendation(response);
        eventRepository.save(event);
        return true;
    }

    public boolean generateTags(Request request, EventEntity event, List<FilePreviewEntity> files, List<String> tags) {
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
                .toList();
        }

        event.setTags(generatedTags);
        eventRepository.save(event);
        return true;
    }
}

