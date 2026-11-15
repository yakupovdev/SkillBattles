package com.skillbattles.backend.config;

import com.skillbattles.backend.service.QuestionImageService;
import org.springframework.context.annotation.Configuration;
import org.springframework.core.io.Resource;
import org.springframework.http.CacheControl;
import org.springframework.web.servlet.config.annotation.ResourceHandlerRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;
import org.springframework.web.servlet.resource.PathResourceResolver;
import java.io.IOException;
import java.time.Duration;
import java.util.regex.Pattern;

@Configuration
public class QuestionImageResourceConfig implements WebMvcConfigurer {
    @Override
    public void addResourceHandlers(ResourceHandlerRegistry registry) {
        registry.addResourceHandler("/media/questions/**")
                .addResourceLocations("classpath:/question-images/")
                .setCacheControl(CacheControl.maxAge(Duration.ofDays(365)).cachePublic().immutable())
                .resourceChain(true)
                .addResolver(new PathResourceResolver() {
                    private final Pattern key = Pattern.compile(QuestionImageService.KEY_PATTERN);

                    @Override
                    protected Resource getResource(String path, Resource location) throws IOException {
                        return key.matcher(path).matches() ? super.getResource(path, location) : null;
                    }
                });
    }
}
