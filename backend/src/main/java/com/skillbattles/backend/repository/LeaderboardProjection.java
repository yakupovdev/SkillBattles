package com.skillbattles.backend.repository;
import java.util.UUID;
public interface LeaderboardProjection {long getPosition();UUID getUserId();String getNickname();int getRating();int getCalibrationCompletedMatches();}
