package com.skillbattles.backend.dto;

import com.skillbattles.backend.entity.Subject;
import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class RatingDto {
    private Subject subject;
    private int rating;
    private String rank;
}
