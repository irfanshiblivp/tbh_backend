import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:frontend/core/app_theme.dart';
import 'package:frontend/providers/app_state.dart';
import 'package:frontend/models/models.dart';
import 'package:frontend/screens/merchant_detail_screen.dart';
import 'package:frontend/services/api_service.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  String? activeCategory;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return Scaffold(
      backgroundColor: const Color(0xFF07070A),
      body: Stack(
        children: [
          // Background ambient light orbs for premium visual depth
          Positioned(
            top: -100,
            right: -50,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [AppColors.amber.withValues(alpha: 0.18), Colors.transparent],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 100,
            left: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [AppColors.amber2.withValues(alpha: 0.08), Colors.transparent],
                ),
              ),
            ),
          ),
          
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Custom Premium Header Section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Categories",
                        style: GoogleFonts.playfairDisplay(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => _showFilterSheet(context, state),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: state.selectedStateFilter != null || state.isNearMeFilter 
                                  ? AppColors.amber 
                                  : Colors.white.withValues(alpha: 0.08),
                            ),
                          ),
                          child: Icon(
                            Icons.tune_outlined, 
                            color: state.selectedStateFilter != null || state.isNearMeFilter 
                                ? AppColors.amber 
                                : Colors.white70,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Horizontal Categories Selector List (Sleek Self-Sizing Pills)
                SizedBox(
                  height: 58,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    scrollDirection: Axis.horizontal,
                    itemCount: state.categories.length,
                    itemBuilder: (context, index) {
                      final cat = state.categories[index];
                      bool isSelected = activeCategory == cat.slug;
                      return GestureDetector(
                        onTap: () {
                          setState(() => activeCategory = isSelected ? null : cat.slug);
                          state.filterMerchants(isSelected ? null : cat.slug);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeInOut,
                          margin: const EdgeInsets.only(right: 10, top: 6, bottom: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                          decoration: BoxDecoration(
                            gradient: isSelected
                                ? const LinearGradient(
                                    colors: [AppColors.amber, AppColors.amber2],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  )
                                : LinearGradient(
                                    colors: [Colors.white.withValues(alpha: 0.05), Colors.white.withValues(alpha: 0.02)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(
                              color: isSelected 
                                  ? Colors.white.withValues(alpha: 0.15) 
                                  : Colors.white.withValues(alpha: 0.08),
                              width: 1,
                            ),
                            boxShadow: [
                              if (isSelected)
                                BoxShadow(
                                  color: AppColors.amber.withValues(alpha: 0.28),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                )
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                AppTheme.getCategoryIcon(cat.name), 
                                color: isSelected ? Colors.white : Colors.white60, 
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                cat.name.toUpperCase(),
                                style: GoogleFonts.jost(
                                  color: isSelected ? Colors.white : AppColors.text2, 
                                  fontSize: 11, 
                                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                  letterSpacing: 0.6,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                
                // Section Divider and Title Info Row
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        activeCategory == null 
                            ? "All Merchants" 
                            : "${activeCategory!.replaceAll('-', ' ').toUpperCase()} MERCHANTS", 
                        style: GoogleFonts.jost(
                          color: Colors.white70, 
                          fontSize: 12, 
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.5,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                        ),
                        child: Text(
                          "${state.merchants.length} FOUND", 
                          style: GoogleFonts.dmMono(
                            color: AppColors.amber2, 
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Vertical Merchants List with polished Squircles
                Expanded(
                  child: state.merchants.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.storefront_outlined, color: Colors.white24, size: 48),
                              const SizedBox(height: 12),
                              Text(
                                "No Merchants Found",
                                style: GoogleFonts.jost(color: Colors.white38, fontSize: 14),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                          physics: const BouncingScrollPhysics(),
                          itemCount: state.merchants.length,
                          itemBuilder: (context, index) {
                            final m = state.merchants[index];
                            return _buildMerchantSmallCard(m);
                          },
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMerchantSmallCard(Merchant m) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context, 
        MaterialPageRoute(builder: (_) => MerchantDetailScreen(merchant: m)),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.035),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06), width: 1.2),
        ),
        child: Row(
          children: [
            // Merchant Squircle Logo Container with fine details
            Container(
              width: 74,
              height: 74,
              decoration: BoxDecoration(
                color: AppColors.ink2,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: AppColors.amber.withValues(alpha: 0.18),
                  width: 1.5,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: CachedNetworkImage(
                  imageUrl: m.profilePhoto,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: AppColors.ink2,
                    child: const Center(
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.amber),
                      ),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: AppColors.ink2,
                    child: const Icon(Icons.storefront_outlined, color: Colors.white24, size: 24),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            
            // Merchant Info Texts
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    m.name, 
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.jost(
                      color: Colors.white, 
                      fontSize: 15, 
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, color: AppColors.amber2, size: 12),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          (m.city.isNotEmpty && m.state.isNotEmpty)
                              ? "${m.city}, ${m.state}".toUpperCase()
                              : m.address.toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.jost(
                            color: AppColors.text2, 
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  
                  // Premium Gradient Discount Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.amber, Color(0xFFFF8C00)],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.amber.withValues(alpha: 0.24),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        )
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.offline_bolt_outlined, color: Colors.white, size: 10),
                        const SizedBox(width: 4),
                        Text(
                          "PRIME ${m.discountPercentage}% OFF", 
                          style: GoogleFonts.dmMono(
                            color: Colors.white, 
                            fontSize: 9, 
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Custom Subtle Navigation Arrow
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.04),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.chevron_right, color: Colors.white38, size: 18),
            ),
            const SizedBox(width: 4),
          ],
        ),
      ),
    );
  }

  void _showFilterSheet(BuildContext context, AppState state) {
    final Future<List<Merchant>> merchantsFuture = ApiService().getMerchants();
    String? tempState = state.selectedStateFilter;
    String? tempCity = state.selectedCityFilter;
    bool tempNearMe = state.isNearMeFilter;
    bool showSuggestions = false;
    
    final initialText = tempCity != null && tempState != null
        ? "$tempCity, $tempState"
        : (tempState ?? tempCity ?? "");
    final TextEditingController locationController = TextEditingController(text: initialText);
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return FutureBuilder<List<Merchant>>(
          future: merchantsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Container(
                height: 200,
                decoration: const BoxDecoration(
                  color: AppColors.ink2,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: const Center(
                  child: CircularProgressIndicator(color: AppColors.amber),
                ),
              );
            }
            
            final merchants = snapshot.data ?? state.merchants;
            final Set<String> states = {};
            final Map<String, String> cityToState = {};
            for (var m in merchants) {
              if (m.state.isNotEmpty) {
                states.add(m.state.trim());
              }
              if (m.city.isNotEmpty) {
                cityToState[m.city.trim()] = m.state.trim();
              }
            }
            final List<_LocationSuggestion> allLocations = [];
            for (final s in states) {
              allLocations.add(_LocationSuggestion(name: s, type: 'state'));
            }
            cityToState.forEach((city, stateName) {
              allLocations.add(_LocationSuggestion(name: city, type: 'city', parentState: stateName));
            });
            
            return StatefulBuilder(
              builder: (context, setModalState) {
                final query = locationController.text.toLowerCase().trim();
                final suggestions = allLocations.where((loc) {
                  return loc.name.toLowerCase().contains(query) || 
                         loc.parentState.toLowerCase().contains(query);
                }).toList();
                
                return Container(
                  padding: EdgeInsets.only(
                    left: 28,
                    right: 28,
                    top: 28,
                    bottom: 28 + MediaQuery.of(context).viewInsets.bottom,
                  ),
                  decoration: const BoxDecoration(
                    color: AppColors.ink2,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                    border: Border(top: BorderSide(color: AppColors.line, width: 1)),
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "FILTER DIRECTORY", 
                              style: GoogleFonts.jost(
                                color: Colors.white, 
                                fontSize: 16, 
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.5,
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                state.filterMerchants(activeCategory);
                                Navigator.pop(context);
                              },
                              child: Text(
                                "RESET", 
                                style: GoogleFonts.jost(
                                  color: AppColors.amber2, 
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Text(
                          "SEARCH LOCATION (CITY/STATE)", 
                          style: GoogleFonts.jost(
                            color: AppColors.text2, 
                            fontSize: 10, 
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.black26,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                          ),
                          child: TextField(
                            controller: locationController,
                            style: GoogleFonts.jost(color: Colors.white, fontSize: 14),
                            onChanged: (val) {
                              setModalState(() {
                                showSuggestions = val.isNotEmpty;
                                if (val.isEmpty) {
                                  tempState = null;
                                  tempCity = null;
                                }
                              });
                            },
                            onTap: () {
                              setModalState(() {
                                if (locationController.text.isNotEmpty) {
                                  showSuggestions = true;
                                }
                              });
                            },
                            decoration: InputDecoration(
                              hintText: "Enter state or city...",
                              hintStyle: GoogleFonts.jost(color: Colors.white30, fontSize: 13),
                              prefixIcon: const Icon(Icons.search, color: AppColors.amber2, size: 18),
                              suffixIcon: locationController.text.isNotEmpty 
                                  ? IconButton(
                                      icon: const Icon(Icons.clear, color: Colors.white30, size: 16),
                                      onPressed: () {
                                        locationController.clear();
                                        setModalState(() {
                                          tempState = null;
                                          tempCity = null;
                                          showSuggestions = false;
                                        });
                                      },
                                    )
                                  : null,
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                        
                        // Suggestion List
                        if (showSuggestions && suggestions.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Container(
                            constraints: const BoxConstraints(maxHeight: 150),
                            decoration: BoxDecoration(
                              color: Colors.black38,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                            ),
                            child: ListView.builder(
                              shrinkWrap: true,
                              itemCount: suggestions.length,
                              itemBuilder: (context, index) {
                                final sug = suggestions[index];
                                final displayName = sug.type == 'city' && sug.parentState.isNotEmpty
                                    ? "${sug.name}, ${sug.parentState}"
                                    : sug.name;
                                return ListTile(
                                  dense: true,
                                  leading: Icon(
                                    sug.type == 'state' ? Icons.map_outlined : Icons.location_on_outlined,
                                    color: AppColors.amber2,
                                    size: 16,
                                  ),
                                  title: Text(
                                    displayName,
                                    style: GoogleFonts.jost(color: Colors.white, fontSize: 13),
                                  ),
                                  onTap: () {
                                    setModalState(() {
                                      if (sug.type == 'state') {
                                        tempState = sug.name;
                                        tempCity = null;
                                      } else {
                                        tempState = sug.parentState.isNotEmpty ? sug.parentState : null;
                                        tempCity = sug.name;
                                      }
                                      locationController.text = displayName;
                                      showSuggestions = false;
                                    });
                                  },
                                );
                              },
                            ),
                          ),
                        ],
                        
                        const SizedBox(height: 20),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.black26,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                          ),
                          child: SwitchListTile(
                            title: Text(
                              "NEAR ME", 
                              style: GoogleFonts.jost(
                                color: Colors.white, 
                                fontSize: 13, 
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                              ),
                            ),
                            subtitle: Text(
                              "Show merchants sorted by distance to your current location", 
                              style: GoogleFonts.jost(color: Colors.white38, fontSize: 11),
                            ),
                            value: tempNearMe,
                            activeThumbColor: AppColors.amber2,
                            onChanged: (val) {
                              setModalState(() {
                                tempNearMe = val;
                              });
                            },
                          ),
                        ),
                        const SizedBox(height: 32),
                        Container(
                          width: double.infinity,
                          height: 52,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [AppColors.amber, Color(0xFFFF8C00)],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.amber.withValues(alpha: 0.3),
                                blurRadius: 16,
                                offset: const Offset(0, 8),
                              )
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: () {
                              state.filterMerchants(
                                activeCategory, 
                                state: tempState, 
                                city: tempCity, 
                                nearMe: tempNearMe
                              );
                              Navigator.pop(context);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              foregroundColor: Colors.white,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            child: Text(
                              "APPLY FILTERS", 
                              style: GoogleFonts.jost(fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 1.2),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}

class _LocationSuggestion {
  final String name;
  final String type; // 'city' or 'state'
  final String parentState;
  
  _LocationSuggestion({required this.name, required this.type, this.parentState = ''});
}
