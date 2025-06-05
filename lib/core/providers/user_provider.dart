import 'package:flutter/material.dart';
import 'package:toptan_street/core/models/user_model.dart';

class UserProvider extends ChangeNotifier {
  User? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isLoggedIn => _currentUser != null;

  // Kullanıcı oturumunu ayarla
  void setUser(User user) {
    _currentUser = user;
    _errorMessage = null;
    notifyListeners();
  }

  // Oturumu kapat
  void logout() {
    _currentUser = null;
    notifyListeners();
  }

  // Oturum durumunu güncelle
  void updateLoadingStatus(bool isLoading) {
    _isLoading = isLoading;
    notifyListeners();
  }

  // Hata mesajını ayarla
  void setErrorMessage(String message) {
    _errorMessage = message;
    notifyListeners();
  }

  // Kullanıcı rolünü kontrol et
  bool isWholesaler() {
    return _currentUser?.role == 'WHOLESALER';
  }

  // Kullanıcı ödeme durumunu kontrol et
  bool get hasCompletedPayment {
    return _currentUser?.paymentStatus == true;
  }

  // Kullanıcı adını getir
  String get fullName {
    if (_currentUser == null) {
      return '';
    }
    return '${_currentUser!.firstName} ${_currentUser!.lastName}';
  }
}
