package com.skillbattles.backend.dto;

import jakarta.validation.ConstraintValidator;
import jakarta.validation.ConstraintValidatorContext;
import java.nio.charset.StandardCharsets;

public class PasswordBytesValidator implements ConstraintValidator<PasswordBytes, String> {
    private int minimum=8;
    @Override public void initialize(PasswordBytes constraint){minimum=constraint.min();}
    @Override
    public boolean isValid(String value, ConstraintValidatorContext context) {
        if (value == null) return true;
        int bytes = value.getBytes(StandardCharsets.UTF_8).length;
        return bytes >= minimum && bytes <= 72;
    }
}
