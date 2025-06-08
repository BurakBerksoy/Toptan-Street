package com.example.toptanstreet_backend.service;

import com.example.toptanstreet_backend.dto.RegisterRequest;
import com.example.toptanstreet_backend.model.User;
import com.example.toptanstreet_backend.model.UserRole;
import com.example.toptanstreet_backend.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
public class UserService {
    
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
            throw new RuntimeException("Email zaten kullanımda");
        }
        
        // Doğrulama kodu gönder
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
        
        // Yeni kullanıcı oluştur
        User newUser = new User();
        newUser.setFirstName(registerRequest.getFirstName());
        newUser.setLastName(registerRequest.getLastName());
        newUser.setEmail(registerRequest.getEmail());
        newUser.setPassword(passwordEncoder.encode(registerRequest.getPassword()));
        newUser.setRole(registerRequest.getRole());
        
        // Toptancı ise, ödeme durumunu false olarak ayarla (ödeme bekliyor)
        if (registerRequest.getRole() == UserRole.WHOLESALER) {
            newUser.setPaymentStatus(false);
        } else {
            // Perakendeciler için ödeme gerekmez
            newUser.setPaymentStatus(true);
        }
        
        // Kullanıcıyı kaydet ve döndür
        return userRepository.save(newUser);
    }
    
    public User findUserByEmail(String email) {
        return userRepository.findByEmail(email)
                .orElseThrow(() -> new RuntimeException("Kullanıcı bulunamadı: " + email));
    }
}
