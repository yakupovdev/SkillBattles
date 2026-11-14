package com.skillbattles.backend.processor;

import com.skillbattles.backend.dto.ReportDto;
import java.util.UUID;

public interface RoundActionsProcessor {
    ReportDto report(UUID battle, UUID round, UUID user, String reason, String comment);
}
