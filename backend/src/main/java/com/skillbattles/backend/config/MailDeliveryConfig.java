package com.skillbattles.backend.config;
import org.springframework.context.annotation.*;
import org.springframework.scheduling.concurrent.ThreadPoolTaskExecutor;
@Configuration public class MailDeliveryConfig {
 @Bean public ThreadPoolTaskExecutor mailDeliveryExecutor(){
  var executor=new ThreadPoolTaskExecutor();executor.setCorePoolSize(1);executor.setMaxPoolSize(2);executor.setQueueCapacity(100);
  executor.setThreadNamePrefix("password-reset-mail-");executor.setWaitForTasksToCompleteOnShutdown(true);executor.setAwaitTerminationSeconds(5);return executor;
 }
}
