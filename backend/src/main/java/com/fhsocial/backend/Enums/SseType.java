package com.fhsocial.backend.Enums;

import com.fasterxml.jackson.annotation.JsonValue;

public enum SseType {
    ADD_USER("addUser"),
    REMOVE_USER("removeUser"),
    ADD_EVENT("addEvent"),
    REMOVE_EVENT("removeEvent"),  
    ADD_MEMBER("addMember"),
    REMOVE_MEMBER("removeMember"),
    ADD_COMMENT("addComment"),
    REMOVE_COMMENT("removeComment"),
    ADD_FILE_PREVIEW("addFilePreview"),
    REMOVE_FILE_PREVIEW("removeFilePreview");

    private final String value;

    SseType(String value) {
        this.value = value;
    }

    @JsonValue
    public String getValue() {
        return value;
    }
}
