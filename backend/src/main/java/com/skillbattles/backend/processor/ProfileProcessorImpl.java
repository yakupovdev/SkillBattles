package com.skillbattles.backend.processor;
import com.skillbattles.backend.dto.*;
import com.skillbattles.backend.service.*;
import java.util.UUID;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;
@Component @RequiredArgsConstructor public class ProfileProcessorImpl implements ProfileProcessor {
 private final UserService users; private final RefreshTokenService refresh; private final SubscriptionService subscriptions;
 @Override @Transactional public UserDto update(UUID id,ProfileUpdateDto dto) {
  var user=users.update(id,dto); if(dto.getNewPassword()!=null)refresh.revokeAll(id);
  user.setPro(subscriptions.entitlements(id).isPro()); return user;
 }
}
