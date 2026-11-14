package com.skillbattles.backend.handler;
import org.springframework.web.filter.OncePerRequestFilter;
import org.springframework.stereotype.Component;
import org.springframework.core.annotation.Order;
import org.springframework.core.Ordered;
import jakarta.servlet.*;
import jakarta.servlet.http.*;
import java.io.IOException;
@Component @Order(Ordered.HIGHEST_PRECEDENCE+10)
public class PersonalNoStoreFilter extends OncePerRequestFilter {
    @Override protected void doFilterInternal(HttpServletRequest request,HttpServletResponse response,FilterChain chain) throws ServletException,IOException {
        if(request.getRequestURI().startsWith("/api/v1/"))response.setHeader("Cache-Control","no-store");chain.doFilter(request,response);
    }
}
