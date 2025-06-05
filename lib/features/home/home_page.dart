import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:toptan_street/core/constants/app_constants.dart';
import 'package:toptan_street/core/providers/app_state_provider.dart';
import 'package:toptan_street/core/theme/app_theme.dart';
import 'package:toptan_street/widgets/bottom_navbar.dart';
import 'package:toptan_street/widgets/top_navbar.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    // Uygulama ilk açıldığında default bildirim durumunu ayarlayalım
    Future.microtask(() {
      Provider.of<AppStateProvider>(context, listen: false)
          .setNotificationStatus(true);
    });
  }

  @override
  Widget build(BuildContext context) {
    // Provider'dan durum bilgisini alalım
    final appState = Provider.of<AppStateProvider>(context);
    
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: TopNavbar(
        isLoggedIn: appState.isLoggedIn,
        hasNotification: appState.hasNotification,
      ),
      body: _buildBody(),
      bottomNavigationBar: BottomNavbar(
        currentIndex: appState.currentNavIndex,
        onTap: (index) {
          appState.setNavIndex(index);
        },
      ),
    );
  }

  Widget _buildBody() {
    // Ana sayfa içeriği (henüz ürün yok mesajı)
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            AppConstants.noProductsMessage,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}
