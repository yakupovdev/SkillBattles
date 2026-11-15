package com.skillbattles.backend.config;

import io.swagger.v3.oas.models.media.*;
import io.swagger.v3.oas.models.responses.ApiResponse;
import org.springdoc.core.customizers.OpenApiCustomizer;
import org.springframework.context.annotation.*;
import java.util.*;

/** JSON responses always include every property, including explicit null values. */
@Configuration
public class ApiSchemaConfig {
 @Bean OpenApiCustomizer responseSchemaConventions(){return api->{
  Set<String> visited=new HashSet<>();
  api.getPaths().forEach((path,item)->item.readOperations().forEach(operation->{
   if(path.startsWith("/media/questions/")) return; // Resource-handler contracts include binary GET and bodyless HEAD.
   // The input-free invitation snapshot has only the feature contract's 200/401/500 responses.
   if(!"getUsersMeRematchInvitations".equals(operation.getOperationId()))
    operation.getResponses().putIfAbsent("400",new ApiResponse().description("VALIDATION_ERROR"));
   operation.getResponses().putIfAbsent("500",new ApiResponse().description("INTERNAL_ERROR"));
   if(operation.getSecurity()!=null&&operation.getSecurity().stream().anyMatch(s->s.containsKey("accessBearer")||s.containsKey("refreshBearer")))
    operation.getResponses().putIfAbsent("401",new ApiResponse().description("UNAUTHORIZED"));
   operation.getResponses().forEach((code,response)->{
    if(code.startsWith("2")){if(response.getContent()!=null)response.getContent().values().forEach(media->required(media.getSchema(),api.getComponents().getSchemas(),visited));}
    else if(code.matches("[45][0-9][0-9]"))response.setContent(new Content().addMediaType("application/json",new MediaType().schema(new Schema<>().$ref("#/components/schemas/ErrorResponse"))));
   });
  }));
 };}
 private void required(Schema<?> schema,Map<String,Schema> models,Set<String> visited){
  if(schema==null)return;
  if(schema.get$ref()!=null){String name=schema.get$ref().substring(schema.get$ref().lastIndexOf('/')+1);if(visited.add(name))required(models.get(name),models,visited);return;}
  if(schema.getProperties()!=null){schema.setRequired(new ArrayList<>(schema.getProperties().keySet()));schema.getProperties().values().forEach(child->required(child,models,visited));}
  required(schema.getItems(),models,visited);
  if(schema.getAllOf()!=null)schema.getAllOf().forEach(child->required(child,models,visited));
 }
}
