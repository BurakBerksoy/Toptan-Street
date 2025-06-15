import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:toptan_street/core/models/user_model.dart';
import 'package:toptan_street/core/providers/app_state_provider.dart';
import 'package:toptan_street/core/services/api_service.dart';
import 'package:toptan_street/core/theme/app_theme.dart';
import 'package:toptan_street/features/auth/login_page.dart';
import 'package:toptan_street/features/auth/verification_code_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  // Seçili kullanıcı türü - varsayılan olarak Perakendeci
  UserRole _selectedRole = UserRole.RETAILER;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String? _errorMessage;
  
  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
  
  Future<void> _register() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
      
      // Form verilerini ekranda göster (hata ayıklama)
      debugPrint('Kayıt bilgileri:');
      debugPrint('Ad: ${_firstNameController.text.trim()}');
      debugPrint('Soyad: ${_lastNameController.text.trim()}');
      debugPrint('E-mail: ${_emailController.text.trim()}');
      debugPrint('Rol: ${_selectedRole.name}');
      
      try {
        debugPrint('==========================================');
        debugPrint('Backend\'e kayıt başlatma isteği gönderiliyor...');
        debugPrint('Kayıt bilgileri: ${_firstNameController.text.trim()}, ${_lastNameController.text.trim()}, ${_emailController.text.trim()}, Rol: ${_selectedRole.name}');
        debugPrint('==========================================');
        
        // Backend'e kayıt başlatma için API çağrısı yap
        final response = await ApiService.initiateRegistration(
          firstName: _firstNameController.text.trim(),
          lastName: _lastNameController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
          role: _selectedRole.name, // WHOLESALER veya RETAILER olarak gönderilecek
        ).timeout(Duration(seconds: 15), onTimeout: () {
          // Zaman aşımında özel işlem
          debugPrint('Kayıt başlatma isteği zaman aşımına uğradı!');
          return {
            'success': false,
            'message': 'Sunucu yanıt vermiyor. Lütfen daha sonra tekrar deneyin.',
            'data': null
          };
        });
        
        // API yanıtını göster (hata ayıklama)
        debugPrint('==========================================');
        debugPrint('API yanıtı (detaylı): $response');
        debugPrint('Başarı durumu: ${response['success']} (${response['success']?.runtimeType})');
        debugPrint('Mesaj: ${response['message']}');
        debugPrint('Veri: ${response['data']}');
        debugPrint('API yanıtındaki tüm anahtarlar: ${response.keys.toList()}');
        debugPrint('==========================================');
        
        // Boş yanıt kontrolü
        if (response == null) {
          throw Exception('Sunucudan yanıt alınamadı.');
        }
        
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          
          debugPrint('Yanıt success değeri inceleniyor: ${response['success']}, tipi: ${response['success'].runtimeType}');
          if (response['success'] == true) {
            debugPrint('\n========== YÖNLENDİRME YAPILIYOR ==========');
            debugPrint('Kayıt başlatma başarılı, doğrulama sayfasına geçiliyor...');
            
            // Doğrudan Navigator çağrısı yapıyoruz
            WidgetsBinding.instance.addPostFrameCallback((_) {
              debugPrint('YÖNLENDIRME: VerificationCodePage\'e geçiş yapılıyor...');
              
              Navigator.push(
                context,
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) => VerificationCodePage(
                    firstName: _firstNameController.text.trim(),
                    lastName: _lastNameController.text.trim(),
                    email: _emailController.text.trim(),
                    password: _passwordController.text.trim(),
                    role: _selectedRole,
                  ),
                  transitionsBuilder: (context, animation, secondaryAnimation, child) {
                    return FadeTransition(opacity: animation, child: child);
                  },
                ),
              );
            });
            
            // Alternatif basit yönlendirme (WidgetsBinding yaklaşımı başarısız olursa)
            if (!mounted) return;
            try {
              // Direkt yönlendirmeyi dene
              debugPrint('YÖNLENDIRME: Alternatif yöntem deneniyor...');
              
              // 200 ms bekleyip direkt geçiş yapmayı dene
              Future.delayed(Duration(milliseconds: 200), () {
                if (!mounted) return;
                debugPrint('YÖNLENDIRME: Gecikme sonrası geçiş yapılıyor');
                
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => VerificationCodePage(
                      firstName: _firstNameController.text.trim(),
                      lastName: _lastNameController.text.trim(),
                      email: _emailController.text.trim(),
                      password: _passwordController.text.trim(),
                      role: _selectedRole,
                    ),
                  ),
                );
              });
            } catch (navigationError) {
              debugPrint('YÖNLENDIRME HATASI: $navigationError');
            }
            
            // Bilgilendirme mesajı
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  response['message'] ?? 'Doğrulama kodu e-posta adresinize gönderildi',
                  style: GoogleFonts.poppins(),
                ),
                backgroundColor: Colors.green,
              ),
            );
            
            // Debug: Doğrulama kodunun gönderildiğini onaylama mesajı
            debugPrint('Doğrulama kodu gönderildi mesajı gösterildi');
          } else {
            // Doğrulama kodu gönderme hatası
            debugPrint('Kayıt başlatma başarısız: ${response['message']}');
            setState(() {
              // Daha açıklayıcı hata mesajları
              String hata = response['message'] ?? 'Doğrulama kodu gönderilirken bir hata oluştu';
              
              // Özel hata durumlarını kontrol et
              if (hata.contains('Email already exists') || 
                  hata.contains('E-posta zaten kullanımda') ||
                  hata.toLowerCase().contains('e-posta adresi kayıtlı')) {
                hata = 'Bu e-posta adresi zaten sistemde kayıtlı. Farklı bir e-posta deneyin veya giriş yapmayı deneyin.';
              } else if (hata.contains('Invalid email format') ||
                       hata.contains('Geçersiz e-posta formatı')) {
                hata = 'Lütfen geçerli bir e-posta adresi girin.';
              } else if (hata.contains('Password') || hata.contains('Şifre')) {
                hata = 'Şifre gereksinimlerini karşılamıyor. En az 8 karakter, bir büyük harf, bir küçük harf ve bir rakam içermelidir.';
              } else if (hata.contains('Connection') || hata.contains('Bağlantı')) {
                hata = 'Sunucu bağlantısı kurulamadı. İnternet bağlantınızı kontrol edin ve tekrar deneyin.';
              }
              
              _errorMessage = hata;
            });
            
            // Kullanıcıya hata mesajını görmesi için ekstra görsel uyarı
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Kayıt başlatılamıyor: ' + (response['message'] ?? 'Bilinmeyen hata'),
                  style: GoogleFonts.poppins(),
                ),
                backgroundColor: Colors.red,
                duration: Duration(seconds: 5),
              ),
            );
          }
        }
      } catch (e) {
        debugPrint('Kayıt sırasında istisna: $e');
        if (mounted) {
          setState(() {
            _errorMessage = 'Kayıt başlatılamadı: ${e.toString()}';
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Kayıt Ol',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: GestureDetector(
        onTap: () {
          // Klavyeyi kapat
          FocusScope.of(context).unfocus();
        },
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // 1. HATA MESAJI
                  if (_errorMessage != null)
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 20),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        border: Border.all(color: Colors.red.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _errorMessage!,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.red.shade700,
                        ),
                      ),
                    ),
                  
                  // Kullanıcı Türü Seçimi
                  Container(
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Text(
                            'Kullanıcı Türü',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        RadioListTile<UserRole>(
                          title: Text(
                            'Perakendeci',
                            style: GoogleFonts.poppins(),
                          ),
                          value: UserRole.RETAILER,
                          groupValue: _selectedRole,
                          onChanged: (value) {
                            setState(() {
                              _selectedRole = value!;
                            });
                          },
                        ),
                        RadioListTile<UserRole>(
                          title: Text(
                            'Toptancı',
                            style: GoogleFonts.poppins(),
                          ),
                          value: UserRole.WHOLESALER,
                          groupValue: _selectedRole,
                          onChanged: (value) {
                            setState(() {
                              _selectedRole = value!;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  
                  // Toptancı ücret bilgilendirmesi
                  if (_selectedRole == UserRole.WHOLESALER)
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 20),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        border: Border.all(color: Colors.amber.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Colors.amber.shade800,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Toptancı üyelik için 50 TL ödeme gerekmektedir.',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: Colors.amber.shade800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  
                  // 2. KAYIT FORMU
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        // Ad alanı
                        TextFormField(
                          controller: _firstNameController,
                          keyboardType: TextInputType.name,
                          decoration: InputDecoration(
                            labelText: 'Adınız',
                            hintText: 'Adınızı girin',
                            prefixIcon: const Icon(Icons.person_outline),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: AppTheme.primaryColor,
                                width: 2,
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 16,
                              horizontal: 16,
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Ad gerekli';
                            }
                            return null;
                          },
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Soyad alanı
                        TextFormField(
                          controller: _lastNameController,
                          keyboardType: TextInputType.name,
                          decoration: InputDecoration(
                            labelText: 'Soyadınız',
                            hintText: 'Soyadınızı girin',
                            prefixIcon: const Icon(Icons.person_outline),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: AppTheme.primaryColor,
                                width: 2,
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 16,
                              horizontal: 16,
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Soyad gerekli';
                            }
                            return null;
                          },
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Email alanı
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            labelText: 'E-posta',
                            hintText: 'ornek@eposta.com',
                            prefixIcon: const Icon(Icons.email_outlined),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: AppTheme.primaryColor,
                                width: 2,
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 16,
                              horizontal: 16,
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'E-posta gerekli';
                            }
                            // Basit e-posta kontrolü
                            if (!value.contains('@') || !value.contains('.')) {
                              return 'Geçerli bir e-posta adresi girin';
                            }
                            return null;
                          },
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Şifre alanı
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          decoration: InputDecoration(
                            labelText: 'Şifre',
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                color: Colors.grey,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: AppTheme.primaryColor,
                                width: 2,
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 16,
                              horizontal: 16,
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Şifre gerekli';
                            }
                            if (value.length < 6) {
                              return 'Şifre en az 6 karakter olmalıdır';
                            }
                            return null;
                          },
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Şifre tekrar alanı
                        TextFormField(
                          controller: _confirmPasswordController,
                          obscureText: _obscureConfirmPassword,
                          decoration: InputDecoration(
                            labelText: 'Şifre Tekrar',
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureConfirmPassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                color: Colors.grey,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscureConfirmPassword = !_obscureConfirmPassword;
                                });
                              },
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: AppTheme.primaryColor,
                                width: 2,
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 16,
                              horizontal: 16,
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Şifre tekrarı gerekli';
                            }
                            if (value != _passwordController.text) {
                              return 'Şifreler eşleşmiyor';
                            }
                            return null;
                          },
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // Kayıt Ol Butonu
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _register,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor,
                              foregroundColor: Colors.white,
                              elevation: 1,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2.5,
                                    ),
                                  )
                                : Text(
                                    'Kayıt Ol',
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  // Giriş Sayfasına Dön
                  Divider(height: 32, color: Colors.grey.shade300),
                  
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context); // Kayıt sayfasını kapat, login sayfasına dön
                    },
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      'Zaten bir hesabınız var mı? Giriş Yap',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: const Color(0xFF3366CC),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Google ile kayıt ol
                  Container(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        // Google ile kayıt - şimdilik sadece UI
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Google ile kayıt şu an aktif değil')),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.grey.shade300),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: SvgPicture.asset(
                        'assets/images/google_logo.svg',
                        height: 20,
                      ),
                      label: Text(
                        'Google ile Kayıt Ol',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
