package com.skillbattles.backend.service;
import com.skillbattles.backend.exception.*;import java.time.*;import org.junit.jupiter.api.*;import org.junit.jupiter.params.ParameterizedTest;import org.junit.jupiter.params.provider.CsvSource;import static org.assertj.core.api.Assertions.*;
class AgePolicyTest {
 // UTC is already November 15; the age boundary must still use November 14 ET.
 final AgePolicy policy=new AgePolicy(Clock.fixed(Instant.parse("2026-11-15T02:00:00Z"),ZoneOffset.UTC));
 @ParameterizedTest @CsvSource({"2013,11,14","2013,11,13","2013,10,","1900,1,","2000,2,29"})
 void permitsBirthdayAndOlderWithoutUpperAgeLimit(Integer y,Integer m,Integer d){assertThatCode(()->policy.validate(y,m,d)).doesNotThrowAnyException();}
 @ParameterizedTest @CsvSource({"2013,11,15","2013,12,","2014,1,"})
 void rejectsUnderThirteen(Integer y,Integer m,Integer d){assertThatThrownBy(()->policy.validate(y,m,d)).isInstanceOf(AgeRestrictedException.class);}
 @ParameterizedTest @CsvSource({"2027,1,","2026,12,","2026,11,15","2001,2,29","2000,13,1","1899,1,1"})
 void invalidOrFutureDateIsValidationError(Integer y,Integer m,Integer d){assertThatThrownBy(()->policy.validate(y,m,d)).isInstanceOf(FieldValidationException.class);}
 @Test void requiresDayOnlyAtBoundaryMonth(){assertThatThrownBy(()->policy.validate(2013,11,null)).isInstanceOfSatisfying(FieldValidationException.class,e->assertThat(e.getField()).isEqualTo("birthDay"));}
}
