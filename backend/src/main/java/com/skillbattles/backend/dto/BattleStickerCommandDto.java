package com.skillbattles.backend.dto;
import lombok.*;
import java.util.UUID;
@Value
public class BattleStickerCommandDto { String stickerId; UUID submissionId; }
