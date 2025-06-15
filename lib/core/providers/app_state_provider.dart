import 'package:flutter/material.dart';
import 'package:toptan_street/core/services/api_service.dart';

class AppStateProvider extends ChangeNotifier {
  // Kullanıcı giriş durumu
  bool _isLoggedIn = false;
  bool get isLoggedIn => _isLoggedIn;
  
  // Kullanıcı bilgileri
  Map<String, dynamic>? _userData;
  Map<String, dynamic>? get userData => _userData;
  
  // JWT token
  String? _token;
  String? get token => _token;

  // Bildirim durumu
  bool _hasNotification = false;
  bool get hasNotification => _hasNotification;

  // Seçilen alt navigasyon indeksi
  int _currentNavIndex = 0;
  int get currentNavIndex => _currentNavIndex;

  // Giriş durumunu güncelle
  void setLoginStatus(bool status) {
    _isLoggedIn = status;
    notifyListeners();
  }

  // Bildirim durumunu güncelle
  void setNotificationStatus(bool status) {
    _hasNotification = status;
    notifyListeners();
  }

  // Alt navigasyon indeksini güncelle
  void setNavIndex(int index) {
    _currentNavIndex = index;
    notifyListeners();
  }

  // API üzerinden giriş yap
  Future<bool> login(String email, String password) async {
    try {
      print('🔑 Login işlemi başlatılıyor: $email');
      
      // API'ye giriş isteği gönder
      final response = await ApiService.login(
        email: email,
        password: password,
      );
      
      print('🔑 Login API cevabı alındı: ${response['success']}');
      
      if (response['success'] == true) {
        // Giriş başarılı - kullanıcı bilgilerini ve token'ı sakla
        final data = response['data'];
        if (data != null && data is Map<String, dynamic>) {
          print('🔑 Login data içeriği işleniyor...');
          
          // User ve token bilgilerini ayıkla
          if (data.containsKey('user')) {
            _userData = data['user'];
            print('🔑 Kullanıcı bilgileri saklandı: ${_userData?['email']}');
          } else {
            print('⚠️ Uyarı: API cevabında user bilgisi yok!');
          }
          
          if (data.containsKey('token')) {
            _token = data['token']?.toString();
            print('🔑 Token saklandı: ${_token?.substring(0, 10)}...');
          } else {
            print('⚠️ Uyarı: API cevabında token yok!');
          }
          
          // Girişi başarılı işaretle (user ve token olmasa bile, API başarılı olduğu için girilsin)
          _isLoggedIn = true;
          notifyListeners();
          print('🔑 Giriş başarılı, uygulama durumu güncellendi');
          return true;
        } else {
          // API başarılı ama data objesi yok veya formatı yanlış
          print('⚠️ Uyarı: API başarılı ama data formatı yanlış: $data');
          return false;
        }
      } else {
        // Giriş başarısız
        print('🔴 Giriş başarısız: ${response['message']}');
        return false;
      }
    } catch (e) {
      print('🔴 Login hatası: $e');
      return false;
    }
  }

  // Çıkış işlemi
  void logout() {
    _isLoggedIn = false;
    _userData = null;
    _token = null;
    notifyListeners();
  }
}
