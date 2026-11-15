package com.skillbattles.backend.controller;

import org.springframework.context.annotation.Profile;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.GetMapping;

/** Explicit client routes: unknown assets, APIs and namespaces never become index.html. */
@Controller
@Profile("heroku")
@io.swagger.v3.oas.annotations.Hidden
public class HerokuFrontendController {
    @GetMapping({"/", "/auth", "/auth/forgot", "/auth/reset", "/billing/return",
            "/play/search", "/play/duel", "/profile", "/profile/edit", "/leaderboard", "/history", "/pro",
            "/friends", "/friends/{id:[0-9a-fA-F\\-]{36}}",
            "/battle/{id:[0-9a-fA-F\\-]{36}}", "/result/{id:[0-9a-fA-F\\-]{36}}"})
    public String index() { return "forward:/index.html"; }
}
