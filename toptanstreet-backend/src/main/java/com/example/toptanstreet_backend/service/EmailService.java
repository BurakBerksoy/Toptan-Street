package com.example.toptanstreet_backend.service;

import jakarta.mail.MessagingException;
import jakarta.mail.internet.MimeMessage;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.mail.javamail.MimeMessageHelper;
import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
@Slf4j
public class EmailService {

    @org.springframework.beans.factory.annotation.Value("${spring.mail.host:smtp.gmail.com}")
    private String mailHost;
    
    @org.springframework.beans.factory.annotation.Value("${spring.mail.port:587}")
    private String mailPort;
    
    @org.springframework.beans.factory.annotation.Value("${spring.mail.username:}")
    private String mailUsername;

    private final JavaMailSender mailSender;

    /**
     * E-posta gönderimi asenkron olarak gerçekleştirilir
     *
     * @param to        Alıcı e-posta adresi
     * @param subject   E-posta konusu
     * @param content   E-posta içeriği (HTML formatında olabilir)
     */
    @Async
    public void sendEmail(String to, String subject, String content) {
        try {
            log.info("📧 E-posta gönderimi başlatılıyor: alıcı={}, konu={}", to, subject);
            
            MimeMessage message = mailSender.createMimeMessage();
            MimeMessageHelper helper = new MimeMessageHelper(message, true, "UTF-8");
            
            // Gönderen adresini açıkça belirt - ÖNEMLİ!
            helper.setFrom(mailUsername);
            log.debug("Gönderen adresi ayarlandı: {}", mailUsername);
            
            helper.setTo(to);
            helper.setSubject(subject);
            helper.setText(content, true); // true -> HTML içeriği olarak işaretler
            
            log.debug("Mail sunucusuna bağlanılıyor: {}:{}", mailHost, mailPort);
            log.debug("Kullanıcı adı: {}", mailUsername);
                     
            mailSender.send(message);
            log.info("✅ E-posta başarıyla gönderildi: {}", to);
        } catch (MessagingException e) {
            log.error("❌ E-posta gönderimi başarısız: {}", e.getMessage());
            log.error("❌ Hata sınıfı: {}", e.getClass().getName());
            log.error("❌ Stack trace:");
            for (StackTraceElement element : e.getStackTrace()) {
                log.error("   ⚠️ at {}", element);
            }
            // Eğer MailAuthenticationException ise özel loglama yap
            if (e.getMessage().contains("535 5.7.8") || 
                e.getMessage().contains("Authentication failed") || 
                e.getMessage().contains("authentication failed")) {
                log.error("🔐 GMAIL KİMLİK DOĞRULAMA HATASI: Gmail için ya uygulama şifresi yanlış ya da 2FA ayarlanmamış.");
                log.error("🔑 Gmail'de 'Uygulama Şifreleri' özelliğini etkinleştirmeniz ve buradan aldığınız şifreyi kullanmanız gerekiyor.");
            }
        } catch (Exception e) {
            log.error("⚠️ Beklenmeyen e-posta hatası: {}", e.getMessage());
            for (StackTraceElement element : e.getStackTrace()) {
                log.error("   ⚠️ at {}", element);
            }
        }
    }
    
    /**
     * Doğrulama kodu içeren e-posta gönderir
     *
     * @param to   Alıcı e-posta adresi
     * @param code Doğrulama kodu
     */
    public void sendVerificationCode(String to, String code) {
        String subject = "Toptan Street - E-posta Doğrulama Kodu";
        String content = "<div style=\"font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px; border: 1px solid #ddd; border-radius: 5px;\">"
                + "<h2 style=\"color: #1A237E; text-align: center;\">Toptan Street</h2>"
                + "<h3 style=\"text-align: center;\">E-posta Doğrulama Kodu</h3>"
                + "<p>Merhaba,</p>"
                + "<p>E-posta adresinizi doğrulamak için aşağıdaki kodu kullanın:</p>"
                + "<div style=\"text-align: center; margin: 30px 0;\">"
                + "<h1 style=\"font-size: 36px; letter-spacing: 5px; color: #1A237E; background-color: #f5f5f5; display: inline-block; padding: 10px 20px; border-radius: 5px;\">"
                + code
                + "</h1>"
                + "</div>"
                + "<p>Bu kod 5 dakika süreyle geçerlidir.</p>"
                + "<p>Eğer bu işlemi siz başlatmadıysanız, lütfen bu e-postayı dikkate almayın.</p>"
                + "<hr style=\"margin: 20px 0;\">"
                + "<p style=\"text-align: center; color: #666; font-size: 12px;\">© 2025 Toptan Street. Tüm hakları saklıdır.</p>"
                + "</div>";

        sendEmail(to, subject, content);
    }
}
