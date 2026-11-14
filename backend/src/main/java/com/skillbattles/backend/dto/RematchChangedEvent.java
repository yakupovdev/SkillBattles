package com.skillbattles.backend.dto;
import java.time.Instant;
public record RematchChangedEvent(RematchDto rematch,Instant occurredAt){}
