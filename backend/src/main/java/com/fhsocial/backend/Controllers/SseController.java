package com.fhsocial.backend.Controllers;

import org.springframework.web.bind.annotation.CrossOrigin;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.servlet.mvc.method.annotation.SseEmitter;

import com.fhsocial.backend.Services.SseService;

@RestController
@RequestMapping("/sse")
@CrossOrigin(origins = "*")
public class SseController {

    private final SseService sseService;

    public SseController(SseService sseService) {
        this.sseService = sseService;
    }

    @GetMapping
    public SseEmitter connect() {
        return sseService.connect();
    }
}