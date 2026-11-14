package com.skillbattles.backend.processor;
import com.skillbattles.backend.dto.AccountStateDto;
import java.util.UUID;
public interface AccountProcessor {AccountStateDto state(UUID userId);}
