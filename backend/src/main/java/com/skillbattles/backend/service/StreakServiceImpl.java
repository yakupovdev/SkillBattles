package com.skillbattles.backend.service;
import com.skillbattles.backend.dto.StreaksDto;
import com.skillbattles.backend.repository.StreakRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.time.*;
import java.util.UUID;
@Service @RequiredArgsConstructor @Transactional(readOnly=true)
public class StreakServiceImpl implements StreakService {
    private final StreakRepository repository;private final Clock clock;
    @Override @Transactional public boolean qualify(UUID user,Instant at){return repository.qualify(user,EtCalendar.date(at))>0;}
    @Override public StreaksDto current(UUID user){return StreakCalculator.calculate(repository.dates(user),EtCalendar.date(clock.instant()));}
}
