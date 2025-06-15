package com.example.toptanstreet_backend.service;

import com.example.toptanstreet_backend.dto.RegisterRequest;
import com.example.toptanstreet_backend.model.User;
import com.example.toptanstreet_backend.model.UserRole;
import com.example.toptanstreet_backend.repository.UserRepository;
import jakarta.annotation.PostConstruct;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
@Slf4j
public class UserService {
    
    @PostConstruct
    public void checkEncoderAndTestBCrypt() {
        System.out.println("\n🔍 UserService encoder instance: " + System.identityHashCode(passwordEncoder));
        System.out.println("🔍 UserService encoder class: " + passwordEncoder.getClass().getName());
        
        // BCrypt self-test
        String testPassword = "test123";
        String hashedPassword = passwordEncoder.encode(testPassword);
        boolean matches = passwordEncoder.matches(testPassword, hashedPassword);
        System.out.println("🔒 BCrypt self-test on UserService: " + (matches ? "BAŞARILI ✅" : "BAŞARISIZ ❌"));
        System.out.println("🔒 Generated hash: " + hashedPassword);
    }
    
    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final VerificationService verificationService;
    
    /**
     * İlk adım kayıt işlemi - doğrulama kodu gönderir
     * 
     * @param registerRequest Kayıt bilgileri
     * @return Doğrulama kodu gönderildiği bilgisi
     */
    public String initiateRegistration(RegisterRequest registerRequest) {
        // Email kullanımda mı kontrol et
        if (userRepository.existsByEmail(registerRequest.getEmail())) {
            // Kullanıcı zaten kayıtlı - doğrulama durumunu kontrol et
            boolean isVerified = verificationService.isEmailVerified(registerRequest.getEmail());
            if (isVerified) {
                // E-posta doğrulanmış, normale devam edilemez
                throw new RuntimeException("Bu email adresi sistemde zaten kayıtlı. Lütfen giriş yapmayı deneyin.");
            } else {
                // E-posta doğrulanmamış, yeni doğrulama kodu gönderilebilir
                // Önceki doğrulama kodunu sil ve yeni kod gönder
                return verificationService.createAndSendVerificationCode(registerRequest.getEmail());
            }
        }
        
        // Doğrulama kodu gönder (yeni kullanıcı)
        return verificationService.createAndSendVerificationCode(registerRequest.getEmail());
    }
    
    /**
     * E-posta doğrulandıktan sonra kullanıcı kaydını tamamlar
     * 
     * @param registerRequest Kayıt bilgileri
     * @return Kaydedilen kullanıcı
     */
    @Transactional
    public User registerUser(RegisterRequest registerRequest) {
        // Email kullanımda mı kontrol et
        if (userRepository.existsByEmail(registerRequest.getEmail())) {
            throw new RuntimeException("Email zaten kullanımda");
        }
        
        // Email doğrulanmış mı kontrol et
        if (!verificationService.isEmailVerified(registerRequest.getEmail())) {
            throw new RuntimeException("E-posta adresi doğrulanmamış");
        }
        
        log.info("🔐 Kullanıcı şifre hashlenme süreci başladı: {}", registerRequest.getEmail());
        
        // Şifre durum logu
        String rawPassword = registerRequest.getPassword();
        log.debug("🔐 RAW şifre: {}", rawPassword);
        System.out.println("🔐 RAW şifre: " + rawPassword);
        
        // Şifreyi hashle ve log'a yazdır
        String hashedPassword = passwordEncoder.encode(rawPassword);
        log.debug("🔐 HASHED şifre: {}", hashedPassword);
        System.out.println("🔐 HASHED şifre: " + hashedPassword);
        log.info("🔐 Hash kontrolü: BCrypt formatında mı? {}", hashedPassword.startsWith("$2a$"));
        log.info("🔐 Hash uzunluğu: {} karakter", hashedPassword.length());
        
        // Yeni kullanıcı oluştur
        User newUser = new User();
        newUser.setFirstName(registerRequest.getFirstName());
        newUser.setLastName(registerRequest.getLastName());
        newUser.setEmail(registerRequest.getEmail());
        newUser.setPassword(hashedPassword); // Hashlenmiş şifreyi kaydet
        newUser.setRole(registerRequest.getRole());
        
        // Toptancı ise, ödeme durumunu false olarak ayarla (ödeme bekliyor)
        if (registerRequest.getRole() == UserRole.WHOLESALER) {
            newUser.setPaymentStatus(false);
        } else {
            // Perakendeciler için ödeme gerekmez
            newUser.setPaymentStatus(true);
        }
        
        // Kullanıcıyı kaydet
        User savedUser = userRepository.save(newUser);
        
        // Kaydedilen kullanıcının şifre hash'ini kontrol et
        log.info("🔐 Kullanıcı kaydedildi. DB'ye yazılan şifre hash'i: {}", savedUser.getPassword().substring(0, 10) + "...");
        
        return savedUser;
    }
    
    public User findUserByEmail(String email) {
        return userRepository.findByEmail(email)
                .orElseThrow(() -> new RuntimeException("Kullanıcı bulunamadı: " + email));
    }
}
