package com.skillbattles.backend.exception;
import org.springframework.http.HttpStatus;
public class BillingUnavailableException extends BusinessException {
    public BillingUnavailableException() {super("BILLING_UNAVAILABLE","Test billing is unavailable.",HttpStatus.SERVICE_UNAVAILABLE);}
}
