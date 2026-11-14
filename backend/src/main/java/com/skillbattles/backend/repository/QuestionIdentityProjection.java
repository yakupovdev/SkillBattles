package com.skillbattles.backend.repository;

import java.util.UUID;

public interface QuestionIdentityProjection {
    UUID getId();
    String getExternalKey();
}
