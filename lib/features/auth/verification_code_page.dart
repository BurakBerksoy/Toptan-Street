import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:toptan_street/core/models/user_model.dart';
import 'package:toptan_street/core/providers/app_state_provider.dart';
import 'package:toptan_street/core/services/api_service.dart';
import 'package:toptan_street/core/theme/app_theme.dart';

class VerificationCodePage extends StatefulWidget {
  final String firstName;
  final String lastName;
  final String email;
  final String password;
  final UserRole role;

  const VerificationCodePage({
    super.key,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.password,
    required this.role,
  });

  @override
  State<VerificationCodePage> createState() => _VerificationCodePageState();
}

class _VerificationCodePageState extends State<VerificationCodePage> {
  final List<TextEditingController> _controllers = List.generate(
    6,
    (index) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(
    6,
    (index) => FocusNode(),
  );

  Timer? _timer;
  int _timeLeft = 300; // 5 dakika = 300 saniye
  bool _isLoading = false;
  bool _isResendLoading = false;
  String? _errorMessage;
  bool _isVerified = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() {
      _timeLeft = 300;
    });
    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (timer) {
        if (_timeLeft == 0) {
          timer.cancel();
        } else {
          setState(() {
            _timeLeft--;
          });
        }
      },
    );
  }

  String _formatTimeLeft() {
    final minutes = _timeLeft ~/ 60;
    final seconds = _timeLeft % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  String _getFullCode() {
    return _controllers.map((controller) => controller.text).join();
  }

  Future<void> _verifyCode() async {
    final code = _getFullCode();
    if (code.length != 6) {
      setState(() {
        _errorMessage = 'Lütfen 6 haneli kodu eksiksiz girin';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // API çağrısı ile kodu doğrula
      final response = await ApiService.verifyCode(
        email: widget.email,
        code: code,
      );

      if (mounted) {
        if (response['success']) {
          setState(() {
            _isVerified = true;
            _isLoading = false;
          });

          // Doğrulama başarılı, doğrudan kayıt işlemini tamamla
          _completeRegistration();
        } else {
          setState(() {
            _errorMessage = response['message'];
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Doğrulama sırasında bir hata oluştu: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _resendCode() async {
    if (_isResendLoading || _timeLeft > 0) return;

    setState(() {
      _isResendLoading = true;
      _errorMessage = null;
    });

    try {
      // API çağrısı ile kodu yeniden gönder
      final response = await ApiService.resendVerificationCode(
        email: widget.email,
      );

      if (mounted) {
        if (response['success']) {
          // Süreyi yeniden başlat
          _startTimer();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Doğrulama kodu yeniden gönderildi',
                style: GoogleFonts.poppins(),
              ),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          setState(() {
            _errorMessage = response['message'];
          });
        }
        setState(() {
          _isResendLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Kod gönderilirken bir hata oluştu: $e';
          _isResendLoading = false;
        });
      }
    }
  }

  // Ödeme sayfası geçici olarak kaldırıldı

  Future<void> _completeRegistration() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null; // Önceki hata mesajlarını temizle
    });

    try {
      // Önce e-posta doğrulama durumunu kontrol et
      final verificationStatus = await ApiService.checkVerificationStatus(
        email: widget.email,
      );
      
      if (!verificationStatus['success'] || verificationStatus['data'] == false) {
        // Doğrulama başarısız
        setState(() {
          _isLoading = false;
          _errorMessage = 'E-posta adresiniz doğrulanmamış. Lütfen doğrulama kodunu tekrar kontrol edin.';
        });
        return;
      }

      // Kayıt ve otomatik giriş işlemini tek seferde yap
      final response = await ApiService.completeRegistrationAndLogin(
        firstName: widget.firstName,
        lastName: widget.lastName,
        email: widget.email,
        password: widget.password,
        role: widget.role.name,
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        if (response['success']) {
          // Başarılı kayıt ve otomatik giriş
          final appState = Provider.of<AppStateProvider>(context, listen: false);
          appState.setLoginStatus(true);
          
          // Tüm açık sayfaları kapat ve ana sayfaya yönlendir
          Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
          
          // Başarı mesajı
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Kayıt işleminiz başarıyla tamamlandı!',
                style: GoogleFonts.poppins(),
              ),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          // Kayıt veya giriş sırasında bir hata oluştu
          setState(() {
            _errorMessage = response['message'] ?? 'Kayıt tamamlanamıyor. Lütfen daha sonra tekrar deneyin.';
            
            // "Authentication failed" yerine daha açıklayıcı mesajlar
            if (_errorMessage != null) {
              if (_errorMessage!.contains('Authentication failed') || 
                  _errorMessage!.contains('doğrulanmamış') ||
                  _errorMessage!.contains('E-posta adresi doğrulanmamış')) {
                _errorMessage = 'E-posta adresiniz henüz doğrulanmamış. Lütfen doğrulama kodunu tekrar girin.';
              } else if (_errorMessage!.contains('Email zaten kullanımda')) {
                _errorMessage = 'Bu e-posta adresi zaten kayıtlı. Lütfen giriş yapmayı deneyin.';
              }
            }
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Kayıt tamamlanırken bir hata oluştu: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'E-posta Doğrulama',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              Icon(
                Icons.email_outlined,
                size: 80,
                color: Theme.of(context).primaryColor,
              ),
              const SizedBox(height: 20),
              Text(
                'Doğrulama Kodu',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                '${widget.email} adresine gönderilen 6 haneli doğrulama kodunu girin',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              // Doğrulama kodu girişi için 6 kutu
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  6,
                  (index) => _buildCodeInput(index),
                ),
              ),
              const SizedBox(height: 10),
              // Geri sayım
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.timer, size: 18, color: Colors.grey),
                  const SizedBox(width: 5),
                  Text(
                    'Kalan süre: ${_formatTimeLeft()}',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: _timeLeft > 0 ? Colors.grey[600] : Colors.red,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Hata mesajı
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Text(
                    _errorMessage!,
                    style: GoogleFonts.poppins(
                      color: Colors.red,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              // Doğrula butonu
              ElevatedButton(
                onPressed: _isLoading ? null : _verifyCode,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 40,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        'Doğrula',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
              const SizedBox(height: 20),
              // Yeniden kod gönder
              TextButton(
                onPressed: (_timeLeft == 0 && !_isResendLoading) ? _resendCode : null,
                child: _isResendLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        'Kodu Yeniden Gönder',
                        style: GoogleFonts.poppins(
                          color: _timeLeft == 0
                              ? AppTheme.primaryColor
                              : Colors.grey,
                        ),
                      ),
              ),
              const SizedBox(height: 10),
              // Rol bilgisi
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Column(
                  children: [
                    Text(
                      widget.role == UserRole.WHOLESALER ? 'Toptancı Hesabı' : 'Perakendeci Hesabı',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'E-posta doğrulaması başarıyla tamamlandıktan sonra kayıt işleminiz tamamlanacaktır.',
                      style: GoogleFonts.poppins(fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCodeInput(int index) {
    return Container(
      width: 45,
      height: 50,
      margin: const EdgeInsets.symmetric(horizontal: 5),
      decoration: BoxDecoration(
        border: Border.all(
          color: _controllers[index].text.isNotEmpty
              ? AppTheme.primaryColor
              : Colors.grey[300]!,
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: TextField(
        controller: _controllers[index],
        focusNode: _focusNodes[index],
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        maxLength: 1,
        onChanged: (value) {
          if (value.isNotEmpty && index < 5) {
            _focusNodes[index + 1].requestFocus();
          }
          setState(() {});
        },
        decoration: const InputDecoration(
          counterText: '',
          border: InputBorder.none,
        ),
        style: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

// Ödeme sayfası geçici olarak kaldırıldı
