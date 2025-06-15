package com.example.toptanstreet_backend.service;

import com.example.toptanstreet_backend.dto.LoginRequest;
import com.example.toptanstreet_backend.model.User;
import com.example.toptanstreet_backend.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

import jakarta.annotation.PostConstruct;
import java.util.HashMap;
import java.util.Map;

@Service
@RequiredArgsConstructor
@Slf4j
public class AuthService {
    
    @PostConstruct
    public void checkEncoderAndTestBCrypt() {
        System.out.println("\n🔍 AuthService encoder instance: " + System.identityHashCode(passwordEncoder));
        System.out.println("🔍 AuthService encoder class: " + passwordEncoder.getClass().getName());
        
        // BCrypt self-test
        String testPassword = "test123";
        String hashedPassword = passwordEncoder.encode(testPassword);
        boolean matches = passwordEncoder.matches(testPassword, hashedPassword);
        System.out.println("🔒 BCrypt self-test on AuthService: " + (matches ? "BAŞARILI ✅" : "BAŞARISIZ ❌"));
        System.out.println("🔒 Generated hash: " + hashedPassword);
    }
    
    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    
    public Map<String, Object> login(LoginRequest loginRequest) {
        log.info("🔑 Giriş denemesi: {}", loginRequest.getEmail());
        System.out.println("\n\n🔑 🔑 🔑 GİRİŞ DENEMESİ: " + loginRequest.getEmail() + " 🔑 🔑 🔑\n");
        
        try {
            // Kullanıcıyı e-posta ile ara
            log.debug("Veritabanında kullanıcı aranıyor: {}", loginRequest.getEmail());
            User user = userRepository.findByEmail(loginRequest.getEmail())
                    .orElseThrow(() -> {
                        String errorMsg = "Geçersiz kullanıcı adı veya şifre (kullanıcı bulunamadı)";
                        log.warn("⚠️ Giriş başarısız: {} kullanıcısı bulunamadı", loginRequest.getEmail());
                        System.out.println("❌ HATA: " + errorMsg);
                        return new RuntimeException(errorMsg);
                    });
            
            // Kullanıcı bilgileri logu
            System.out.println("✅ Kullanıcı bulundu: ID=" + user.getId() + ", Email=" + user.getEmail() + ", Role=" + user.getRole());
            
            // Şifre kontrolü - DETAYLI LOGLAMA
            log.debug("🔐 Şifre doğrulama işlemi başlatıldı");
            System.out.println("🔐 ŞİFRE DOĞRULAMA İŞLEMİ BAŞLATILDI");
            
            String rawPassword = loginRequest.getPassword();
            String hashedPassword = user.getPassword();
            
            // Şifre logu
            System.out.println("🔐 Girişte kullanıcının girdiği şifre: " + rawPassword);
            System.out.println("🔐 Veritabanındaki hash: " + hashedPassword);
            
            // Şifre null veya boş mu kontrolü
            if (rawPassword == null || rawPassword.isEmpty()) {
                String errorMsg = "Geçersiz kullanıcı adı veya şifre (şifre boş)";
                log.warn("❌ Giriş başarısız: Şifre boş");
                System.out.println("❌ HATA: " + errorMsg);
                throw new RuntimeException(errorMsg);
            }
            
            // Hash formatı kontrolü
            if (hashedPassword == null || !hashedPassword.startsWith("$2a$")) {
                String displayHash = hashedPassword != null ? hashedPassword.substring(0, Math.min(hashedPassword.length(), 10)) + "..." : "null";
                String errorMsg = "Veritabanında şifre formatı hatalı: " + displayHash;
                log.error("❌ Hash formatı geçersiz: {}", displayHash);
                System.out.println("❌ HATA: " + errorMsg);
                throw new RuntimeException(errorMsg);
            }
            
            // Şifre encoder'in sınıfını logla
            System.out.println("🔐 Kullanılan PasswordEncoder sınıfı: " + passwordEncoder.getClass().getName());
            
            // BCrypt matches metoduyla karşılaştırma
            boolean matches = passwordEncoder.matches(rawPassword, hashedPassword);
            
            // Karşılaştırma sonucu
            System.out.println("🔐 Karşılaştırma sonucu: " + matches);
            
            if (!matches) {
                String errorMsg = "Geçersiz kullanıcı adı veya şifre (hash eşleşmedi)";
                log.warn("❌ Şifre eşleşmedi: {} için", loginRequest.getEmail());
                System.out.println("❌ HATA: " + errorMsg);
                throw new RuntimeException(errorMsg);
            }
            
            log.debug("✅ Şifre doğrulaması başarılı: {}", loginRequest.getEmail());
            System.out.println("✅ ŞİFRE DOĞRULAMASI BAŞARILI!");
            
            // Eğer toptancı ise ve ödeme yapılmadıysa uyarı
            if (user.getRole().name().equals("WHOLESALER") && !user.getPaymentStatus()) {
                log.warn("⚠️ Toptancı ödemesi yapılmamış: {}", loginRequest.getEmail());
                throw new RuntimeException("Toptancı hesabınız için ödeme yapmanız gerekmektedir");
            }
            
            // Token ve kullanıcı bilgilerini içeren yanıt oluştur
            Map<String, Object> responseMap = new HashMap<>();
            responseMap.put("user", user);
            responseMap.put("token", "simulated-jwt-token-" + user.getId()); // Gerçek projede JWT token oluşturulacak
            
            log.info("✅ Giriş başarılı: {} (ID: {})", loginRequest.getEmail(), user.getId());
            return responseMap;
            
        } catch (Exception e) {
            log.error("🔴 Giriş sırasında hata: {} - {}", e.getClass().getSimpleName(), e.getMessage());
            throw e;
        }
    }
}
