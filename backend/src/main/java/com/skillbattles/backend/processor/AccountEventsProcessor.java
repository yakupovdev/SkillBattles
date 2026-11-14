package com.skillbattles.backend.processor;
import com.skillbattles.backend.dto.AccountChangedEvent;
public interface AccountEventsProcessor {void changed(AccountChangedEvent event);}
