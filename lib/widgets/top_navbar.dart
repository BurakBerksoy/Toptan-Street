import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:toptan_street/core/constants/app_constants.dart';
import 'package:toptan_street/core/providers/app_state_provider.dart';
import 'package:toptan_street/core/theme/app_theme.dart';
import 'package:toptan_street/features/auth/login_page.dart';

class TopNavbar extends StatelessWidget implements PreferredSizeWidget {
  final bool isLoggedIn;
  final bool hasNotification;
  
  const TopNavbar({
    super.key,
    this.isLoggedIn = false,
    this.hasNotification = false,
  });
 
  @override
  Size get preferredSize => const Size.fromHeight(56.0);

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final bool isMobile = screenWidth < 600;

    return AppBar(
      backgroundColor: Colors.white,
      elevation: 1,
      scrolledUnderElevation: 2,
      shadowColor: Colors.black12,
      titleSpacing: 0,
      automaticallyImplyLeading: false,
      title: Row(
        children: [
          // 1. SOL BÖLGE: Sadece Logo
          Padding(
            padding: const EdgeInsets.only(left: 12.0),
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(
                Icons.inventory_2_outlined,
                size: 18,
                color: Colors.white,
              ),
            ),
          ),
          
          // 2. ORTA BÖLGE: Arama Çubuğu
          Expanded(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: isMobile ? screenWidth * 0.7 : double.infinity,
              ),
              margin: const EdgeInsets.symmetric(horizontal: 12),
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFF2F2F2),
                borderRadius: BorderRadius.circular(8),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 2,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Sabit arama ikonu
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    child: Icon(
                      Icons.search,
                      color: Color(0xFF9E9E9E),
                      size: 20,
                    ),
                  ),
                  // Arama alanı
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Ürün, kategori veya marka ara',
                        hintStyle: GoogleFonts.poppins(
                          fontSize: 14,
                          color: const Color(0xFF9E9E9E),
                        ),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 10,
                        ),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // 3. SAĞ BÖLGE: Login Durumuna Göre Değişen İçerik
          // Bildirim ikonu (her durumda gösterilir)
          Container(
            margin: const EdgeInsets.only(right: 4),
            child: IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints( // Minimum 48x48 touch target
                minWidth: 48,
                minHeight: 48,
              ),
              onPressed: () {
                // Bildirimler sayfasına yönlendir
              },
              icon: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(
                    Icons.notifications_outlined,
                    color: Color(0xFF424242),
                    size: 24,
                  ),
                  if (hasNotification && isLoggedIn)
                    Positioned(
                      top: -2,
                      right: -2,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          
          // Login durumuna göre değişen içerik
          if (isLoggedIn)
            // Profil ikonu 
            Container(
              margin: const EdgeInsets.only(right: 8),
              child: IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth: 48,
                  minHeight: 48,
                ),
                onPressed: () => _showProfileMenu(context),
                icon: const Icon(
                  Icons.person_outline,
                  color: Color(0xFF424242),
                  size: 24,
                ),
              ),
            )
          else
            // "Giriş Yap" butonu
            Container(
              margin: const EdgeInsets.only(right: 12),
              child: TextButton(
                onPressed: () {
                  // Direkt login sayfasına yönlendir
                  Navigator.pushNamed(context, '/login');
                },
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  minimumSize: const Size(48, 48), // Minimum touch target
                ),
                child: Text(
                  'Giriş Yap',
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF1A237E), // Koyu mavi tema rengi
                    fontWeight: FontWeight.w500, // Medium
                    fontSize: 14,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showProfileMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.person, color: AppTheme.primaryColor),
              title: Text(
                AppConstants.profileLabel,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              onTap: () {
                Navigator.pop(context);
                // Profil sayfasına yönlendir
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings, color: AppTheme.primaryColor),
              title: Text(
                AppConstants.settingsLabel,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              onTap: () {
                Navigator.pop(context);
                // Ayarlar sayfasına yönlendir
              },
            ),
            ListTile(
              leading: const Icon(Icons.shopping_bag, color: AppTheme.primaryColor),
              title: Text(
                AppConstants.ordersLabel,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              onTap: () {
                Navigator.pop(context);
                // Siparişler sayfasına yönlendir
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: Text(
                AppConstants.logoutLabel,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.red,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                // Provider üzerinden çıkış işlemi
                Provider.of<AppStateProvider>(context, listen: false).logout();
              },
            ),
          ],
        ),
      ),
    );
  }
  
  // Bottom sheet kodu kaldırıldı
  
}
