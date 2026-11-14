package com.skillbattles.backend.service;

import com.skillbattles.backend.dto.*;
import com.skillbattles.backend.entity.Difficulty;
import java.util.*;

public interface DisciplineService {
    List<DisciplineDto> active();
    DisciplineDto get(String code);
    DisciplineDto requireActive(String code);
    void mergeTopics(String code, List<TopicDto> topics);
    int limitSeconds(DisciplineDto discipline, Difficulty difficulty);
}
