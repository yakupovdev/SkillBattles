package com.skillbattles.backend.processor;

import com.skillbattles.backend.dto.*;
import com.skillbattles.backend.service.*;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;
import java.util.UUID;

@Component
@RequiredArgsConstructor
@Transactional
public class AuthProcessorImpl implements AuthProcessor {
    private final UserService userService;
    private final RefreshTokenService refreshTokenService;
    private final TokenService tokenService;
    private final RatingService ratingService;
    private final SubscriptionService subscriptions;
    private final org.springframework.transaction.PlatformTransactionManager transactions;

    @Override
    @Transactional(propagation=org.springframework.transaction.annotation.Propagation.NOT_SUPPORTED)
    public AuthDto register(RegisterDto dto) {
        // A unique-code violation aborts PostgreSQL's transaction. Retry the entire
        // registration, ratings/subscription initialization and token issuance.
        for(int attempt=0;attempt<8;attempt++) {
            try { return new org.springframework.transaction.support.TransactionTemplate(transactions)
                    .execute(status -> issue(userService.register(dto)));
            } catch(org.springframework.dao.DataIntegrityViolationException ex){if(!FriendCodeGenerator.collision(ex))throw ex;}
        }
        throw new IllegalStateException("Could not allocate a unique friend code.");
    }

    @Override
    public AuthDto login(LoginDto dto) { return issue(userService.authenticate(dto)); }

    @Override
    public AuthDto refresh(String refreshToken) {
        UUID userId = tokenService.validateRefresh(refreshToken);
        // Lock user before refresh row: same lock order as login/deletion, preventing races and deadlocks.
        UserDto user = userService.lockActiveById(userId);
        refreshTokenService.consume(tokenService.hash(refreshToken), userId);
        return issue(user);
    }

    @Override
    public void logout(String refreshToken) {
        UUID userId = tokenService.validateRefresh(refreshToken);
        refreshTokenService.consume(tokenService.hash(refreshToken), userId);
    }

    @Override
    public void deleteUser(UUID userId) {
        userService.softDelete(userId);
        refreshTokenService.revokeAll(userId);
    }

    private AuthDto issue(UserDto user) {
        ratingService.initialize(user.getId());subscriptions.initialize(user.getId());user.setPro(subscriptions.entitlements(user.getId()).isPro());
        TokenPairDto tokens = tokenService.issue(user.getId());
        refreshTokenService.store(new RefreshTokenDto(user.getId(), tokenService.hash(tokens.getRefreshToken()), tokens.getRefreshExpiresAt()));
        return new AuthDto(tokens, user);
    }
}
