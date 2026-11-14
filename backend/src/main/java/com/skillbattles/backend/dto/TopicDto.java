package com.skillbattles.backend.dto;

import com.skillbattles.backend.entity.*;
import lombok.*;
import java.util.*;

@Data @NoArgsConstructor @AllArgsConstructor
public class TopicDto {
    private String topicCode;
    private String topicName;
}
