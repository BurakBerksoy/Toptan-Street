package com.example.toptanstreet_backend.controller;

import com.example.toptanstreet_backend.dto.ApiResponse;
import com.example.toptanstreet_backend.dto.LoginRequest;
import com.example.toptanstreet_backend.dto.RegisterRequest;

import com.example.toptanstreet_backend.model.User;
import com.example.toptanstreet_backend.service.AuthService;
import com.example.toptanstreet_backend.service.UserService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.Map;

@RestController
@RequestMapping("/api/v1/auth")
@CrossOrigin(origins = "*") // Flutter uygulamasından erişim için
public class AuthController {

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
        try {
            // Kayıt işlemini başlat
            userService.initiateRegistration(request);
            
            Map<String, Object> response = new HashMap<>();
            response.put("email", request.getEmail());
            response.put("message", "Doğrulama kodu e-posta adresinize gönderildi.");
            
            return ResponseEntity.ok(ApiResponse.success("Doğrulama kodu gönderildi", response));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(ApiResponse.error(e.getMessage()));
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
