package com.example.toptanstreet_backend.controller;

import com.example.toptanstreet_backend.model.User;
import com.example.toptanstreet_backend.repository.UserRepository;
import com.example.toptanstreet_backend.service.EmailService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.Map;
import java.util.Optional;

@RestController
@RequestMapping("/api/v1/test")
@RequiredArgsConstructor
@Slf4j
public class TestController {
    
    private final EmailService emailService;
    private final PasswordEncoder passwordEncoder;
    private final UserRepository userRepository;
    
    @PostMapping("/send-email")
    public ResponseEntity<Map<String, String>> sendTestEmail(@RequestParam String to) {
        log.info("📧 Test e-postası gönderiliyor: {}", to);
        
        try {
            emailService.sendEmail(
                to,
                "Toptan Street - Test E-postası",
                "<h1>Bu bir test e-postasıdır</h1><p>E-posta sistemi çalışıyor!</p>"
            );
            
            Map<String, String> response = new HashMap<>();
            response.put("status", "success");
            response.put("message", "Test e-postası gönderim isteği alındı. Logs klasörünü kontrol edin ve e-posta gelen kutunuzu kontrol edin.");
            
            log.info("✅ Test e-postası gönderildi: {}", to);
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            Map<String, String> response = new HashMap<>();
            response.put("status", "error");
            response.put("message", "E-posta gönderilirken bir hata oluştu: " + e.getMessage());
            
            log.error("❌ Test e-postası gönderiminde hata: {}", e.getMessage());
            return ResponseEntity.badRequest().body(response);
        }
    }
    
    /**
     * Şifre doğrulama testi için endpoint
     * Örneğin: /api/v1/test/password?email=test@example.com&password=123456
     */
    @GetMapping("/password")
    public ResponseEntity<Map<String, Object>> testPasswordEncoder(
            @RequestParam String email,
            @RequestParam String password) {
        
        log.info("🔐 Şifre doğrulama testi başlatıldı: {} için", email);
        Map<String, Object> result = new HashMap<>();
        
        // 1. Şifrenin hash'lenmiş hali
        String rawPassword = password;
        String hashedPassword = passwordEncoder.encode(rawPassword);
        result.put("raw_password", rawPassword);
        result.put("hashed_password", hashedPassword);
        result.put("hash_length", hashedPassword.length());
        result.put("hash_starts_with", hashedPassword.substring(0, 7));
        
        // 2. Veritabanında kullanıcı ara
        Optional<User> userOpt = userRepository.findByEmail(email);
        if (userOpt.isPresent()) {
            User user = userOpt.get();
            String dbPasswordHash = user.getPassword();
            boolean passwordMatches = passwordEncoder.matches(rawPassword, dbPasswordHash);
            
            // 3. Veritabanındaki hash ile karşılaştırma bilgilerini ekle
            result.put("user_exists", true);
            result.put("db_password_hash", dbPasswordHash);
            result.put("db_hash_format_valid", dbPasswordHash != null && dbPasswordHash.startsWith("$2a$"));
            result.put("passwords_match", passwordMatches);
            
            log.info("DB'deki hash: {}, Girilen şifre: {}, Eşleşme: {}", 
                    dbPasswordHash.substring(0, 10) + "...", rawPassword, passwordMatches);
        } else {
            result.put("user_exists", false);
            log.warn("Kullanıcı bulunamadı: {}", email);
        }
        
        // 4. Genel kontroller
        result.put("encoder_class", passwordEncoder.getClass().getName());
        result.put("hash_verification_test", passwordEncoder.matches(rawPassword, hashedPassword));
        
        return ResponseEntity.ok(result);
    }
    
    @GetMapping("/mail-config")
    public ResponseEntity<Map<String, String>> getMailConfig() {
        Map<String, String> config = new HashMap<>();
        config.put("host", System.getProperty("spring.mail.host", "Ayarlanmamış"));
        config.put("port", System.getProperty("spring.mail.port", "Ayarlanmamış"));
        config.put("username", System.getProperty("spring.mail.username", "Ayarlanmamış"));
        config.put("auth", System.getProperty("spring.mail.properties.mail.smtp.auth", "Ayarlanmamış"));
        config.put("starttls", System.getProperty("spring.mail.properties.mail.smtp.starttls.enable", "Ayarlanmamış"));
        
        log.info("📋 Mail konfigürasyonu görüntülendi");
        return ResponseEntity.ok(config);
    }
}
