package com.skillbattles.backend.dto;
import lombok.*;
@Getter @Setter public class TopicStats {
 private String topicCode;private String topicName;private int questionCount;private int correctCount;private double accuracyPercent;@io.swagger.v3.oas.annotations.media.Schema(nullable=true) private Long avgAnswerTimeMs;
 @com.fasterxml.jackson.annotation.JsonProperty("isWeakTopic") private boolean weakTopic;
}
