package com.skillbattles.backend.dto;
import lombok.Value;
@Value public class LeaderboardEntry {long position;PublicPlayer player;int rating;String rankCode;@com.fasterxml.jackson.annotation.JsonProperty("isCalibrating") boolean calibrating;}
