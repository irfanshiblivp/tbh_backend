import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:frontend/core/app_theme.dart';
import '../providers/app_state.dart';
import '../models/models.dart';
import 'merchant_detail_screen.dart';
import 'package:geolocator/geolocator.dart';
import 'profile_screen.dart';
import '../widgets/premium_loading.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String activeCategory = 'all';
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  String _searchQuery = '';
  List<Map<String, dynamic>> _locationSuggestions = [];
  bool _showSuggestions = false;

  late PageController _pageController;
  Timer? _bannerTimer;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    _startBannerTimer();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkLocationService();
    });
  }

  Future<void> _checkLocationService() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Check if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showLocationDialog(
        title: "Location Services Disabled",
        message: "Please turn on Location Services in your settings to view nearby merchants.",
      );
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _showLocationDialog(
          title: "Location Permission Denied",
          message: "Please grant location permissions to view nearby merchants.",
        );
        return;
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      _showLocationDialog(
        title: "Location Permission Permanently Denied",
        message: "Location permissions are permanently denied. Please enable them in your app settings to view nearby merchants.",
        openSettings: true,
      );
      return;
    }

    if (mounted) {
      final state = Provider.of<AppState>(context, listen: false);
      await state.fetchLocationAndSort();
    }
  }

  void _showLocationDialog({
    required String title,
    required String message,
    bool openSettings = false,
  }) {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1A1A2E),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              const Icon(Icons.location_off, color: AppColors.amber),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.jost(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            message,
            style: GoogleFonts.jost(color: Colors.white70, fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                if (openSettings) {
                  await Geolocator.openAppSettings();
                } else {
                  await Geolocator.openLocationSettings();
                }
                // Recheck after returning
                Future.delayed(const Duration(seconds: 2), () {
                  _checkLocationService();
                });
              },
              child: Text(
                openSettings ? "OPEN APP SETTINGS" : "TURN ON LOCATION",
                style: const TextStyle(color: AppColors.amber, fontWeight: FontWeight.bold),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text(
                "RETRY",
                style: TextStyle(color: Colors.white54),
              ),
            ),
          ],
        );
      },
    );
  }


  void _startBannerTimer() {
    _bannerTimer?.cancel();
    _bannerTimer = Timer.periodic(const Duration(seconds: 3), (Timer timer) {
      if (!mounted) return;
      final state = context.read<AppState>();
      final bannersCount = state.heroBanners.length;
      if (bannersCount > 1 && _pageController.hasClients) {
        _currentPage = (_currentPage + 1) % bannersCount;
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _bannerTimer?.cancel();
    _pageController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _buildSuggestions(List<Merchant> merchants, String query) {
    if (query.trim().isEmpty) return [];
    final q = query.toLowerCase().trim();
    final Map<String, bool> suggestionsMap = {};
    for (final m in merchants) {
      if (m.city.isNotEmpty && m.city.toLowerCase().contains(q)) {
        suggestionsMap[m.city] = true;
      }
      if (m.state.isNotEmpty && m.state.toLowerCase().contains(q)) {
        suggestionsMap[m.state] = true;
      }
      if (m.businessName.toLowerCase().contains(q)) {
        suggestionsMap[m.businessName] = false;
      }
    }
    final sortedKeys = suggestionsMap.keys.toList()..sort();
    return sortedKeys.take(6).map((key) {
      return {
        'text': key,
        'isLocation': suggestionsMap[key]!,
      };
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final profile = state.profile;

    final rawMerchants = state.merchants;
    List<Merchant> filteredMerchants = List.from(rawMerchants);

    if (_searchQuery.trim().isNotEmpty) {
      final query = _searchQuery.toLowerCase().trim();
      
      List<Merchant> matches = [];
      List<Merchant> nonMatches = [];

      for (var m in rawMerchants) {
        final city = m.city.toLowerCase();
        final stateName = m.state.toLowerCase();
        final address = m.address.toLowerCase();
        final name = m.businessName.toLowerCase();
        
        if (city.contains(query) || stateName.contains(query) || address.contains(query) || name.contains(query)) {
          matches.add(m);
        } else {
          nonMatches.add(m);
        }
      }

      if (state.devicePosition != null) {
        int sortFn(Merchant a, Merchant b) {
          if (a.latitude == null || a.longitude == null) return 1;
          if (b.latitude == null || b.longitude == null) return -1;
          double distA = Geolocator.distanceBetween(
            state.devicePosition!.latitude,
            state.devicePosition!.longitude,
            a.latitude!,
            a.longitude!,
          );
          double distB = Geolocator.distanceBetween(
            state.devicePosition!.latitude,
            state.devicePosition!.longitude,
            b.latitude!,
            b.longitude!,
          );
          return distA.compareTo(distB);
        }
        matches.sort(sortFn);
        nonMatches.sort(sortFn);
      }

      filteredMerchants = [...matches, ...nonMatches];
    }

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
              backgroundColor: const Color(0xFF07070A).withValues(alpha: 0.95),
              elevation: 0,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppColors.amber.withValues(alpha: 0.12),
                        const Color(0xFF07070A),
                      ],
                    ),
                  ),
                ),
                titlePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                title: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Image.asset('res/images/logo_transparent.png', height: 40),
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
                                BoxShadow(color: AppColors.amber.withValues(alpha: 0.1), blurRadius: 10),
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
                    const SizedBox(height: 16),
                    // Search bar with suggestions
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.04),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: _showSuggestions ? AppColors.amber.withValues(alpha: 0.5) : AppColors.line,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: TextField(
                            controller: _searchController,
                            focusNode: _searchFocusNode,
                            style: GoogleFonts.jost(color: Colors.white, fontSize: 14),
                            onChanged: (val) {
                              final suggestions = _buildSuggestions(state.merchants, val);
                              setState(() {
                                _searchQuery = val;
                                _locationSuggestions = suggestions;
                                _showSuggestions = val.isNotEmpty && suggestions.isNotEmpty;
                              });
                            },
                            onTap: () {
                              if (_searchQuery.isNotEmpty && _locationSuggestions.isNotEmpty) {
                                setState(() => _showSuggestions = true);
                              }
                            },
                            onSubmitted: (_) => setState(() => _showSuggestions = false),
                            decoration: InputDecoration(
                              hintText: "Search location, city, state or shop...",
                              hintStyle: GoogleFonts.jost(color: Colors.white30, fontSize: 14),
                              prefixIcon: const Icon(Icons.search, color: AppColors.amber, size: 20),
                              suffixIcon: _searchQuery.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear, color: Colors.white30, size: 18),
                                      onPressed: () {
                                        _searchController.clear();
                                        setState(() {
                                          _searchQuery = '';
                                          _showSuggestions = false;
                                          _locationSuggestions = [];
                                        });
                                      },
                                    )
                                  : null,
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                          ),
                        ),
                        // Suggestion Dropdown
                        if (_showSuggestions && _locationSuggestions.isNotEmpty)
                          Container(
                            margin: const EdgeInsets.only(top: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1A1A2E),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppColors.amber.withValues(alpha: 0.3)),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.4),
                                  blurRadius: 16,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Column(
                              children: _locationSuggestions.asMap().entries.map((entry) {
                                final idx = entry.key;
                                final suggestion = entry.value;
                                final isLast = idx == _locationSuggestions.length - 1;
                                return InkWell(
                                  onTap: () {
                                    _searchController.text = suggestion['text'];
                                    setState(() {
                                      _searchQuery = suggestion['text'];
                                      _showSuggestions = false;
                                    });
                                    _searchFocusNode.unfocus();
                                  },
                                  borderRadius: BorderRadius.vertical(
                                    top: idx == 0 ? const Radius.circular(14) : Radius.zero,
                                    bottom: isLast ? const Radius.circular(14) : Radius.zero,
                                  ),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    decoration: BoxDecoration(
                                      border: isLast ? null : Border(
                                        bottom: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          suggestion['isLocation'] == true
                                              ? Icons.location_on_outlined
                                              : Icons.storefront,
                                          color: AppColors.amber,
                                          size: 16,
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            suggestion['text'],
                                            style: GoogleFonts.jost(
                                              color: Colors.white,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                        const Icon(Icons.north_west, color: Colors.white24, size: 14),
                                      ],
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    
                    _buildPromoBanners(context, state),
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
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => const ShimmerMerchantCard(),
                    childCount: 3,
                  ),
                ),
              )
            else if (filteredMerchants.isEmpty && _searchQuery.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                    decoration: BoxDecoration(
                      color: AppColors.ink2,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppColors.line),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.search_off_rounded, color: AppColors.amber.withValues(alpha: 0.5), size: 48),
                        const SizedBox(height: 16),
                        Text(
                          "No Merchants Found",
                          style: GoogleFonts.playfairDisplay(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "No shops found matching your search. Try searching another location or city.",
                          textAlign: TextAlign.center,
                          style: GoogleFonts.jost(color: AppColors.text2, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _buildMerchantCard(filteredMerchants[index]),
                    childCount: filteredMerchants.length,
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
          BoxShadow(color: AppColors.amber.withValues(alpha: 0.3), blurRadius: 8),
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

  Widget _buildPromoBanners(BuildContext context, AppState state) {
    final activeBanners = state.heroBanners;
    if (activeBanners.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 180,
      child: PageView.builder(
        controller: _pageController,
        onPageChanged: (index) {
          _currentPage = index;
        },
        itemCount: activeBanners.length,
        itemBuilder: (context, index) {
          final banner = activeBanners[index];
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.line),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: CachedNetworkImage(
                imageUrl: banner.imageUrl,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(color: AppColors.ink2),
                errorWidget: (context, url, error) => Container(color: AppColors.ink2),
              ),
            ),
          );
        },
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
          color: isSelected ? AppColors.amber.withValues(alpha: 0.08) : Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: isSelected ? AppColors.amber.withValues(alpha: 0.5) : AppColors.line),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isSelected ? AppColors.amber : AppColors.text2, size: 24),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: Text(
                label.toUpperCase(),
                textAlign: TextAlign.center,
                style: TextStyle(color: isSelected ? Colors.white : AppColors.text2, fontSize: 9, fontWeight: FontWeight.bold),
              ),
            ),
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
                      color: Colors.black.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.amber.withValues(alpha: 0.5)),
                    ),
                    child: Text(
                      merchant.saveBadgeText,
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
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 10)],
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
                            color: AppColors.amber.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.amber.withValues(alpha: 0.2)),
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
                              color: Colors.white.withValues(alpha: 0.05),
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
