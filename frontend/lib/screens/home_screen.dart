import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:frontend/core/app_theme.dart';
import '../providers/app_state.dart';
import '../models/models.dart';
import 'merchant_detail_screen.dart';
import 'prime_screen.dart';
import 'package:geolocator/geolocator.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String activeCategory = 'all';

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final profile = state.profile;

    return Scaffold(
      backgroundColor: const Color(0xFF07070A),
      body: RefreshIndicator(
        onRefresh: state.refreshData,
        color: AppColors.amber,
        backgroundColor: AppColors.ink2,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Custom App Bar
            SliverAppBar(
              expandedHeight: 120,
              floating: false,
              pinned: true,
              backgroundColor: const Color(0xFF07070A).withOpacity(0.95),
              elevation: 0,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppColors.amber.withOpacity(0.12),
                        const Color(0xFF07070A),
                      ],
                    ),
                  ),
                ),
                titlePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                title: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Image.asset('res/images/logo_transparent.png', height: 28),
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => _showAnnouncementsDialog(context, state),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.ink2,
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.line),
                            ),
                            child: const Icon(Icons.notifications_none_outlined, color: AppColors.amber, size: 20),
                          ),
                        ),
                        const SizedBox(width: 12),
                        GestureDetector(
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen())),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.ink2,
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.line),
                              boxShadow: [
                                BoxShadow(color: AppColors.amber.withOpacity(0.1), blurRadius: 10),
                              ],
                            ),
                            child: const Icon(Icons.person_outline, color: AppColors.amber, size: 20),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 10),
                    Text(
                      "WELCOME BACK,",
                      style: GoogleFonts.jost(
                        color: AppColors.text2,
                        fontSize: 12,
                        letterSpacing: 2,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          profile?.username.toUpperCase() ?? "GUEST",
                          style: GoogleFonts.playfairDisplay(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        if (profile?.isPrime ?? false) ...[
                          const SizedBox(width: 12),
                          _buildPrimeBadge(),
                        ],
                      ],
                    ),
                    if (profile?.state != null && profile!.state!.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.location_on, color: AppColors.amber, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            profile.state!.toUpperCase(),
                            style: GoogleFonts.jost(
                              color: AppColors.text2,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 24),
                    
                    // Referral & Prime Card
                    _buildReferralCard(context, state),
                    
                    const SizedBox(height: 32),
                    
                    // Categories
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "CATEGORIES",
                          style: GoogleFonts.jost(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                          ),
                        ),
                        Text(
                          "VIEW ALL",
                          style: GoogleFonts.jost(
                            color: AppColors.amber,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),

            // Horizontal Categories List
            SliverToBoxAdapter(
              child: SizedBox(
                height: 100,
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  scrollDirection: Axis.horizontal,
                  itemCount: state.categories.length + 1,
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return _buildCategoryItem("all", "All", Icons.grid_view, state);
                    }
                    final cat = state.categories[index - 1];
                    return _buildCategoryItem(cat.name.toLowerCase(), cat.name, AppTheme.getCategoryIcon(cat.name), state);
                  },
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 32, 20, 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "FEATURED MERCHANTS",
                      style: GoogleFonts.jost(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const Icon(Icons.filter_list_rounded, color: AppColors.text2, size: 20),
                  ],
                ),
              ),
            ),

            // Merchants List
            if (state.isLoading)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator(color: AppColors.amber)),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _buildMerchantCard(state.merchants[index]),
                    childCount: state.merchants.length,
                  ),
                ),
              ),
            
            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ),
      ),
    );
  }

  Widget _buildPrimeBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.amber, Color(0xFFFF8C00)],
        ),
        borderRadius: BorderRadius.circular(6),
        boxShadow: [
          BoxShadow(color: AppColors.amber.withOpacity(0.3), blurRadius: 8),
        ],
      ),
      child: const Text(
        "PRIME",
        style: TextStyle(
          color: Colors.black,
          fontSize: 10,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildReferralCard(BuildContext context, AppState state) {
    final profile = state.profile;
    final bool isPrime = profile?.isPrime ?? false;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isPrime 
            ? [const Color(0xFF1C1810), const Color(0xFF0C0C11)]
            : [const Color(0xFF140E0E), const Color(0xFF0C0C11)],
        ),
        border: Border.all(
          color: isPrime ? AppColors.amber.withOpacity(0.3) : AppColors.line,
          width: 1,
        ),
        boxShadow: [
          if (isPrime) BoxShadow(color: AppColors.amber.withOpacity(0.05), blurRadius: 30, spreadRadius: 5),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "REFERRAL BALANCE",
                      style: GoogleFonts.jost(
                        color: AppColors.text2,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "₹${profile?.referralBalance.toStringAsFixed(0) ?? "0"}",
                      style: GoogleFonts.dmMono(
                        color: Colors.white,
                        fontSize: 38,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.line),
                  ),
                  child: Icon(
                    isPrime ? Icons.auto_awesome : Icons.card_giftcard,
                    color: AppColors.amber,
                    size: 24,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "TOTAL EARNED",
                        style: GoogleFonts.jost(color: AppColors.text2, fontSize: 9, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "₹${profile?.referralTotalEarned.toStringAsFixed(0) ?? "0"}",
                        style: GoogleFonts.dmMono(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "TOTAL SAVED",
                        style: GoogleFonts.jost(color: AppColors.text2, fontSize: 9, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "₹${state.totalSaved.toStringAsFixed(0)}",
                        style: GoogleFonts.dmMono(color: AppColors.amber, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                // Share Button
                IconButton(
                  onPressed: () {
                    final code = profile?.referralCode ?? "TBH000";
                    final text = "Join The Baron Club and save 5-40% at the finest merchants! Use my referral code: $code\nDownload the app now!";
                    Clipboard.setData(ClipboardData(text: text));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Referral message copied to clipboard!"), backgroundColor: AppColors.amber),
                    );
                  },
                  icon: const Icon(Icons.share, color: AppColors.text2, size: 20),
                  tooltip: "Share Referral Code",
                ),
                const SizedBox(width: 8),
                if (!isPrime)
                  ElevatedButton(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PrimeScreen())),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.amber,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 8,
                      shadowColor: AppColors.amber.withOpacity(0.4),
                    ),
                    child: const Text(
                      "JOIN PRIME",
                      style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 1),
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.amber.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.amber.withOpacity(0.2)),
                    ),
                    child: const Text(
                      "MEMBERSHIP ACTIVE",
                      style: TextStyle(color: AppColors.amber, fontWeight: FontWeight.bold, fontSize: 10),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showPrimePurchaseSheet(BuildContext context, AppState state) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: AppColors.ink2,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.line, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 32),
            Text("THE BARON CLUB", style: GoogleFonts.jost(color: AppColors.amber, fontWeight: FontWeight.bold, letterSpacing: 4)),
            const SizedBox(height: 12),
            Text("Upgrade to Prime", style: GoogleFonts.playfairDisplay(fontSize: 32, fontWeight: FontWeight.w900)),
            const SizedBox(height: 32),
            _buildBenefitItem(Icons.verified, "Exclusive Merchant Discounts"),
            _buildBenefitItem(Icons.stars, "Priority Support & Access"),
            _buildBenefitItem(Icons.card_giftcard, "Higher Referral Rewards"),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton(
                onPressed: () async {
                  Navigator.pop(context);
                  bool success = await state.buyPrimeSimulated();
                  if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Welcome to The Baron Club Prime!"), backgroundColor: AppColors.amber),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.amber,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                child: const Text("ACTIVATE NOW - ₹199", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
            const SizedBox(height: 16),
            const Text("Simulated Purchase for Demo", style: TextStyle(color: AppColors.text2, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildBenefitItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(icon, color: AppColors.amber, size: 20),
          const SizedBox(width: 16),
          Text(text, style: const TextStyle(fontSize: 16, color: AppColors.text)),
        ],
      ),
    );
  }

  Widget _buildCategoryItem(String slug, String label, IconData icon, AppState state) {
    bool isSelected = activeCategory == slug;
    return GestureDetector(
      onTap: () {
        setState(() => activeCategory = slug);
        state.filterMerchants(slug == 'all' ? null : slug);
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 5),
        width: 80,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.amber.withOpacity(0.08) : Colors.white.withOpacity(0.03),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: isSelected ? AppColors.amber.withOpacity(0.5) : AppColors.line),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isSelected ? AppColors.amber : AppColors.text2, size: 24),
            const SizedBox(height: 8),
            Text(label.toUpperCase(), style: TextStyle(color: isSelected ? Colors.white : AppColors.text2, fontSize: 9, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildMerchantCard(Merchant merchant) {
    final state = context.read<AppState>();
    String? distanceStr;
    if (state.devicePosition != null && merchant.latitude != null && merchant.longitude != null) {
      double dist = Geolocator.distanceBetween(
        state.devicePosition!.latitude,
        state.devicePosition!.longitude,
        merchant.latitude!,
        merchant.longitude!,
      );
      if (dist < 1000) {
        distanceStr = "${dist.toStringAsFixed(0)} m";
      } else {
        distanceStr = "${(dist / 1000).toStringAsFixed(1)} km";
      }
    }

    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => MerchantDetailScreen(merchant: merchant))),
      child: Container(
        margin: const EdgeInsets.only(bottom: 24),
        decoration: BoxDecoration(
          color: AppColors.ink2,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: AppColors.line),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: CachedNetworkImage(
                      imageUrl: merchant.cardImage,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(color: AppColors.ink2),
                      errorWidget: (context, url, error) => Container(color: AppColors.ink2, child: const Icon(Icons.image_not_supported)),
                    ),
                  ),
                ),
                Positioned(
                  top: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.amber.withOpacity(0.5)),
                    ),
                    child: Text(
                      "SAVE ${merchant.discountPercent}%",
                      style: const TextStyle(color: AppColors.amber, fontWeight: FontWeight.bold, fontSize: 10),
                    ),
                  ),
                ),
                Positioned(
                  bottom: -20,
                  left: 20,
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: AppColors.ink2,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.line, width: 2),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 10)],
                    ),
                    child: ClipOval(
                      child: CachedNetworkImage(
                        imageUrl: merchant.logo,
                        fit: BoxFit.cover,
                        errorWidget: (context, url, error) => const Icon(Icons.store, color: AppColors.amber),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          merchant.businessName,
                          style: GoogleFonts.playfairDisplay(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios, color: AppColors.text2, size: 14),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, color: AppColors.amber, size: 14),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          merchant.address,
                          style: GoogleFonts.jost(color: AppColors.text2, fontSize: 13),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (distanceStr != null) ...[
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.amber.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.amber.withOpacity(0.2)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.navigation_outlined, color: AppColors.amber, size: 10),
                              const SizedBox(width: 4),
                              Text(
                                distanceStr,
                                style: GoogleFonts.dmMono(color: AppColors.amber, fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAnnouncementsDialog(BuildContext context, AppState state) {
    showDialog(
      context: context,
      builder: (context) => FutureBuilder<List<dynamic>>(
        future: state.getAnnouncements(),
        builder: (context, snapshot) {
          return AlertDialog(
            backgroundColor: const Color(0xFF1A1A2E),
            title: const Row(
              children: [
                Icon(Icons.campaign_outlined, color: AppColors.amber),
                SizedBox(width: 12),
                Text("Announcements"),
              ],
            ),
            content: SizedBox(
              width: double.maxFinite,
              height: 400,
              child: snapshot.connectionState == ConnectionState.waiting
                ? const Center(child: CircularProgressIndicator(color: AppColors.amber))
                : snapshot.hasError
                  ? Center(child: Text("Error: ${snapshot.error}", style: const TextStyle(color: Colors.redAccent)))
                  : snapshot.data == null || snapshot.data!.isEmpty
                    ? const Center(child: Text("No new announcements", style: TextStyle(color: Colors.white24)))
                    : ListView.builder(
                        itemCount: snapshot.data!.length,
                        itemBuilder: (context, index) {
                          final a = snapshot.data![index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(a['title'] ?? "", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                const SizedBox(height: 8),
                                Text(a['message'] ?? "", style: const TextStyle(color: Colors.white70, fontSize: 13)),
                                const SizedBox(height: 8),
                                Text(a['created_at'].toString().split('T')[0], style: const TextStyle(color: Colors.white24, fontSize: 10)),
                              ],
                            ),
                          );
                        },
                      ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text("Close")),
            ],
          );
        },
      ),
    );
  }
}
