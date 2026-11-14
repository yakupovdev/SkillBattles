package com.skillbattles.backend.dto;
import lombok.*;
@Getter @Setter public class TopicStatsDto {
 private String topicCode;private String topicName;private int questionCount;private int correctCount;private double accuracyPercent;private Long avgAnswerTimeMs;
 @com.fasterxml.jackson.annotation.JsonProperty("isWeakTopic") private boolean weakTopic;
}
