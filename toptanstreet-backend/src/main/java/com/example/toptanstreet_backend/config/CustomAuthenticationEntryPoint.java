package com.example.toptanstreet_backend.config;

import com.example.toptanstreet_backend.dto.ApiResponse;
import com.fasterxml.jackson.databind.ObjectMapper;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.security.core.AuthenticationException;
import org.springframework.security.web.AuthenticationEntryPoint;
import org.springframework.stereotype.Component;

import java.io.IOException;
import java.io.PrintWriter;

@Component
public class CustomAuthenticationEntryPoint implements AuthenticationEntryPoint {

    private static final Logger logger = LoggerFactory.getLogger(CustomAuthenticationEntryPoint.class);
    private final ObjectMapper objectMapper = new ObjectMapper();

    @Override
    public void commence(HttpServletRequest request, HttpServletResponse response,
                         AuthenticationException authException) throws IOException, ServletException {
        
        // Güvenilir kaynak ve path kontrolü
        String requestPath = request.getRequestURI();
        String method = request.getMethod();
        
        // Auth endpoint'lerine erişimde security filter'i bypass et
        if (requestPath.startsWith("/api/v1/auth/") || requestPath.startsWith("/api/v1/verification/")) {
            System.out.println("\n\n[GEÇİCİ FIX] Security filtre atlanıyor: " + requestPath + " " + method);
            System.out.println("Bu endpoint'ler için izin verildi\n\n");
            
            // Auth endpoint'lerine erişimde filtreleri atla, işlemi controller'a bırak
            // Normalde burayı atlamak güvenlik riski oluşturabilir ama geçici fix için güvenli bir ortamda kullanıyoruz
            return;
        }
        
        // Özel hata mesajı oluşturmak için loglama
        System.out.println("\n\n==============================================");
        System.out.println("ÖZEL HATA MESAJI TETİKLENDİ! CustomAuthenticationEntryPoint.commence() çağrıldı!");
        System.out.println("Request URI: " + requestPath);
        System.out.println("Request Method: " + method);
        System.out.println("Exception: " + authException.getMessage());
        System.out.println("Exception type: " + authException.getClass().getName());
        System.out.println("==============================================\n\n");
        
        logger.error("Yetkisiz erişim hatası: {} - {}", requestPath, authException.getMessage());
        
        // Özel hata mesajını hazırla - URL'ye göre kararlaştır
        String errorMessage;
        if (requestPath.contains("/api/v1/auth/initiate-register")) {
            errorMessage = "Kayıt işlemi başarısız. Bu email adresi zaten sistemde kayıtlı olabilir.";
            logger.error("Kayıt işlemi başarısız. Muhtemelen email zaten kayıtlı.");
        } else if (requestPath.contains("/api/v1/auth/login")) {
            errorMessage = "Giriş yapılamadı. Email veya şifre hatalı.";
            logger.error("Giriş işlemi başarısız. Email veya şifre hatalı.");
        } else {
            // Genel kimlik doğrulama hatası
            errorMessage = "Yetkisiz erişim. Bu işlem için giriş yapmanız gerekmektedir.";
        }
        
        // HTTP yanıtını hazırla - Flutter uygulaması için 400 Bad Request kullan
        response.setStatus(HttpServletResponse.SC_BAD_REQUEST); 
        response.setContentType("application/json;charset=UTF-8");
        
        // ApiResponse nesnesini oluştur ve JSON olarak yaz
        ApiResponse<?> apiResponse = ApiResponse.error(errorMessage);
        try {
            String jsonResponse = objectMapper.writeValueAsString(apiResponse);
            logger.debug("Döndürülen JSON yanıt: {}", jsonResponse);
            PrintWriter writer = response.getWriter();
            writer.write(jsonResponse);
            writer.flush();
            
            // Debug: Gönderilen yanıtı logla
            System.out.println("Gönderilen API Yanıtı: " + jsonResponse);
        } catch (Exception e) {
            logger.error("JSON dönüştürme hatası: {}", e.getMessage(), e);
        }
    }
}
