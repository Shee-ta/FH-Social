package com.fhsocial.backend.Services;

import java.io.IOException;
import java.util.Iterator;
import java.util.List;
import java.util.concurrent.CopyOnWriteArrayList;

import org.springframework.stereotype.Service;
import org.springframework.web.servlet.mvc.method.annotation.SseEmitter;

import com.fhsocial.backend.DTO.SseDTO;

@Service
public class SseService {
    
    private final List<SseEmitter> emitters = new CopyOnWriteArrayList<>();

    public SseEmitter connect() {
        SseEmitter emitter = new SseEmitter(0L);

        emitters.add(emitter);

        emitter.onCompletion(() -> emitters.remove(emitter));
        emitter.onTimeout(() -> emitters.remove(emitter));
        emitter.onError(ex -> emitters.remove(emitter));

        return emitter;
    }

    public void sendSseEvent(SseDTO<?> event) {
        Iterator<SseEmitter> iterator = emitters.iterator();

        while (iterator.hasNext()) {
            SseEmitter emitter = iterator.next();

            try {
                emitter.send(
                    SseEmitter.event()
                        .name(event.type().getValue())
                        .data(event.dto())
                );
            } catch (IOException e) {
                emitter.complete();
                emitters.remove(emitter);
            }
        }
    }
}