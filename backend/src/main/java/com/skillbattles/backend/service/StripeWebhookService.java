package com.skillbattles.backend.service;
import com.fasterxml.jackson.databind.JsonNode;
public interface StripeWebhookService {JsonNode verify(byte[] raw,String signature);}
