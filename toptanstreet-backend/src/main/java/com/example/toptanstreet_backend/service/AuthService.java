package com.example.toptanstreet_backend.service;

import com.example.toptanstreet_backend.dto.LoginRequest;
import com.example.toptanstreet_backend.model.User;
import com.example.toptanstreet_backend.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

import java.util.HashMap;
import java.util.Map;

@Service
@RequiredArgsConstructor
public class AuthService {
    
    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    
    public Map<String, Object> login(LoginRequest loginRequest) {
        // Kullanıcıyı e-posta ile ara
        User user = userRepository.findByEmail(loginRequest.getEmail())
                .orElseThrow(() -> new RuntimeException("Geçersiz kullanıcı adı veya şifre"));
        
        // Şifre kontrolü
        if (!passwordEncoder.matches(loginRequest.getPassword(), user.getPassword())) {
            throw new RuntimeException("Geçersiz kullanıcı adı veya şifre");
        }
        
        // Eğer toptancı ise ve ödeme yapılmadıysa uyarı
        if (user.getRole().name().equals("WHOLESALER") && !user.getPaymentStatus()) {
            throw new RuntimeException("Toptancı hesabınız için ödeme yapmanız gerekmektedir");
        }
        
        // Token ve kullanıcı bilgilerini içeren yanıt oluştur
        Map<String, Object> responseMap = new HashMap<>();
        responseMap.put("user", user);
        responseMap.put("token", "simulated-jwt-token-" + user.getId()); // Gerçek projede JWT token oluşturulacak
        
        return responseMap;
    }
}
