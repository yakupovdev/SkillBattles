package com.skillbattles.backend.client;
public interface ResetMailClient { boolean available(); void send(String email,String token); }
