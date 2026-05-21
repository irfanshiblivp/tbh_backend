import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:frontend/core/app_theme.dart';
import 'package:frontend/providers/app_state.dart';
import 'package:frontend/screens/auth_screen.dart';
import 'package:frontend/screens/verification_screen.dart';
import 'package:frontend/screens/home_screen.dart';
import 'package:frontend/screens/categories_screen.dart';
import 'package:frontend/screens/profile_screen.dart';
import 'package:frontend/screens/merchant/merchant_layout.dart';
import 'package:frontend/screens/admin/admin_layout.dart';

void main() {
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return Material(
      color: Colors.black,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Text(
            "App Error: ${details.exception}",
            style: const TextStyle(color: Colors.redAccent, fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  };
  runApp(
    ChangeNotifierProvider(
      create: (_) => AppState(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'The Baron Club',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const RootScreen(),
    );
  }
}

class RootScreen extends StatelessWidget {
  const RootScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    
    // Check for Connection or Server Errors
    if (!state.hasConnection || !state.serverAvailable) {
      return Scaffold(
        backgroundColor: const Color(0xFF090910),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(40.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  !state.hasConnection ? Icons.wifi_off : Icons.dns_outlined,
                  size: 80,
                  color: AppColors.amber.withOpacity(0.5),
                ),
                const SizedBox(height: 32),
                Text(
                  !state.hasConnection ? "NO INTERNET" : "SERVER ACCESS FAILED",
                  style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 1.5),
                ),
                const SizedBox(height: 12),
                Text(
                  !state.hasConnection 
                    ? "Please check your data connection or Wi-Fi." 
                    : "The server is currently unreachable. Please try again later.",
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white38, fontSize: 14),
                ),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => state.refreshData(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.amber,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text("RETRY CONNECTION", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
    
    if (state.isCheckingAuth || (state.isLoggedIn && state.profile == null && state.isLoading)) {
      return Scaffold(
        backgroundColor: const Color(0xFF090910),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('res/images/logo_transparent.png', height: 80),
              const SizedBox(height: 24),
              const CircularProgressIndicator(color: AppColors.amber),
              const SizedBox(height: 12),
              const Text("Syncing your profile...", style: TextStyle(color: Colors.white38, fontSize: 12)),
            ],
          ),
        ),
      );
    }
    
    print("RootScreen Build: isLoggedIn=${state.isLoggedIn}, isVerified=${state.isVerified}, role=${state.userRole}");
    
    if (!state.isLoggedIn) return const AuthScreen();
    
    // Redirect to verification if not verified (like website)
    if (!state.isVerified) {
      print("Redirecting to VerificationScreen");
      return const VerificationScreen();
    }
    
    // Using snake_case roles from Laravel DB
    print("Navigating to Layout for role: ${state.userRole}");
    if (state.userRole == 'merchant') return const MerchantLayout();
    if (state.userRole == 'admin') return const AdminLayout();

    return const MainLayout();
  }
}

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const CategoriesScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    try {
      return Scaffold(
        body: _screens[_currentIndex],
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          type: BottomNavigationBarType.fixed,
          backgroundColor: AppColors.ink2,
          selectedItemColor: AppColors.amber,
          unselectedItemColor: AppColors.text2.withOpacity(0.5),
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10),
          unselectedLabelStyle: const TextStyle(fontSize: 10),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'HOME'),
            BottomNavigationBarItem(icon: Icon(Icons.grid_view_outlined), activeIcon: Icon(Icons.grid_view), label: 'CATEGORIES'),
            BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'PROFILE'),
          ],
        ),
      );
    } catch (e) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Text("Layout Error: $e", style: const TextStyle(color: Colors.redAccent)),
        ),
      );
    }
  }
}
