package com.skillbattles.backend.exception;
import lombok.Getter;
@Getter
public class FieldValidationException extends BusinessValidationException {
    private final String field;
    public FieldValidationException(String field, String message) { super("VALIDATION_ERROR", message); this.field=field; }
}
