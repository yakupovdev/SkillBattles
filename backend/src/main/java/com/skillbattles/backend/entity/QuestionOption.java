package com.skillbattles.backend.entity;

import lombok.*;
import java.util.UUID;

/** A JSONB value, not a separate JPA aggregate. */
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@EqualsAndHashCode
public class QuestionOption {
    private UUID id;
    private String key;
    private String text;
}
