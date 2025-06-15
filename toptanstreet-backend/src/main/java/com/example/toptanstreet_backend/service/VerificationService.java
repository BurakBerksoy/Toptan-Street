package com.example.toptanstreet_backend.service;

import com.example.toptanstreet_backend.model.VerificationCode;
import com.example.toptanstreet_backend.repository.VerificationCodeRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Random;

@Service
@RequiredArgsConstructor
@Slf4j
public class VerificationService {
    
    private final VerificationCodeRepository verificationCodeRepository;
    private final EmailService emailService;
    
    @Value("${app.verification.code-length:6}")
    private int codeLength;
    
    @Value("${app.verification.expiration-minutes:5}")
    private int expirationMinutes;
    
    /**
     * Verilen e-posta için yeni bir doğrulama kodu oluşturur ve e-posta ile gönderir
     *
     * @param email Doğrulama kodu gönderilecek e-posta adresi
     * @return Oluşturulan doğrulama kodu
     */
    @Transactional
    public String createAndSendVerificationCode(String email) {
        try {
            log.info("📧 {} için doğrulama kodu oluşturuluyor...", email);
            
            // Önceki kodları temizle
            log.debug("Önceki doğrulama kodları temizleniyor");
            deleteExistingCodes(email);
            
            // Yeni kod oluştur
            String code = generateRandomCode();
            log.debug("Yeni kod oluşturuldu: {}...", code.substring(0, 2) + "****");
            
            // Verification Code nesnesini oluştur
            VerificationCode verificationCode = new VerificationCode();
            verificationCode.setEmail(email);
            verificationCode.setCode(code);
            verificationCode.setExpiresAt(LocalDateTime.now().plusMinutes(expirationMinutes));
            verificationCode.setVerified(false);
            
            try {
                log.debug("Doğrulama kodu veritabanına kaydediliyor...");
                VerificationCode saved = verificationCodeRepository.save(verificationCode);
                log.debug("Doğrulama kodu başarıyla kaydedildi, ID: {}", saved.getId());
            } catch (Exception e) {
                log.error("❌ HATA: Doğrulama kodu veritabanına kaydedilemedi: {}", e.getMessage());
                log.error("❌ Hata türü: {}", e.getClass().getName());
                for (StackTraceElement element : e.getStackTrace()) {
                    log.error("   ⚠️ at {}", element);
                }
                throw new RuntimeException("Doğrulama kodu oluşturulamadı: " + e.getMessage(), e);
            }
            
            // Kodu e-posta ile gönder veya mock et
            log.info("📤 Doğrulama kodu {} adresine gönderiliyor: {}", email, code.substring(0, 2) + "****");
            
            try {
                // E-posta göndermeyi dene
                emailService.sendVerificationCode(email, code);
            } catch (Exception e) {
                // Hata durumunda konsola yazdır (mock girişim)
                log.warn("⚠️ Mail sunucusu çalışmıyor veya kimlik doğrulama hatası - MOCK MODE: " + e.getMessage());
                System.out.println("\n\n----------------------------------------------------------------------------");
                System.out.println("| 📧 DOĞRULAMA KODU (MOCK): " + email + " için kod: " + code + " |");
                System.out.println("----------------------------------------------------------------------------\n");
                
                // Hata loglama
                log.error("Mail gönderimi başarısız, ancak işlem devam ediyor (mock): {}", e.getMessage());
            }
            
            log.info("✅ Doğrulama kodu başarıyla oluşturuldu ve gönderildi");
            return code;
            
        } catch (Exception e) {
            log.error("🔴 Doğrulama kodu oluşturma ve gönderme sırasında GENEL HATA: {}", e.getMessage());
            log.error("🔴 Hata sınıfı: {}", e.getClass().getName());
            log.error("🔴 Stack trace:");
            for (StackTraceElement element : e.getStackTrace()) {
                log.error("   ⚠️ at {}", element);
            }
            throw new RuntimeException("Doğrulama işlemi başarısız: " + e.getMessage(), e);
        }
    }
    
    /**
     * Verilen email için sistemde var olan tüm doğrulama kodlarını siler
     * 
     * @param email Doğrulama kodları silinecek email adresi
     */
    @Transactional
    public void deleteExistingCodes(String email) {
        try {
            List<VerificationCode> existingCodes = verificationCodeRepository.findAllByEmail(email);
            if (existingCodes != null && !existingCodes.isEmpty()) {
                log.debug("{} için {} adet eski doğrulama kodu siliniyor", email, existingCodes.size());
                verificationCodeRepository.deleteAll(existingCodes);
            } else {
                log.debug("{} için silinecek eski doğrulama kodu bulunamadı", email);
            }
        } catch (Exception e) {
            log.warn("Eski doğrulama kodları silinirken hata: {}", e.getMessage());
        }
    }
    
    /**
     * Doğrulama kodunu kontrol eder ve geçerliyse doğrular
     *
     * @param email Doğrulama yapılacak e-posta
     * @param code  Kontrol edilecek kod
     * @return Doğrulama başarılı ise true, değilse false
     */
    @Transactional
    public boolean verifyCode(String email, String code) {
        return verificationCodeRepository.findByEmailAndCode(email, code)
                .filter(VerificationCode::isValid)
                .map(verificationCode -> {
                    verificationCode.setVerified(true);
                    verificationCodeRepository.save(verificationCode);
                    return true;
                })
                .orElse(false);
    }
    
    /**
     * Verilen e-posta adresinin doğrulanıp doğrulanmadığını kontrol eder
     *
     * @param email Kontrol edilecek e-posta adresi
     * @return E-posta doğrulanmışsa true, değilse false
     */
    public boolean isEmailVerified(String email) {
        return verificationCodeRepository.findTopByEmailOrderByIdDesc(email)
                .map(VerificationCode::isVerified)
                .orElse(false);
    }
    
    /**
     * Rastgele doğrulama kodu oluşturur
     *
     * @return Belirtilen uzunlukta sayısal doğrulama kodu
     */
    private String generateRandomCode() {
        Random random = new Random();
        StringBuilder codeBuilder = new StringBuilder(codeLength);
        
        for (int i = 0; i < codeLength; i++) {
            codeBuilder.append(random.nextInt(10)); // 0-9 arası rakamlar
        }
        
        return codeBuilder.toString();
    }
}
