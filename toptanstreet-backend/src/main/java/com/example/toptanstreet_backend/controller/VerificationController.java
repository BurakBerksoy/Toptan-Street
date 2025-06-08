package com.example.toptanstreet_backend.controller;

import com.example.toptanstreet_backend.dto.ApiResponse;
import com.example.toptanstreet_backend.dto.SendVerificationRequest;
import com.example.toptanstreet_backend.dto.VerifyCodeRequest;
import com.example.toptanstreet_backend.service.VerificationService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/v1/verification")
@RequiredArgsConstructor
@CrossOrigin(origins = "*")
public class VerificationController {

    private final VerificationService verificationService;

    /**
     * Doğrulama kodu gönderme endpoint'i
     * 
     * @param request E-posta bilgisini içeren istek
     * @return İşlem sonucu
     */
    @PostMapping("/send")
    public ResponseEntity<ApiResponse<Void>> sendVerificationCode(@RequestBody SendVerificationRequest request) {
        try {
            verificationService.createAndSendVerificationCode(request.getEmail());
            return ResponseEntity.ok(ApiResponse.success("Doğrulama kodu e-posta adresinize gönderildi", null));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(ApiResponse.error("Doğrulama kodu gönderilemedi: " + e.getMessage()));
        }
    }

    /**
     * Doğrulama kodu kontrol endpoint'i
     * 
     * @param request E-posta ve doğrulama kodunu içeren istek
     * @return İşlem sonucu
     */
    @PostMapping("/verify")
    public ResponseEntity<ApiResponse<Boolean>> verifyCode(@RequestBody VerifyCodeRequest request) {
        boolean isVerified = verificationService.verifyCode(request.getEmail(), request.getCode());
        
        if (isVerified) {
            return ResponseEntity.ok(ApiResponse.success("E-posta doğrulama başarılı", true));
        } else {
            return ResponseEntity.badRequest().body(ApiResponse.error("Geçersiz veya süresi dolmuş doğrulama kodu"));
        }
    }

    /**
     * E-posta doğrulama durumu kontrolü endpoint'i
     * 
     * @param email Kontrol edilecek e-posta adresi
     * @return Doğrulama durumu
     */
    @GetMapping("/status")
    public ResponseEntity<ApiResponse<Boolean>> checkVerificationStatus(@RequestParam String email) {
        boolean isVerified = verificationService.isEmailVerified(email);
        return ResponseEntity.ok(ApiResponse.success(isVerified));
    }
}
