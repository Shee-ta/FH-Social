package com.fhsocial.backend.DTO;

public record FileChunkDTO(
int index,
String container,
String title,
String content
) {}
