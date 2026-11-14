package com.skillbattles.backend.service;
import com.skillbattles.backend.entity.PasswordResetToken;
import com.skillbattles.backend.repository.PasswordResetRepository;
import com.skillbattles.backend.exception.BusinessValidationException;
import java.time.*;
import java.util.UUID;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
@Service @RequiredArgsConstructor @Transactional(readOnly=true)
public class PasswordResetServiceImpl implements PasswordResetService {
 private final PasswordResetRepository repository; private final Clock clock;
 @org.springframework.beans.factory.annotation.Value("${app.password-reset.ttl:PT20M}") private Duration ttl=Duration.ofMinutes(20);
 @jakarta.annotation.PostConstruct void validateTtl(){if(!Duration.ofMinutes(20).equals(ttl))throw new IllegalArgumentException("Password reset TTL must be PT20M.");}
 @Override @Transactional public void store(UUID user,String hash) { var t=new PasswordResetToken();t.setUserId(user);t.setTokenHash(hash);t.setExpiresAt(clock.instant().plus(ttl));repository.saveAndFlush(t); }
 @Override public UUID owner(String hash) { return repository.findByTokenHash(hash).filter(t -> t.getConsumedAt()==null && t.getExpiresAt().isAfter(clock.instant())).orElseThrow(PasswordResetServiceImpl::invalid).getUserId(); }
 @Override @Transactional public void consume(String hash,UUID owner) {
  if(repository.consume(hash,owner,clock.instant())!=1)throw invalid();
 }
 private static BusinessValidationException invalid(){return new BusinessValidationException("INVALID_RESET_TOKEN","Reset token is invalid or expired.");}
}
