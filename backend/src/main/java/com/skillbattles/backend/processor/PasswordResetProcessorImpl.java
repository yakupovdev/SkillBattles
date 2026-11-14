package com.skillbattles.backend.processor;
import com.skillbattles.backend.service.*;
import com.skillbattles.backend.client.ResetMailClient;
import com.skillbattles.backend.exception.*;
import java.security.SecureRandom;
import java.util.*;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;
import org.springframework.transaction.support.TransactionTemplate;
import org.springframework.transaction.PlatformTransactionManager;
import org.springframework.scheduling.concurrent.ThreadPoolTaskExecutor;
@Component @RequiredArgsConstructor @Slf4j
public class PasswordResetProcessorImpl implements PasswordResetProcessor {
 private final UserService users;private final PasswordResetService resets;private final RefreshTokenService refresh;private final TokenService tokens;
 private final ResetMailClient mail;private final RequestRateLimiter limiter;private final PlatformTransactionManager transactions;
 private final ThreadPoolTaskExecutor mailDeliveryExecutor;
 private final SecureRandom random=new SecureRandom();
 @Override public void request(String email,String ip) {
  String normalized=email.trim().toLowerCase(Locale.ROOT);
  limiter.check("reset-ip:"+ip,30);limiter.check("reset-email:"+tokens.hash(normalized),3);
  if(!mail.available())throw new EmailUnavailableException();
  // Always dispatch the same task and return before looking up the account or contacting SMTP.
  try { mailDeliveryExecutor.execute(() -> deliver(normalized)); }
  catch(org.springframework.core.task.TaskRejectedException ex){throw new EmailUnavailableException();}
 }
 private void deliver(String email) {
  try {
   byte[] bytes=new byte[32];random.nextBytes(bytes);String raw=Base64.getUrlEncoder().withoutPadding().encodeToString(bytes);
   Boolean exists=new TransactionTemplate(transactions).execute(s -> {var user=users.findByEmail(email);user.ifPresent(u -> resets.store(u.getId(),tokens.hash(raw)));return user.isPresent();});
   if(Boolean.TRUE.equals(exists))mail.send(email,raw);
  }catch(RuntimeException ex){log.warn("Password reset delivery failed: {}",ex.getClass().getSimpleName());}
 }
 @Override public void confirm(String raw,String password,String ip) {
  limiter.check("reset-confirm:"+ip,30);
  new TransactionTemplate(transactions).executeWithoutResult(s -> {
   String hash=tokens.hash(raw);UUID owner=resets.owner(hash);
   try {users.lockActiveById(owner);}catch(UnauthorizedException ex){throw new BusinessValidationException("INVALID_RESET_TOKEN","Reset token is invalid or expired.");}
   resets.consume(hash,owner);users.resetPassword(owner,password);refresh.revokeAll(owner);
  });
 }
}
