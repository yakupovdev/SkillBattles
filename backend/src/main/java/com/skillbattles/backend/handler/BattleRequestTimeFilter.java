package com.skillbattles.backend.handler;

import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.*;
import lombok.RequiredArgsConstructor;
import org.springframework.core.Ordered;
import org.springframework.core.annotation.Order;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;
import java.io.IOException;
import java.time.Clock;

@Component
@Order(Ordered.HIGHEST_PRECEDENCE)
@RequiredArgsConstructor
public class BattleRequestTimeFilter extends OncePerRequestFilter {
    public static final String RECEIVED_AT = BattleRequestTimeFilter.class.getName() + ".receivedAt";
    private final Clock clock;

    @Override
    protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response, FilterChain chain) throws ServletException, IOException {
        request.setAttribute(RECEIVED_AT, clock.instant().truncatedTo(java.time.temporal.ChronoUnit.MICROS));
        chain.doFilter(request, response);
    }
}
