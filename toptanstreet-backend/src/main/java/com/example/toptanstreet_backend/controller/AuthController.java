package com.example.toptanstreet_backend.controller;

import com.example.toptanstreet_backend.dto.ApiResponse;
import com.example.toptanstreet_backend.dto.LoginRequest;
import com.example.toptanstreet_backend.dto.RegisterRequest;

import com.example.toptanstreet_backend.model.User;
import com.example.toptanstreet_backend.service.AuthService;
import com.example.toptanstreet_backend.service.UserService;
import lombok.RequiredArgsConstructor;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.Map;

@RestController
@RequestMapping("/api/v1/auth")
@CrossOrigin(origins = "*") // Flutter uygulamasından erişim için
public class AuthController {
    
    private static final Logger logger = LoggerFactory.getLogger(AuthController.class);

    private final UserService userService;
    private final AuthService authService;
    
    public AuthController(UserService userService, AuthService authService) {
        this.userService = userService;
        this.authService = authService;
    }
    
    /**
     * Kayıt işlemini başlatır ve doğrulama kodu gönderir
     *
     * @param request Kayıt bilgileri
     * @return Doğrulama kodu gönderildi bilgisi
     */
    @PostMapping("/initiate-register")
    public ResponseEntity<ApiResponse<Map<String, Object>>> initiateRegistration(@RequestBody RegisterRequest request) {
        logger.info("initiateRegistration endpoint called for email: {}", request.getEmail());
        logger.debug("RegisterRequest details: firstName={}, lastName={}, email={}, role={}", 
                request.getFirstName(), request.getLastName(), request.getEmail(), request.getRole());
        
        String errorMessage = null;
        try {
            // Gelen isteği validate et
            logger.debug("Validating registration request...");
            if (request.getEmail() == null || request.getEmail().isBlank()) {
                errorMessage = "Email boş olamaz";
                logger.warn("Registration failed: {}", errorMessage);
                return ResponseEntity.badRequest().body(ApiResponse.error(errorMessage));
            }
            
            if (request.getPassword() == null || request.getPassword().isBlank()) {
                errorMessage = "Parola boş olamaz";
                logger.warn("Registration failed: {}", errorMessage);
                return ResponseEntity.badRequest().body(ApiResponse.error(errorMessage));
            }
            
            try {
                // Kayıt işlemini başlat - DETAYLI HATA AYIKLAMA
                logger.debug("Initiating registration process... ⏳ Lütfen bekleyin...");
                userService.initiateRegistration(request);
                
                // BAŞARILI KAYIT
                Map<String, Object> response = new HashMap<>();
                response.put("email", request.getEmail());
                response.put("message", "Doğrulama kodu e-posta adresinize gönderildi.");
                
                logger.info("✅ Registration initiated successfully for: {}", request.getEmail());
                return ResponseEntity.ok(ApiResponse.success("Doğrulama kodu gönderildi", response));
                
            } catch (RuntimeException ex) {
                // UserService'den gelen RuntimeException'ları yakala ve detaylı logla
                errorMessage = ex.getMessage();
                
                logger.error("🔴 HATA YAKALANDI (RuntimeException): {}", errorMessage);
                logger.error("🔴 Hata sınıfı: {}", ex.getClass().getName());
                logger.error("🔴 Stack trace:");
                for (StackTraceElement element : ex.getStackTrace()) {
                    logger.error("   ⚠️ at {}", element);
                }
                
                // Kullanıcı dostu hata mesajı oluştur
                if (errorMessage != null && errorMessage.contains("Email zaten kullanımda")) {
                    errorMessage = "Bu email adresi sistemde zaten kayıtlı. Lütfen giriş yapmayı deneyin.";
                } else if (errorMessage == null || errorMessage.isEmpty() || errorMessage.equals("Authentication failed")) {
                    // "Authentication failed" özel bir durum - detaylı bilgi ekliyoruz
                    errorMessage = "Kayıt işlemi sırasında bir hata oluştu. Lütfen bilgilerinizi kontrol edip tekrar deneyin.";
                    logger.error("🔴 'Authentication failed' hatası - bu bir Spring Security hatası olabilir");
                }
                
                // İstemciye hata yanıtı gönder
                ApiResponse<Map<String, Object>> errorResponse = new ApiResponse<>(false, errorMessage, null);
                return ResponseEntity.badRequest().body(errorResponse);
            }
        } catch (Exception e) {
            // GENEL HATA - Tüm diğer exception'ları yakala ve detaylı logla
            errorMessage = "Kayıt sırasında beklenmeyen bir hata oluştu: " + e.getMessage();
            
            logger.error("❌ GENİŞ HATA YAKALANDI (Exception): {}", e.getMessage());
            logger.error("❌ Hata sınıfı: {}", e.getClass().getName());
            logger.error("❌ Stack trace:");
            for (StackTraceElement element : e.getStackTrace()) {
                logger.error("   ⚠️ at {}", element);
            }
            
            logger.error("Registration failed with unexpected error: {}", errorMessage);
            
            // Gerçek hata mesajını döndür
            ApiResponse<Map<String, Object>> errorResponse = new ApiResponse<>(false, errorMessage, null);
            return ResponseEntity.badRequest().body(errorResponse);
        }
    }
    
    /**
     * E-posta doğrulandıktan sonra kayıt işlemini tamamlar
     *
     * @param request Kayıt bilgileri
     * @return Kayıt işlemi sonucu
     */
    @PostMapping("/register")
    public ResponseEntity<ApiResponse<User>> register(@RequestBody RegisterRequest request) {
        try {
            User registeredUser = userService.registerUser(request);
            return ResponseEntity.ok(ApiResponse.success("Kayıt başarılı", registeredUser));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(ApiResponse.error(e.getMessage()));
        }
    }
    
    @PostMapping("/login")
    public ResponseEntity<ApiResponse<?>> login(@RequestBody LoginRequest request) {
        try {
            var loginResult = authService.login(request);
            return ResponseEntity.ok(ApiResponse.success("Giriş başarılı", loginResult));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(ApiResponse.error(e.getMessage()));
        }
    }
}
