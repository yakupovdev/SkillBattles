package com.skillbattles.backend.client;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.mail.SimpleMailMessage;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.beans.factory.ObjectProvider;
import org.springframework.stereotype.Component;
import java.net.URI;
@Component public class SmtpResetMailClient implements ResetMailClient {
 private final ObjectProvider<JavaMailSender> sender; private final String base; private final String from; private final String host;
 public SmtpResetMailClient(ObjectProvider<JavaMailSender> sender,@Value("${app.password-reset.base-url:}")String base,@Value("${app.password-reset.from:}")String from,@Value("${spring.mail.host:}")String host){this.sender=sender;this.base=base;this.from=from;this.host=host;}
 @Override public boolean available(){
  try { var uri=URI.create(base);return !host.isBlank()&&!from.isBlank()&&uri.getHost()!=null&&uri.getRawQuery()==null&&uri.getFragment()==null&&java.util.Set.of("http","https").contains(uri.getScheme())&&sender.getIfAvailable()!=null; }catch(IllegalArgumentException ex){return false;}
 }
 @Override public void send(String email,String token) {
  var message=new SimpleMailMessage();message.setTo(email);message.setFrom(from);message.setSubject("Reset your SkillBattles password");
  message.setText("Use this link within 20 minutes to reset your password: "+base+"?token="+token+"\nIf you did not request this, ignore this email.");
  sender.getObject().send(message);
 }
}
