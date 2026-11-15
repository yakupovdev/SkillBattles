package com.skillbattles.backend.config;

import io.swagger.v3.oas.models.*;
import io.swagger.v3.oas.models.headers.Header;
import io.swagger.v3.oas.models.media.*;
import io.swagger.v3.oas.models.parameters.PathParameter;
import io.swagger.v3.oas.models.responses.*;
import org.springdoc.core.customizers.OpenApiCustomizer;
import org.springframework.context.annotation.*;
import java.util.*;

/** Document the resource handler without adding duplicate MVC controller mappings. */
@Configuration
public class QuestionImageOpenApiConfig {
    @Bean
    OpenApiCustomizer questionImageOperations() {
        return api -> {
            var path = new PathItem();
            path.addParametersItem(new PathParameter().name("disciplineCode").required(true)
                    .schema(new StringSchema().pattern("^[A-Z][A-Z0-9_]{1,63}$")));
            path.addParametersItem(new PathParameter().name("sourceId").required(true)
                    .schema(new StringSchema().pattern("^[a-f0-9]{8}$")));
            path.addParametersItem(new PathParameter().name("sha256").required(true)
                    .schema(new StringSchema().pattern("^[a-f0-9]{64}$")));
            path.get(operation(false));
            path.head(operation(true));
            api.path("/media/questions/{disciplineCode}/{sourceId}/{sha256}.png", path);
        };
    }

    private Operation operation(boolean head) {
        var success = new ApiResponse().description(head ? "Same PNG metadata as GET; no body." : "Exact original packaged PNG bytes.");
        success.addHeaderObject("Content-Type", header(new StringSchema()._enum(List.of("image/png"))));
        success.addHeaderObject("Content-Length", header(new IntegerSchema().format("int64").minimum(java.math.BigDecimal.ZERO)));
        success.addHeaderObject("Cache-Control", header(new StringSchema().description("public, max-age=31536000, immutable (directive order is not significant)")));
        success.addHeaderObject("X-Content-Type-Options", header(new StringSchema()._enum(List.of("nosniff"))));
        if (!head) success.content(new Content().addMediaType("image/png", new MediaType().schema(new StringSchema().format("binary"))));
        var missing = new ApiResponse().description(head ? "Unknown resource; no body." : "NOT_FOUND; never a SPA or login redirect.");
        if (!head) missing.content(new Content().addMediaType("application/json", new MediaType().schema(new Schema<>().$ref("#/components/schemas/ErrorResponse"))));
        return new Operation().operationId(head ? "headQuestionIllustration" : "getQuestionIllustration")
                .tags(List.of("Battle question images")).security(List.of())
                .summary(head ? "Read packaged illustration metadata" : "Download a packaged question illustration")
                .description("Anonymous read-only illustration. Follow imageUrl from the frozen question. No request body, JWT, upload or directory listing. Malformed/traversal paths are rejected.")
                .responses(new ApiResponses().addApiResponse("200", success)
                        .addApiResponse("304", new ApiResponse().description("Matching Last-Modified validator; no body."))
                        .addApiResponse("404", missing));
    }

    private Header header(Schema<?> schema) { return new Header().schema(schema); }
}
