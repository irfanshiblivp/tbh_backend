import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:frontend/core/app_theme.dart';
import 'package:frontend/providers/app_state.dart';
import 'package:frontend/models/models.dart';
import 'package:frontend/screens/merchant_detail_screen.dart';

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
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text("Categories", style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 22)),
        actions: [
          IconButton(
            onPressed: () => _showFilterSheet(context, state),
            icon: Icon(Icons.filter_list, color: state.selectedStateFilter != null || state.isNearMeFilter ? AppColors.amber : Colors.white),
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: Column(
        children: [
          SizedBox(
            height: 160,
            child: GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              scrollDirection: Axis.horizontal,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 1,
                mainAxisExtent: 100,
                mainAxisSpacing: 12,
              ),
              itemCount: state.categories.length,
              itemBuilder: (context, index) {
                final cat = state.categories[index];
                bool isSelected = activeCategory == cat.slug;
                return GestureDetector(
                  onTap: () {
                    setState(() => activeCategory = isSelected ? null : cat.slug);
                    state.filterMerchants(isSelected ? null : cat.slug);
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.amber.withOpacity(0.09) : Colors.white.withOpacity(0.045),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: isSelected ? AppColors.amber : Colors.white.withOpacity(0.09)),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.amber.withOpacity(0.14) : Colors.white.withOpacity(0.06),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(AppTheme.getCategoryIcon(cat.name), color: isSelected ? AppColors.amber : Colors.white54, size: 26),
                        ),
                        const SizedBox(height: 10),
                        Text(cat.name.toUpperCase(), style: TextStyle(color: isSelected ? AppColors.amber : Colors.white30, fontSize: 10, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(activeCategory == null ? "All Merchants" : "${activeCategory!.toUpperCase()} Merchants", style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                Text("${state.merchants.length} FOUND", style: const TextStyle(color: AppColors.text2, fontSize: 10)),
              ],
            ),
          ),
          
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: state.merchants.length,
              itemBuilder: (context, index) {
                final m = state.merchants[index];
                return _buildMerchantSmallCard(m);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMerchantSmallCard(Merchant m) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => MerchantDetailScreen(merchant: m))),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.045),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Row(
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.amber.withOpacity(0.1),
                borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
                child: CachedNetworkImage(
                  imageUrl: m.profilePhoto,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(color: Colors.grey[900]),
                  errorWidget: (context, url, error) => Container(
                    color: Colors.grey[900],
                    child: const Icon(Icons.store, color: Colors.white24, size: 20),
                  ),
                ),

              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(m.name, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 3),
                  Text(m.city, style: const TextStyle(color: AppColors.text2, fontSize: 10)),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.amber,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text("Prime ${m.discountPercentage}% Off", style: const TextStyle(color: Colors.black, fontSize: 9, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white24),
            const SizedBox(width: 10),
          ],
        ),
      ),
    );
  }

  void _showFilterSheet(BuildContext context, AppState state) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0F0F1A),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Filters", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      TextButton(
                        onPressed: () {
                          state.filterMerchants(activeCategory);
                          Navigator.pop(context);
                        },
                        child: const Text("Reset", style: TextStyle(color: Colors.white54)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text("State", style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: state.selectedStateFilter,
                        hint: const Text("Select State", style: TextStyle(color: Colors.white70)),
                        isExpanded: true,
                        dropdownColor: const Color(0xFF1A1A2E),
                        style: const TextStyle(color: Colors.white),
                        items: [
                          'Andhra Pradesh',
                          'Arunachal Pradesh',
                          'Assam',
                          'Bihar',
                          'Chhattisgarh',
                          'Goa',
                          'Gujarat',
                          'Haryana',
                          'Himachal Pradesh',
                          'Jharkhand',
                          'Karnataka',
                          'Kerala',
                          'Madhya Pradesh',
                          'Maharashtra',
                          'Manipur',
                          'Meghalaya',
                          'Mizoram',
                          'Nagaland',
                          'Odisha',
                          'Punjab',
                          'Rajasthan',
                          'Sikkim',
                          'Tamil Nadu',
                          'Telangana',
                          'Tripura',
                          'Uttar Pradesh',
                          'Uttarakhand',
                          'West Bengal',
                        ].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                        onChanged: (val) {
                          setModalState(() {});
                          state.filterMerchants(activeCategory, state: val, city: state.selectedCityFilter, nearMe: state.isNearMeFilter);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SwitchListTile(
                    title: const Text("Near Me", style: TextStyle(color: Colors.white, fontSize: 14)),
                    subtitle: const Text("Show merchants close to your current location", style: TextStyle(color: Colors.white38, fontSize: 11)),
                    value: state.isNearMeFilter,
                    activeColor: AppColors.amber,
                    onChanged: (val) {
                      setModalState(() {});
                      state.filterMerchants(activeCategory, state: state.selectedStateFilter, city: state.selectedCityFilter, nearMe: val);
                    },
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.amber,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text("Apply Filters", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
