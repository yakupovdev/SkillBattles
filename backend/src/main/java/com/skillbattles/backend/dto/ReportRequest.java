package com.skillbattles.backend.dto;
import lombok.*;import jakarta.validation.constraints.*;
@Getter @Setter public class ReportRequest {
 @NotBlank @Pattern(regexp="INCORRECT_ANSWER|UNCLEAR_QUESTION|TYPO|OTHER") private String reason;
 @Size(max=1000) @com.fasterxml.jackson.annotation.JsonSetter(nulls=com.fasterxml.jackson.annotation.Nulls.FAIL) private String comment;
}
