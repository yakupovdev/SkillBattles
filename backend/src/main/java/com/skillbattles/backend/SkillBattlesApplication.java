package com.skillbattles.backend;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

@SpringBootApplication
public class SkillBattlesApplication {
    public static void main(String[] args) {
        var context = SpringApplication.run(SkillBattlesApplication.class, args);
        if (context.getEnvironment().matchesProfiles("question-import")) context.close();
    }
}
