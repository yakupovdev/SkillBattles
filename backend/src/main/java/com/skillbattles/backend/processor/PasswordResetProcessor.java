package com.skillbattles.backend.processor;
public interface PasswordResetProcessor { void request(String email,String ip); void confirm(String token,String password,String ip); }
