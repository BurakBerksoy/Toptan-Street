package com.example.toptanstreet_backend.config;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.Primary;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.web.cors.CorsConfiguration;
import org.springframework.web.cors.CorsConfigurationSource;
import org.springframework.web.cors.UrlBasedCorsConfigurationSource;

import java.util.Arrays;
import java.util.List;

@Configuration
@EnableWebSecurity
public class SecurityConfig {

    private final CustomAuthenticationEntryPoint authenticationEntryPoint;
    
    // Constructor injection - @Autowired yerine (daha güvenli)
    public SecurityConfig(CustomAuthenticationEntryPoint authenticationEntryPoint) {
        this.authenticationEntryPoint = authenticationEntryPoint;
        System.out.println("SecurityConfig yüklendi! CustomAuthenticationEntryPoint: " + 
            (authenticationEntryPoint != null ? "başarıyla inject edildi" : "NULL - HATA!"));
    }
    
    @Bean
    public SecurityFilterChain securityFilterChain(HttpSecurity http) throws Exception {
        // Tüm auth ve verification endpointlerini açıkça logla
        System.out.println("\n\nÖNEMLİ GÜVENLİK AYARLARI:\n" + 
                          "Tüm /api/v1/auth/* ve /api/v1/verification/* endpoint'leri permitAll() ile açılıyor.\n" +
                          "Özellikle /api/v1/auth/initiate-register açık erişimli\n\n");
        
        http
            // CORS konfigürasyonu - Flutter ile backend arasındaki cross-origin istekleri için
            .cors(cors -> cors.configurationSource(corsConfigurationSource()))
            // CSRF korumasını kesinlikle devre dışı bırak
            .csrf(csrf -> csrf.disable())
            // HTTP isteklerinin kimlik doğrulama gereksinimleri
            .authorizeHttpRequests(auth -> {
                // Auth ve verification endpointlerini tek tek açıkça permitAll yap
                auth.requestMatchers("/api/v1/auth/initiate-register").permitAll();
                auth.requestMatchers("/api/v1/auth/login").permitAll();
                auth.requestMatchers("/api/v1/auth/register").permitAll();
                auth.requestMatchers("/api/v1/verification/**").permitAll();
                
                // Genel olarak tüm auth endpoint'leri
                auth.requestMatchers("/api/v1/auth/**").permitAll();
                
                // Diğer tüm istekler kimlik doğrulama gerektirir
                auth.anyRequest().authenticated();
            })
            // Özel kimlik doğrulama hata işleyicisi
            .exceptionHandling(ex -> ex
                .authenticationEntryPoint(authenticationEntryPoint)
            )
            // Oturum yönetimi - durumsuz RESTful servisler için
            .sessionManagement(sess -> sess
                .sessionCreationPolicy(SessionCreationPolicy.STATELESS)
            );
        
        System.out.println("Security konfigürasyonu yüklendi! AuthenticationEntryPoint: " + 
            (authenticationEntryPoint != null ? "aktif" : "NULL - DİKKAT!"));
            
        return http.build();
    }
    
    /**
     * CORS konfigürasyonu - Flutter uygulamalarının backend ile haberleşmesini sağlar
     * Geliştirme ortamında tüm isteklere izin veriyoruz (*)
     * Canlı ortamda (production) belirli domainlere sınırlanmalıdır
     */
    @Bean
    public CorsConfigurationSource corsConfigurationSource() {
        CorsConfiguration configuration = new CorsConfiguration();
        configuration.setAllowedOrigins(Arrays.asList("*"));  // Tüm kaynaklara izin ver (geliştirme için)
        configuration.setAllowedMethods(Arrays.asList("GET", "POST", "PUT", "DELETE", "OPTIONS"));
        configuration.setAllowedHeaders(Arrays.asList("*"));
        configuration.setAllowCredentials(false); // '*' ile kullanırken false olmalı
        configuration.setMaxAge(3600L); // Ön uçuş istekleri için önbellek süresi (saniye)
        
        UrlBasedCorsConfigurationSource source = new UrlBasedCorsConfigurationSource();
        source.registerCorsConfiguration("/**", configuration);
        System.out.println("CORS konfigürasyonu aktifleştirildi - Tüm isteklere izin veriliyor");
        return source;
    }
    
    @Bean
    @Primary
    public PasswordEncoder passwordEncoder() {
        return new BCryptPasswordEncoder();
    }
}
