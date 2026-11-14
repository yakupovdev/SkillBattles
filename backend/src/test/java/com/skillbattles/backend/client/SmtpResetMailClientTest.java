package com.skillbattles.backend.client;
import org.junit.jupiter.api.*;import org.junit.jupiter.api.extension.ExtendWith;import org.mockito.*;import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.beans.factory.ObjectProvider;import org.springframework.mail.SimpleMailMessage;import org.springframework.mail.javamail.JavaMailSender;
import static org.mockito.Mockito.*;import static org.assertj.core.api.Assertions.*;
@ExtendWith(MockitoExtension.class) class SmtpResetMailClientTest {
 @Mock ObjectProvider<JavaMailSender> provider;@Mock JavaMailSender sender;
 @Test void buildsTrustedResetLinkAndUsesConfiguredSenderWithoutNetwork(){
  when(provider.getIfAvailable()).thenReturn(sender);when(provider.getObject()).thenReturn(sender);
  var client=new SmtpResetMailClient(provider,"https://frontend.example/reset-password","test-sender@example.com","smtp.test");assertThat(client.available()).isTrue();client.send("test-user@example.com","opaque_test_fixture_token");
  var capture=ArgumentCaptor.forClass(SimpleMailMessage.class);verify(sender).send(capture.capture());var mail=capture.getValue();assertThat(mail.getTo()).containsExactly("test-user@example.com");assertThat(mail.getFrom()).isEqualTo("test-sender@example.com");assertThat(mail.getText()).contains("https://frontend.example/reset-password?token=opaque_test_fixture_token","20 minutes");
 }
 @Test void missingSettingsAndAmbiguousBaseUrlsDisableDelivery(){
  for(String base:java.util.List.of("","relative/path","https://frontend.example/reset?next=foreign","https://frontend.example/reset#fragment"))assertThat(new SmtpResetMailClient(provider,base,"sender@example.com","smtp.test").available()).isFalse();
  assertThat(new SmtpResetMailClient(provider,"https://frontend.example/reset","sender@example.com","").available()).isFalse();verifyNoInteractions(sender);
 }
}
