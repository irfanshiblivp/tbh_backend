import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_theme.dart';
import '../../providers/app_state.dart';
import 'package:intl/intl.dart';
import 'admin_dashboard.dart';
import 'merchant_management_screen.dart';
import 'category_management_screen.dart';
import 'user_management_screen.dart';
import 'admin_management_screen.dart';
import 'prime_management_screen.dart';
import 'transaction_management_screen.dart';
import 'announcement_screen.dart';
import 'state_management_screen.dart';
import 'referral_management_screen.dart';

class AdminLayout extends StatefulWidget {
  const AdminLayout({super.key});

  @override
  State<AdminLayout> createState() => _AdminLayoutState();
}

class _AdminLayoutState extends State<AdminLayout> {
  int _selectedIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final List<Widget> _pages = [
    const AdminDashboard(),
    const TransactionManagementScreen(),
    const MerchantManagementScreen(),
    const AppUserManagementScreen(),
    const CategoryManagementScreen(),
    const AnnouncementScreen(),
    const AdminManagementScreen(),
    const PrimeManagementScreen(),
    const ReferralManagementScreen(),
  ];


  @override
  Widget build(BuildContext context) {
    try {
      final state = context.watch<AppState>();
      final isDesktop = MediaQuery.of(context).size.width > 1100;
      final isTablet = MediaQuery.of(context).size.width > 700;

      return Stack(
        children: [
          Scaffold(
            key: _scaffoldKey,
            body: Row(
              children: [
                if (isDesktop || isTablet)
                  _buildSidebar(isDesktop),
                Expanded(
                  child: SafeArea(
                    child: Column(
                      children: [
                        _buildHeader(context),
                        Expanded(
                          child: _pages[_selectedIndex],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            drawer: (!isDesktop) ? Drawer(child: _buildSidebar(true)) : null,
          ),
          if (state.isLoading)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.6),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1A2E),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.amber.withOpacity(0.2)),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(AppColors.amber),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          "Processing...",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.none,
                            fontFamily: 'Outfit',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      );
    } catch (e) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Text("Admin Layout Error: $e", style: const TextStyle(color: Colors.redAccent)),
        ),
      );
    }
  }

  Widget _buildSidebar(bool isExpanded) {
    return Container(
      width: isExpanded ? 260 : 80,
      color: const Color(0xFF151521),
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),
            _buildLogo(isExpanded),
          const SizedBox(height: 40),
          _buildSidebarItem(0, Icons.dashboard_outlined, Icons.dashboard, "Dashboard", isExpanded),
          _buildSidebarItem(1, Icons.receipt_long_outlined, Icons.receipt_long, "Transactions", isExpanded),
          _buildSidebarItem(2, Icons.store_outlined, Icons.store, "Merchants", isExpanded),
          _buildSidebarItem(3, Icons.people_outline, Icons.people, "Users", isExpanded),
          _buildSidebarItem(4, Icons.category_outlined, Icons.category, "Categories", isExpanded),
          _buildSidebarItem(5, Icons.campaign_outlined, Icons.campaign, "Announcements", isExpanded),
          _buildSidebarItem(6, Icons.admin_panel_settings_outlined, Icons.admin_panel_settings, "Admins", isExpanded),
          _buildSidebarItem(7, Icons.star_outline, Icons.star, "Prime Plan", isExpanded),
          _buildSidebarItem(8, Icons.card_giftcard_outlined, Icons.card_giftcard, "Referrals", isExpanded),
          const Spacer(),

          const SizedBox(height: 20),
        ],
      ),
    ),
    );
  }

  Widget _buildLogo(bool isExpanded) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Image.asset('res/images/logo_transparent.png', height: 32),
        if (isExpanded) ...[
          const SizedBox(width: 12),
          const Text(
            "The Baron Club",
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSidebarItem(int index, IconData icon, IconData activeIcon, String label, bool isExpanded) {
    final isSelected = _selectedIndex == index;
    return InkWell(
      onTap: () {
        setState(() => _selectedIndex = index);
        if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
          Navigator.pop(context);
        }
      },
      child: Container(

        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          border: isSelected ? Border(left: BorderSide(color: AppColors.amber, width: 4)) : null,
          gradient: isSelected ? LinearGradient(
            colors: [AppColors.amber.withOpacity(0.1), Colors.transparent],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ) : null,
        ),
        child: Row(
          children: [
            Icon(isSelected ? activeIcon : icon, color: isSelected ? AppColors.amber : Colors.white54),
            if (isExpanded) ...[
              const SizedBox(width: 16),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.white54,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final state = context.watch<AppState>();
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth <= 700;
    final isVerySmall = screenWidth <= 450;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 24, vertical: isMobile ? 24 : 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.05))),
      ),
      child: Row(
        children: [
          if (isMobile)
            IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () => _scaffoldKey.currentState?.openDrawer(),
            ),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!isVerySmall)
                  Text(
                    DateFormat('EEEE, MMM d').format(DateTime.now()),
                    style: const TextStyle(color: Colors.white30, fontSize: 10),
                  ),
                Text(
                  isVerySmall ? "Admin" : "Welcome Back, Admin",
                  style: TextStyle(
                    color: Colors.white, 
                    fontSize: isVerySmall ? 16 : 18, 
                    fontWeight: FontWeight.bold,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          if (!isMobile) ...[
            const Spacer(),
            _buildSearchBox(),
          ],
          const SizedBox(width: 12),
          _buildAdminProfile(state),
        ],
      ),
    );
  }

  Widget _buildSearchBox() {
    return Container(
      width: 300,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const TextField(
        style: TextStyle(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          icon: Icon(Icons.search, color: Colors.white24, size: 20),
          hintText: "Search anything...",
          hintStyle: TextStyle(color: Colors.white24),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildAdminProfile(AppState state) {
    return PopupMenuButton<String>(
      offset: const Offset(0, 50),
      color: const Color(0xFF1A1A2E),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.amber.withOpacity(0.1),
            child: const Icon(Icons.person, color: AppColors.amber, size: 20),
          ),
          const SizedBox(width: 12),
          const Icon(Icons.keyboard_arrow_down, color: Colors.white24),
        ],
      ),
      onSelected: (value) {
        if (value == 'profile') {
          setState(() => _selectedIndex = 6);
        } else if (value == 'activity') {
          setState(() => _selectedIndex = 0);
        }
      },
      itemBuilder: (context) => <PopupMenuEntry<String>>[
        const PopupMenuItem(value: 'profile', child: Text("Profile Settings", style: TextStyle(color: Colors.white))),
        const PopupMenuItem(value: 'activity', child: Text("Activity Log", style: TextStyle(color: Colors.white))),
        const PopupMenuDivider(),
        PopupMenuItem(
          onTap: () => state.logout(),
          child: const Text("Logout", style: TextStyle(color: Colors.redAccent)),
        ),
      ],

    );
  }
}
