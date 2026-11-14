package com.skillbattles.backend.processor;

import com.skillbattles.backend.dto.*;
import com.skillbattles.backend.service.*;
import com.skillbattles.backend.exception.*;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;
import java.util.UUID;

@Component
@RequiredArgsConstructor
public class RoundActionsProcessorImpl implements RoundActionsProcessor {
    private final BattleService battles;
    private final BattleAccessProcessor access;
    private final ReportService reports;

    @Override
    @Transactional
    public ReportDto report(UUID battle, UUID round, UUID user, String reason, String comment) {
        var b = battles.getForParticipant(battle, user);
        access.require(b, user);
        var r = b.getState().getRounds().stream()
                .filter(item -> item.getId().equals(round) && item.getStartedAt() != null)
                .findFirst().orElseThrow(() -> new NotFoundException("ROUND_NOT_FOUND", "Round not found."));
        if (!r.isCompleted() && !BattleEngineImpl.terminal(b))
            throw new ConflictException("ROUND_NOT_REVEALED", "Round has not been revealed.");
        return reports.report(new ReportCommandDto(user, battle, round, reason, comment));
    }
}
