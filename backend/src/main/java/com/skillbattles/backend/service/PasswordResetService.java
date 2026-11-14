package com.skillbattles.backend.service;
import java.util.UUID;
public interface PasswordResetService { void store(UUID user,String hash); UUID owner(String hash); void consume(String hash,UUID owner); }
