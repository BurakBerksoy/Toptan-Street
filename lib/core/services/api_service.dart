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
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      final responseData = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': responseData['message'] ?? 'Giriş başarılı',
          'data': responseData['data'],
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Giriş sırasında bir hata oluştu',
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
  
  // Diğer API istekleri buraya eklenebilir (profil güncelleme vb.)
}
