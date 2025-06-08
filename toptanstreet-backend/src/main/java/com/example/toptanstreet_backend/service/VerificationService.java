package com.example.toptanstreet_backend.service;

import com.example.toptanstreet_backend.model.VerificationCode;
import com.example.toptanstreet_backend.repository.VerificationCodeRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.Random;

@Service
@RequiredArgsConstructor
public class VerificationService {
    
    private final VerificationCodeRepository verificationCodeRepository;
    private final EmailService emailService;
    
    @Value("${app.verification.code-length}")
    private int codeLength;
    
    @Value("${app.verification.expiration-minutes}")
    private int expirationMinutes;
    
    /**
     * Verilen e-posta için yeni bir doğrulama kodu oluşturur ve e-posta ile gönderir
     *
     * @param email Doğrulama kodu gönderilecek e-posta adresi
     * @return Oluşturulan doğrulama kodu
     */
    @Transactional
    public String createAndSendVerificationCode(String email) {
        // Yeni kod oluştur
        String code = generateRandomCode();
        
        // Geçerlilik süresini belirle
        LocalDateTime expiresAt = LocalDateTime.now().plusMinutes(expirationMinutes);
        
        // Varolan eski kodları bul
        verificationCodeRepository.findTopByEmailOrderByIdDesc(email)
                .ifPresent(verificationCodeRepository::delete);
        
        // Yeni kod oluştur ve kaydet
        VerificationCode verificationCode = new VerificationCode();
        verificationCode.setEmail(email);
        verificationCode.setCode(code);
        verificationCode.setExpiresAt(expiresAt);
        verificationCode.setVerified(false);
        
        verificationCodeRepository.save(verificationCode);
        
        // E-posta ile kodu gönder
        emailService.sendVerificationCode(email, code);
        
        return code;
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
