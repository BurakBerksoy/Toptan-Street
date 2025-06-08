package com.example.toptanstreet_backend.model;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import jakarta.persistence.*;
import java.time.LocalDateTime;

@Entity
@Data
@AllArgsConstructor
@NoArgsConstructor
@Table(name = "verification_codes", schema = "toptanstreet")
public class VerificationCode {
    
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    
    @Column(nullable = false)
    private String email;
    
    @Column(nullable = false, length = 6)
    private String code;
    
    @Column(nullable = false)
    private LocalDateTime expiresAt;
    
    @Column(nullable = false)
    private boolean verified;
    
    /**
     * Kodun geçerliliğini kontrol eder
     */
    public boolean isValid() {
        return !verified && LocalDateTime.now().isBefore(expiresAt);
    }
    
    /**
     * Kodun geçerlilik süresinin dolup dolmadığını kontrol eder
     */
    public boolean isExpired() {
        return LocalDateTime.now().isAfter(expiresAt);
    }
}
