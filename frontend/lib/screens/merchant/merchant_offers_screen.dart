import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_theme.dart';
import '../../providers/app_state.dart';
import '../../models/models.dart';

class MerchantOffersScreen extends StatelessWidget {
  const MerchantOffersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    // Assuming profile contains merchant info including offers
    final merchant = state.merchantProfile;
    final offers = merchant?.offers ?? [];

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text("Manage Offers"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.add), onPressed: () {}),
        ],
      ),
      body: offers.isEmpty 
        ? _buildEmptyState()
        : ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: offers.length,
            itemBuilder: (context, index) => _buildOfferCard(offers[index]),
          ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.local_offer_outlined, size: 64, color: Colors.white10),
          const SizedBox(height: 16),
          const Text("No active offers", style: TextStyle(color: Colors.white24)),
        ],
      ),
    );
  }

  Widget _buildOfferCard(Offer offer) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AppColors.amber.withOpacity(0.1), borderRadius: BorderRadius.circular(14)),
                child: const Icon(Icons.percent, color: AppColors.amber, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(offer.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Text(offer.description, style: const TextStyle(color: Colors.white30, fontSize: 12)),
                  ],
                ),
              ),
              Switch(
                value: offer.isActive,
                onChanged: (val) {},
                activeColor: AppColors.amber,
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(onPressed: () {}, child: const Text("Edit", style: TextStyle(color: Colors.white54))),
              const SizedBox(width: 12),
              TextButton(onPressed: () {}, child: const Text("Delete", style: TextStyle(color: Colors.redAccent))),
            ],
          ),
        ],
      ),
    );
  }
}
