import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../../core/app_theme.dart';
import '../../providers/app_state.dart';
import '../../models/models.dart';

class HeroBannerManagementScreen extends StatefulWidget {
  const HeroBannerManagementScreen({super.key});

  @override
  State<HeroBannerManagementScreen> createState() => _HeroBannerManagementScreenState();
}

class _HeroBannerManagementScreenState extends State<HeroBannerManagementScreen> {
  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final activeBanners = state.heroBanners;
    final isMobile = MediaQuery.of(context).size.width < 700;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 16,
              runSpacing: 12,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      "Hero Banner Management",
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "${activeBanners.length} STANDALONE HERO BANNERS ACTIVE ON HOMEPAGE",
                      style: const TextStyle(fontSize: 10, color: Colors.white30, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () => _showUploadBannerDialog(context, state),
                  icon: const Icon(Icons.add_photo_alternate_outlined, size: 16, color: Colors.black),
                  label: const Text(
                    "Upload New Banner",
                    style: TextStyle(color: Colors.black, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.amber,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: activeBanners.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.view_carousel_outlined, size: 48, color: Colors.white24),
                        const SizedBox(height: 16),
                        const Text("No active hero banners", style: TextStyle(color: Colors.white30, fontSize: 16)),
                        const SizedBox(height: 8),
                        const Text("Upload promo banners to display in the customer home slider", style: TextStyle(color: Colors.white24, fontSize: 12)),
                      ],
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: isMobile ? 1 : 2,
                      crossAxisSpacing: 20,
                      mainAxisSpacing: 20,
                      childAspectRatio: 1.8,
                    ),
                    itemCount: activeBanners.length,
                    itemBuilder: (context, index) {
                      final banner = activeBanners[index];
                      return _buildBannerCard(context, banner, state);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildBannerCard(BuildContext context, HeroBanner banner, AppState state) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            Positioned.fill(
              child: Image.network(
                banner.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: const Color(0xFF151521),
                  child: const Icon(Icons.image_not_supported_outlined, color: Colors.white24, size: 36),
                ),
              ),
            ),
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.05),
                      Colors.black.withValues(alpha: 0.4),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              top: 12,
              right: 12,
              child: Material(
                color: Colors.black.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(30),
                child: InkWell(
                  borderRadius: BorderRadius.circular(30),
                  onTap: () => _confirmDeleteBanner(context, banner, state),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: const Icon(
                      Icons.delete_outline_rounded,
                      color: Colors.redAccent,
                      size: 18,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteBanner(BuildContext context, HeroBanner banner, AppState state) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Delete Hero Banner?"),
        content: const Text("Are you sure you want to delete this hero banner? This will remove it from the customer homepage slider immediately."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            style: TextButton.styleFrom(
              foregroundColor: Colors.white70,
            ),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              try {
                await state.deleteHeroBanner(banner.id);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Hero banner deleted successfully!")),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Failed to delete banner: $e")),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }

  void _showUploadBannerDialog(BuildContext context, AppState state) {
    XFile? pickedImage;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF1A1A2E),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Text("Upload New Hero Banner"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Banner Image",
                  style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () async {
                    final picker = ImagePicker();
                    final image = await picker.pickImage(source: ImageSource.gallery);
                    if (image != null) {
                      setDialogState(() => pickedImage = image);
                    }
                  },
                  child: Container(
                    height: 160,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                    ),
                    child: pickedImage != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: kIsWeb
                                ? Image.network(pickedImage!.path, fit: BoxFit.cover)
                                : Image.file(File(pickedImage!.path), fit: BoxFit.cover),
                          )
                        : const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_a_photo, color: Colors.white30, size: 28),
                              SizedBox(height: 8),
                              Text("Tap to Select Banner Image", style: TextStyle(color: Colors.white30, fontSize: 11)),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
            ElevatedButton(
              onPressed: () async {
                if (pickedImage == null) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please select a banner image to upload!")));
                  return;
                }

                Navigator.pop(context);

                try {
                  http.MultipartFile? imageFile;
                  final bytes = await pickedImage!.readAsBytes();
                  imageFile = http.MultipartFile.fromBytes(
                    'image',
                    bytes,
                    filename: 'banner_image.jpg',
                    contentType: MediaType('image', 'jpeg'),
                  );

                  await state.uploadHeroBanner(imageFile);
                  
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Hero banner uploaded successfully!")),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Error uploading banner: $e")),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.amber, foregroundColor: Colors.black),
              child: const Text("Upload Banner"),
            ),
          ],
        ),
      ),
    );
  }
}
