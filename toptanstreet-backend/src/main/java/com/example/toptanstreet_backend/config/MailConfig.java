package com.example.toptanstreet_backend.config;

import lombok.extern.slf4j.Slf4j;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.core.env.Environment;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.mail.javamail.JavaMailSenderImpl;

import java.util.Properties;

/**
 * E-posta gönderimi için yapılandırmalar içerir
 */
@Configuration
@Slf4j
public class MailConfig {

    private final Environment env;

    public MailConfig(Environment env) {
        this.env = env;
    }

    @Bean
    public JavaMailSender getJavaMailSender() {
        JavaMailSenderImpl mailSender = new JavaMailSenderImpl();
        
        // Ana ayarlar
        mailSender.setHost(env.getProperty("spring.mail.host"));
        mailSender.setPort(Integer.parseInt(env.getProperty("spring.mail.port", "587")));
        mailSender.setUsername(env.getProperty("spring.mail.username"));
        mailSender.setPassword(env.getProperty("spring.mail.password"));
        
        // Debug modunu aktifleştir
        mailSender.setJavaMailProperties(getMailProperties());
        
        // Çalışma modu logu
        log.info("📧 JavaMailSender bean'i yapılandırıldı");
        log.debug("   Host: {}", env.getProperty("spring.mail.host"));
        log.debug("   Port: {}", env.getProperty("spring.mail.port"));
        log.debug("   Username: {}", env.getProperty("spring.mail.username"));
        
        return mailSender;
    }
    
    private Properties getMailProperties() {
        Properties props = new Properties();
        props.put("mail.transport.protocol", "smtp");
        props.put("mail.smtp.auth", env.getProperty("spring.mail.properties.mail.smtp.auth", "true"));
        props.put("mail.smtp.starttls.enable", env.getProperty("spring.mail.properties.mail.smtp.starttls.enable", "true"));
        props.put("mail.smtp.starttls.required", env.getProperty("spring.mail.properties.mail.smtp.starttls.required", "true"));
        props.put("mail.debug", "true"); // Debug modunu aktifleştir
        props.put("mail.smtp.ssl.trust", "*"); // SSL güven sorunlarını önler (dev için güvenli olmayan mod)
        props.put("mail.smtp.ssl.protocols", "TLSv1.2");
        
        // Önemli: 'From' adresi için ayar
        props.put("mail.smtp.from", env.getProperty("spring.mail.username"));
        
        return props;
    }
}
