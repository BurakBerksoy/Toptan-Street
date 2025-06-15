package com.example.toptanstreet_backend.repository;

import com.example.toptanstreet_backend.model.VerificationCode;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface VerificationCodeRepository extends JpaRepository<VerificationCode, Long> {
    
    /**
     * E-posta ve kod ile doğrulama kodu arar
     * 
     * @param email Kullanıcı e-posta adresi
     * @param code Doğrulama kodu
     * @return İlgili doğrulama kodu, yoksa boş Optional
     */
    Optional<VerificationCode> findByEmailAndCode(String email, String code);
    
    /**
     * Belirli bir email adresine ait tüm doğrulama kodlarını bulur
     * 
     * @param email Kullanıcı e-posta adresi
     * @return Eşleşen doğrulama kodları listesi
     */
    List<VerificationCode> findAllByEmail(String email);
    
    /**
     * E-posta ile en son oluşturulan doğrulama kodu
     * 
     * @param email Kullanıcı e-posta adresi
     * @return En son oluşturulan doğrulama kodu, yoksa boş Optional
     */
    Optional<VerificationCode> findTopByEmailOrderByIdDesc(String email);
}
