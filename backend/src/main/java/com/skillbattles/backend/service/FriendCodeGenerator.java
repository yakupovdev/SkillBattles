package com.skillbattles.backend.service;
import org.springframework.stereotype.Component;
import java.security.SecureRandom;
import java.util.Locale;
import com.skillbattles.backend.exception.BusinessValidationException;

@Component
public class FriendCodeGenerator {
    public static final String ALPHABET="ABCDEFGHJKMNPQRSTUVWXYZ23456789";
    private final SecureRandom random=new SecureRandom();
    public String next() {
        var result=new StringBuilder(12);
        for(int i=0;i<12;i++)result.append(ALPHABET.charAt(random.nextInt(ALPHABET.length())));
        return result.toString();
    }
    public static String normalize(String input) {
        if(input==null || input.length()>32)throw invalid();
        String code=input.strip().replace("-","").toUpperCase(Locale.ROOT);
        if(!input.chars().allMatch(c->c<128)||!code.matches("["+ALPHABET+"]{12}"))throw invalid();
        return code;
    }
    private static BusinessValidationException invalid(){return new BusinessValidationException("VALIDATION_ERROR","Invalid friend code.");}
    public static boolean collision(Throwable error) {
        for(Throwable e=error;e!=null;e=e.getCause())
            if(e instanceof org.hibernate.exception.ConstraintViolationException c && "ux_users_friend_code".equals(c.getConstraintName()))return true;
        return false;
    }
}
