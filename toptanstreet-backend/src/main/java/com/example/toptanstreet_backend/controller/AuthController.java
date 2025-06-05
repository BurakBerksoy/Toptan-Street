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
