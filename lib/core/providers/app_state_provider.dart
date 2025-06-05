import 'package:flutter/material.dart';

class AppStateProvider extends ChangeNotifier {
  // Kullanıcı giriş durumu
  bool _isLoggedIn = false;
  bool get isLoggedIn => _isLoggedIn;

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

  // Test için şifre kontrolü (gerçek uygulamada API ile değiştirilecek)
  Future<bool> login(String email, String password) async {
    // API çağrısını simule et
    await Future.delayed(const Duration(seconds: 2));
    
    // Demo için basit kontrol
    if (email == 'test@example.com' && password == 'password123') {
      _isLoggedIn = true;
      notifyListeners();
      return true;
    }
    return false;
  }

  // Çıkış işlemi
  void logout() {
    _isLoggedIn = false;
    notifyListeners();
  }
}
