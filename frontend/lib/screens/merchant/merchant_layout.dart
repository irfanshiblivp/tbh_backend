import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_theme.dart';
import '../../providers/app_state.dart';
import 'merchant_dashboard.dart';
import 'merchant_offers_screen.dart';
import 'merchant_profile_screen.dart';
import 'merchant_transactions_screen.dart';
import 'merchant_verification_screen.dart';

class MerchantLayout extends StatefulWidget {
  const MerchantLayout({super.key});

  @override
  State<MerchantLayout> createState() => _MerchantLayoutState();
}

class _MerchantLayoutState extends State<MerchantLayout> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const MerchantDashboard(),
    const MerchantVerificationScreen(),
    const MerchantTransactionsScreen(),
    const MerchantProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    try {
      return Scaffold(
        backgroundColor: const Color(0xFF0F0F1E),
        body: _pages[_selectedIndex],
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: Colors.white.withOpacity(0.05))),
          ),
          child: BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: (index) => setState(() => _selectedIndex = index),
            backgroundColor: const Color(0xFF1A1A2E),
            selectedItemColor: AppColors.amber,
            unselectedItemColor: Colors.white24,
            type: BottomNavigationBarType.fixed,
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), activeIcon: Icon(Icons.dashboard), label: "Dashboard"),
              BottomNavigationBarItem(icon: Icon(Icons.qr_code_scanner_outlined), activeIcon: Icon(Icons.qr_code_scanner), label: "POS / Redeem"),
              BottomNavigationBarItem(icon: Icon(Icons.receipt_long_outlined), activeIcon: Icon(Icons.receipt_long), label: "History"),
              BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: "Profile"),
            ],
          ),
        ),
      );
    } catch (e) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Text("Merchant Layout Error: $e", style: const TextStyle(color: Colors.redAccent)),
        ),
      );
    }
  }
}
