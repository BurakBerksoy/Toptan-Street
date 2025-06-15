import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // Backend sunucu URL'si - Geliştirme ortamı için localhost
  static const String baseUrl = 'http://10.0.2.2:8080/api/v1'; // Android Emulator için 
  // static const String baseUrl = 'http://localhost:8080/api/v1'; // Web için

  // Kullanıcı Kayıt API'si
  static Future<Map<String, dynamic>> register({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required String role, // WHOLESALER veya RETAILER
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'firstName': firstName,
          'lastName': lastName,
          'email': email,
          'password': password,
          'role': role,
        }),
      );

      final responseData = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': responseData['message'] ?? 'Kayıt başarılı',
          'data': responseData['data'],
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Kayıt sırasında bir hata oluştu',
          'data': null,
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Bağlantı hatası: $e',
        'data': null,
      };
    }
  }
  
  // Kullanıcı Giriş API'si
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      // Debug: API isteği oluşturuluyor...
      print('\n\n🔑🔑🔑 LOGIN API ÇAĞRILIYOR: $email 🔑🔑🔑');
      print('Endpoint: $baseUrl/auth/login');
      
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      ).timeout(const Duration(seconds: 10), onTimeout: () {
        print('🔴 Login API isteği zaman aşımına uğradı (10 saniye)');
        throw Exception('API isteği zaman aşımına uğradı. Lütfen internet bağlantınızı kontrol edin.');
      });

      // Debug: API yanıtı alındı
      print('🔔 LOGIN API yanıtı alındı: HTTP ${response.statusCode}');
      print('🔍 Yanıt Gövdesi: ${response.body}');
      
      // Yanıtı JSON'a çözmeyi dene
      Map<String, dynamic> responseData;
      try {
        responseData = jsonDecode(response.body);
        print('✅ Login JSON çözümleme başarılı: $responseData');
        
        // Spring Boot ApiResponse yapısını detaylı inceleme
        print('🔍 LOGIN API Response Detaylı Analizi:');
        if (responseData.containsKey('success')) {
          print('✓ API yanıtında success alanı var: ${responseData['success']}');
        } else {
          print('✗ API yanıtında success alanı YOK!');
        }
        
        if (responseData.containsKey('message')) {
          print('✓ API yanıtında message alanı var: "${responseData['message']}"');
        }
        
        if (responseData.containsKey('data')) {
          print('✓ API yanıtında data alanı var:');
          print(responseData['data']);
          
          // Data içeriğini incele
          final data = responseData['data'];
          if (data != null && data is Map<String, dynamic>) {
            print('Data anahtarları: ${data.keys.toList()}');
            
            // User ve token kontrolü
            if (data.containsKey('user')) {
              print('✓ Data içinde user objesi var');
              print(data['user']);
            }
            
            if (data.containsKey('token')) {
              print('✓ Data içinde token var: ${data['token']}');
            }
          }
        } else {
          print('✗ API yanıtında data alanı YOK!');
        }
        
        // Tüm anahtarları yazdır
        print('🔑 API yanıtındaki tüm anahtarlar: ${responseData.keys.toList()}');
        
      } catch (jsonError) {
        print('🔴 JSON çözümleme hatası: $jsonError');
        print('🔴 Yanıt içeriği: ${response.body}');
        return {
          'success': false,
          'message': 'Sunucudan gelen yanıt anlaşılamadı',
          'data': null,
        };
      }
      
      if (response.statusCode == 200) {
        // ApiResponse formatına uygun parse işlemi
        bool success = responseData['success'] ?? false;
        String message = responseData['message'] ?? 'Giriş başarılı';
        dynamic data = responseData['data'];
        
        print('🎉 Login başarılı, data döndürülüyor: success=$success');
        
        return {
          'success': success,
          'message': message,
          'data': data,
        };
      } else {
        print('🔴 Login başarısız: ${response.statusCode} - ${responseData['message']}');
        return {
          'success': false,
          'message': responseData['message'] ?? 'Giriş sırasında bir hata oluştu (${response.statusCode})',
          'data': null,
        };
      }
    } catch (e) {
      print('🔴 Login exception: $e');
      return {
        'success': false,
        'message': 'Giriş yapılamıyor: $e',
        'data': null,
      };
    }
  }
  
  // E-posta doğrulama sürecini başlat - İşlem başarılı olursa doğrulama kodunu e-posta adresine gönderir
  static Future<Map<String, dynamic>> initiateRegistration({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required String role, // WHOLESALER veya RETAILER
  }) async {
    try {
      // Debug: API isteği oluşturuluyor...
      print('initiateRegistration çağrılıyor');
      print('Endpoint: $baseUrl/auth/initiate-register');
      print('POST verileri: firstName: $firstName, lastName: $lastName, email: $email, role: $role');
      
      final Uri apiUri = Uri.parse('$baseUrl/auth/initiate-register');
      print('Parse edilen URL: ${apiUri.toString()}');
      
      // HTTP isteğini gönder ve zaman aşımını 10 saniyeye ayarla
      final response = await http.post(
        apiUri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'firstName': firstName,
          'lastName': lastName,
          'email': email,
          'password': password,
          'role': role,
        }),
      ).timeout(const Duration(seconds: 10), onTimeout: () {
        print('API isteği zaman aşımına uğradı (10 saniye)');
        throw Exception('API isteği zaman aşımına uğradı. Lütfen internet bağlantınızı kontrol edin.');
      });

      // Debug: API yanıtı alındı
      print('API yanıtı alındı: ${response.statusCode}');
      print('Yanıt Gövdesi: ${response.body}');
      
      // Yanıtı JSON\'a çözmeyi dene
      Map<String, dynamic> responseData;
      try {
        responseData = jsonDecode(response.body);
        print('JSON çözümleme başarılı: $responseData');
        
        // Spring Boot ApiResponse yapısını detaylı inceleme
        print('API Response Detay analizi:');
        if (responseData.containsKey('success')) {
          print('API yanıtında doğrudan success alanı var: ${responseData['success']}');
        } else {
          print('API yanıtında doğrudan success alanı YOK!');
        }
        
        if (responseData.containsKey('status')) {
          print('API yanıtında status alanı var: ${responseData['status']}');
        }
        
        if (responseData.containsKey('message')) {
          print('API yanıtında mesaj: ${responseData['message']}');
        }
        
        if (responseData.containsKey('data')) {
          print('API yanıtında data alanı var: ${responseData['data']}');
        } else {
          print('API yanıtında data alanı YOK!');
        }
        
        // Tüm anahtarları yazdır
        print('API yanıtındaki tüm anahtarlar: ${responseData.keys.toList()}');
        
      } catch (jsonError) {
        print('JSON çözümleme hatası: $jsonError');
        print('Yanıt içeriği: ${response.body}');
        return {
          'success': false,
          'message': 'Sunucudan gelen yanıt anlaşılamadı',
          'data': null,
        };
      }
      
      if (response.statusCode == 200) {
        print('Başarılı yanıt (200)');
        
        // ApiResponse<Map<String, Object>> formatını kontrol et
        bool success = false;
        String message = '';
        dynamic data;
        
        // Spring Boot ApiResponse formatına uygun parse işlemi
        if (responseData.containsKey('status')) {
          success = responseData['status'] == "SUCCESS";
          message = responseData['message'] ?? 'Doğrulama kodu e-posta adresinize gönderildi';
          data = responseData['data'];
          print('Spring Boot standard ApiResponse formatı tanındı: success=$success');
        } else {
          success = responseData['success'] == true;
          message = responseData['message'] ?? 'Doğrulama kodu e-posta adresinize gönderildi';
          data = responseData['data'];
          print('Alternatif API yanıt formatı tanındı: success=$success');
        }
        
        return {
          'success': success,
          'message': message,
          'data': data,
        };
      } else {
        print('Başarısız yanıt (${response.statusCode}): ${response.body}');
        return {
          'success': false,
          'message': responseData['message'] ?? 'Doğrulama kodu gönderilirken bir hata oluştu (HTTP ${response.statusCode})',
          'data': null,
        };
      }
    } catch (e) {
      print('initiateRegistration exception: $e');
      return {
        'success': false,
        'message': 'Kayıt başlatılamıyor: $e',
        'data': null,
      };
    }
  }

  // Doğrulama kodunu kontrol et
  static Future<Map<String, dynamic>> verifyCode({
    required String email,
    required String code,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/verification/verify'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'email': email,
          'code': code,
        }),
      );

      final responseData = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': responseData['message'] ?? 'E-posta doğrulama başarılı',
          'data': responseData['data'],
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Doğrulama kodu geçersiz veya süresi dolmuş',
          'data': null,
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Bağlantı hatası: $e',
        'data': null,
      };
    }
  }

  // Doğrulama kodunu yeniden gönder
  static Future<Map<String, dynamic>> resendVerificationCode({
    required String email,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/verification/send'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'email': email,
        }),
      );

      final responseData = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': responseData['message'] ?? 'Doğrulama kodu yeniden gönderildi',
          'data': responseData['data'],
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Doğrulama kodu gönderilirken bir hata oluştu',
          'data': null,
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Bağlantı hatası: $e',
        'data': null,
      };
    }
  }
  
  // E-posta doğrulama durumunu kontrol et
  static Future<Map<String, dynamic>> checkVerificationStatus({
    required String email,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/verification/status?email=$email'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      final responseData = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': responseData['message'] ?? 'Doğrulama durumu kontrol edildi',
          'data': responseData['data'], // true veya false dönecek
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Doğrulama durumu kontrol edilirken bir hata oluştu',
          'data': false,
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Bağlantı hatası: $e',
        'data': false,
      };
    }
  }
  
  // Doğrulama ve kayıt sonrası otomatik giriş
  static Future<Map<String, dynamic>> completeRegistrationAndLogin({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required String role,
  }) async {
    try {
      // 1. Kayıt işlemini tamamla
      final registerResponse = await register(
        firstName: firstName,
        lastName: lastName,
        email: email,
        password: password,
        role: role,
      );
      
      if (!registerResponse['success']) {
        return registerResponse; // Kayıt başarısız oldu
      }
      
      // 2. Kayıt başarılı, şimdi otomatik giriş yap
      final loginResponse = await login(
        email: email,
        password: password,
      );
      
      if (loginResponse['success']) {
        // Giriş başarılı, kullanıcı ve token bilgisini dön
        return {
          'success': true,
          'message': 'Kayıt ve giriş başarıyla tamamlandı',
          'data': loginResponse['data'],
          'token': loginResponse['token'],
          'user': loginResponse['user'],
        };
      } else {
        // Giriş başarısız ama kayıt başarılı
        return {
          'success': true,
          'message': 'Kayıt başarılı ancak otomatik giriş yapılamadı. Lütfen giriş yapın.',
          'data': registerResponse['data'],
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Kayıt ve giriş sırasında hata: $e',
        'data': null,
      };
    }
  }
  
  // Diğer API istekleri buraya eklenebilir (profil güncelleme vb.)
}
