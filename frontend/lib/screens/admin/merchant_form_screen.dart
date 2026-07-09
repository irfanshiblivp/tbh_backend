import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../../core/app_theme.dart';
import '../../providers/app_state.dart';
import '../../models/models.dart';
import 'map_picker_screen.dart';

class MerchantFormScreen extends StatefulWidget {
  final Merchant? merchant;
  const MerchantFormScreen({super.key, this.merchant});

  @override
  State<MerchantFormScreen> createState() => _MerchantFormScreenState();
}

class _MerchantFormScreenState extends State<MerchantFormScreen> {
  final _formKey = GlobalKey<FormState>();

  // Text controllers
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _passwordController;
  late TextEditingController _confirmPasswordController;
  late TextEditingController _phoneController;
  late TextEditingController _discountController;
  late TextEditingController _addressController;
  late TextEditingController _descriptionController;
  late TextEditingController _latController;
  late TextEditingController _lngController;
  late TextEditingController _searchController;

  // Selected State
  String? _selectedCategory;
  String _status = 'active';
  XFile? _pickedImage;
  bool _isSaving = false;
  bool _showPassword = false;
  bool _showConfirmPassword = false;
  String _discountType = 'percentage';

  // Map state
  GoogleMapController? _mapController;
  LatLng _selectedLatLng = const LatLng(9.9857409, 76.3096248); // Default center: Kochi
  bool _mapHasError = false;
  bool _isGeocoding = false;
  List<Map<String, dynamic>> _searchResults = [];

  static const String _darkMapStyle = '''
  [
    {
      "elementType": "geometry",
      "stylers": [
        {
          "color": "#121214"
        }
      ]
    },
    {
      "elementType": "labels.text.fill",
      "stylers": [
        {
          "color": "#746855"
        }
      ]
    },
    {
      "elementType": "labels.text.stroke",
      "stylers": [
        {
          "color": "#24242f"
        }
      ]
    },
    {
      "featureType": "administrative.locality",
      "elementType": "labels.text.fill",
      "stylers": [
        {
          "color": "#d59563"
        }
      ]
    },
    {
      "featureType": "poi",
      "elementType": "labels.text.fill",
      "stylers": [
        {
          "color": "#d59563"
        }
      ]
    },
    {
      "featureType": "poi.park",
      "elementType": "geometry",
      "stylers": [
        {
          "color": "#181822"
        }
      ]
    },
    {
      "featureType": "poi.park",
      "elementType": "labels.text.fill",
      "stylers": [
        {
          "color": "#6b9a76"
        }
      ]
    },
    {
      "featureType": "road",
      "elementType": "geometry",
      "stylers": [
        {
          "color": "#1f1f28"
        }
      ]
    },
    {
      "featureType": "road",
      "elementType": "geometry.stroke",
      "stylers": [
        {
          "color": "#212130"
        }
      ]
    },
    {
      "featureType": "road",
      "elementType": "labels.text.fill",
      "stylers": [
        {
          "color": "#9ca2ad"
        }
      ]
    },
    {
      "featureType": "road.highway",
      "elementType": "geometry",
      "stylers": [
        {
          "color": "#2f2f3d"
        }
      ]
    },
    {
      "featureType": "road.highway",
      "elementType": "geometry.stroke",
      "stylers": [
        {
          "color": "#1f1f28"
        }
      ]
    },
    {
      "featureType": "road.highway",
      "elementType": "labels.text.fill",
      "stylers": [
        {
          "color": "#f3c159"
        }
      ]
    },
    {
      "featureType": "water",
      "elementType": "geometry",
      "stylers": [
        {
          "color": "#0d0d14"
        }
      ]
    },
    {
      "featureType": "water",
      "elementType": "labels.text.fill",
      "stylers": [
        {
          "color": "#515c6d"
        }
      ]
    },
    {
      "featureType": "water",
      "elementType": "labels.text.stroke",
      "stylers": [
        {
          "color": "#17263c"
        }
      ]
    }
  ]
  ''';

  @override
  void initState() {
    super.initState();
    final m = widget.merchant;
    
    _nameController = TextEditingController(text: m?.businessName ?? '');
    _emailController = TextEditingController(text: '');
    _passwordController = TextEditingController(text: '');
    _confirmPasswordController = TextEditingController(text: '');
    _phoneController = TextEditingController(text: '');
    _discountController = TextEditingController(text: m?.discountPercent.toString() ?? '50');
    _discountType = m?.discountType ?? 'percentage';
    _addressController = TextEditingController(text: m?.address ?? '');
    _descriptionController = TextEditingController(text: m?.description ?? '');
    _searchController = TextEditingController();

    if (m != null) {
      _status = m.status;
      if (m.latitude != null && m.longitude != null && m.latitude != 0.0 && m.longitude != 0.0) {
        _selectedLatLng = LatLng(m.latitude!, m.longitude!);
      }
      _latController = TextEditingController(text: _selectedLatLng.latitude.toStringAsFixed(6));
      _lngController = TextEditingController(text: _selectedLatLng.longitude.toStringAsFixed(6));
    } else {
      _selectedLatLng = const LatLng(0.0, 0.0);
      _latController = TextEditingController(text: '0.0');
      _lngController = TextEditingController(text: '0.0');
    }

    // Listeners to trigger reactive changes in live preview card
    _nameController.addListener(() => setState(() {}));
    _discountController.addListener(() => setState(() {}));
    _addressController.addListener(() => setState(() {}));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = Provider.of<AppState>(context, listen: false);
      if (state.categories.isNotEmpty) {
        setState(() {
          if (m != null && m.categoryName.isNotEmpty) {
            final hasCat = state.categories.any((c) => c.name == m.categoryName);
            _selectedCategory = hasCat ? m.categoryName : state.categories.first.name;
          } else {
            _selectedCategory = state.categories.first.name;
          }
        });
      }
    });  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _phoneController.dispose();
    _discountController.dispose();
    _addressController.dispose();
    _descriptionController.dispose();
    _latController.dispose();
    _lngController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _pickedImage = image;
      });
    }
  }

  Future<List<Map<String, dynamic>>> _geocodeAddress(String address) async {
    try {
      final state = Provider.of<AppState>(context, listen: false);
      String apiKey = "AIzaSyBgG_yjXNZCsTq3FZRhGgaa_MI61KCmLjo"; // Default fallback
      try {
        final keySetting = state.settings.firstWhere((s) => s.key == 'GOOGLE_MAPS_API_KEY');
        if (keySetting.value.isNotEmpty) {
          apiKey = keySetting.value;
        }
      } catch (_) {}

      final response = await http.get(Uri.parse(
        'https://maps.googleapis.com/maps/api/geocode/json?address=${Uri.encodeComponent(address)}&key=$apiKey'
      ));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'OK' && data['results'] != null) {
          final List results = data['results'];
          return results.map((result) {
            final loc = result['geometry']['location'];
            return {
              'lat': loc['lat'],
              'lng': loc['lng'],
              'address': result['formatted_address'] ?? '',
            };
          }).toList().cast<Map<String, dynamic>>();
        }
      }
    } catch (e) {
      // debugPrint("Geocode error: $e");
    }
    return [];
  }

  Future<void> _reverseGeocode(LatLng latLng) async {
    try {
      final state = Provider.of<AppState>(context, listen: false);
      String apiKey = "AIzaSyBgG_yjXNZCsTq3FZRhGgaa_MI61KCmLjo"; // Default fallback
      try {
        final keySetting = state.settings.firstWhere((s) => s.key == 'GOOGLE_MAPS_API_KEY');
        if (keySetting.value.isNotEmpty) {
          apiKey = keySetting.value;
        }
      } catch (_) {}

      final response = await http.get(Uri.parse(
        'https://maps.googleapis.com/maps/api/geocode/json?latlng=${latLng.latitude},${latLng.longitude}&key=$apiKey'
      ));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'OK' && data['results'] != null && data['results'].isNotEmpty) {
          final String formattedAddress = data['results'][0]['formatted_address'] ?? '';
          if (formattedAddress.isNotEmpty) {
            setState(() {
              _addressController.text = formattedAddress;
            });
          }
        }
      }
    } catch (_) {}
  }

  Widget _buildMiniMapPreview(AppState state) {
    final LatLng displayLatLng = (_selectedLatLng.latitude == 0.0 && _selectedLatLng.longitude == 0.0)
        ? const LatLng(9.9857409, 76.3096248)
        : _selectedLatLng;

    return Container(
      height: 200,
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.line),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Stack(
          children: [
            GoogleMap(
              key: ValueKey('${displayLatLng.latitude}_${displayLatLng.longitude}'),
              initialCameraPosition: CameraPosition(
                target: displayLatLng,
                zoom: 15,
              ),
              zoomControlsEnabled: false,
              myLocationButtonEnabled: false,
              compassEnabled: false,
              mapToolbarEnabled: false,
              rotateGesturesEnabled: false,
              scrollGesturesEnabled: false,
              tiltGesturesEnabled: false,
              zoomGesturesEnabled: false,
              onMapCreated: (controller) {
                try {
                  controller.setMapStyle(_darkMapStyle);
                } catch (_) {}
              },
              markers: {
                Marker(
                  markerId: const MarkerId('merchant_pin'),
                  position: displayLatLng,
                  icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
                ),
              },
            ),
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.2),
                      Colors.black.withValues(alpha: 0.6),
                    ],
                  ),
                ),
              ),
            ),
            Center(
              child: InkWell(
                onTap: () async {
                  final LatLng? result = await Navigator.push<LatLng>(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MapPickerScreen(
                        initialLocation: _selectedLatLng,
                      ),
                    ),
                  );
                  if (result != null) {
                    setState(() {
                      _selectedLatLng = result;
                      _latController.text = result.latitude.toStringAsFixed(6);
                      _lngController.text = result.longitude.toStringAsFixed(6);
                    });
                    _reverseGeocode(result);
                  }
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.amber,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.amber.withValues(alpha: 0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.map_outlined, color: Colors.black, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        "CHANGE LOCATION ON MAP",
                        style: GoogleFonts.jost(
                          color: Colors.black,
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }


  Future<void> _searchAddress() async {
    if (_searchController.text.trim().isEmpty) return;
    setState(() {
      _isGeocoding = true;
      _searchResults = [];
    });
    final results = await _geocodeAddress(_searchController.text.trim());
    setState(() {
      _isGeocoding = false;
      _searchResults = results;
    });

    if (results.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No matching locations found.")),
        );
      }
    } else if (results.length == 1) {
      _selectLocation(results.first);
    }
  }

  void _selectLocation(Map<String, dynamic> result) {
    setState(() {
      final double lat = result['lat'];
      final double lng = result['lng'];
      _selectedLatLng = LatLng(lat, lng);
      _latController.text = lat.toStringAsFixed(6);
      _lngController.text = lng.toStringAsFixed(6);
      _addressController.text = result['address'];
      _searchResults = [];
    });
  }

  void _onManualCoordsChanged() {
    final double? lat = double.tryParse(_latController.text);
    final double? lng = double.tryParse(_lngController.text);
    if (lat != null && lng != null) {
      setState(() {
        _selectedLatLng = LatLng(lat, lng);
      });
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    
    // Additional validation for Create mode
    if (widget.merchant == null) {
      if (_passwordController.text != _confirmPasswordController.text) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Passwords do not match!")),
        );
        return;
      }
    }

    setState(() => _isSaving = true);
    final state = Provider.of<AppState>(context, listen: false);

    try {
      http.MultipartFile? imageFile;
      if (_pickedImage != null) {
        final bytes = await _pickedImage!.readAsBytes();
        imageFile = http.MultipartFile.fromBytes(
          'card_image',
          bytes,
          filename: 'card_image.jpg',
          contentType: MediaType('image', 'jpeg'),
        );
      }

      if (widget.merchant == null) {
        // Create mode
        final postData = {
          'business_name': _nameController.text.trim(),
          'email': _emailController.text.trim(),
          'password': _passwordController.text.trim(),
          'phone': _phoneController.text.trim(),
          'category': _selectedCategory,
          'address': _addressController.text.trim(),
          'description': _descriptionController.text.trim(),
          'status': _status,
          'discount_percent': int.tryParse(_discountController.text.trim()) ?? 50,
          'discount_type': _discountType,
          'latitude': double.tryParse(_latController.text.trim()),
          'longitude': double.tryParse(_lngController.text.trim()),
        };
        await state.adminCreateMerchant(postData, imageFile: imageFile);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Merchant created successfully!")),
          );
          Navigator.pop(context);
        }
      } else {
        // Edit mode
        final postData = {
          'business_name': _nameController.text.trim(),
          'category': _selectedCategory,
          'address': _addressController.text.trim(),
          'description': _descriptionController.text.trim(),
          'status': _status,
          'discount_percent': int.tryParse(_discountController.text.trim()) ?? 50,
          'discount_type': _discountType,
          'latitude': double.tryParse(_latController.text.trim()),
          'longitude': double.tryParse(_lngController.text.trim()),
        };
        await state.updateMerchant(widget.merchant!.id, postData, imageFile: imageFile);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Merchant updated successfully!")),
          );
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e")),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }


  Widget _buildLiveCardPreview() {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: AppColors.ink2,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              child: _pickedImage != null
                  ? (kIsWeb
                      ? Image.network(_pickedImage!.path, fit: BoxFit.cover)
                      : Image.file(File(_pickedImage!.path), fit: BoxFit.cover))
                  : (widget.merchant != null && widget.merchant!.cardImage.isNotEmpty
                      ? Image.network(widget.merchant!.cardImage, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _placeholderImage())
                      : _placeholderImage()),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        _nameController.text.isEmpty ? "Business Name" : _nameController.text,
                        style: GoogleFonts.playfairDisplay(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.amber.withValues(alpha: 0.5)),
                      ),
                      child: Text(
                        _discountType == 'flat'
                            ? "SAVE ₹${_discountController.text.isEmpty ? '100' : _discountController.text}"
                            : "SAVE ${_discountController.text.isEmpty ? '50' : _discountController.text}%",
                        style: const TextStyle(color: AppColors.amber, fontWeight: FontWeight.bold, fontSize: 10),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined, color: AppColors.amber, size: 14),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        _addressController.text.isEmpty ? "No address specified yet" : _addressController.text,
                        style: GoogleFonts.jost(color: AppColors.text2, fontSize: 13),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeholderImage() {
    return Container(
      color: Colors.white.withValues(alpha: 0.04),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.image_outlined, color: Colors.white30, size: 48),
            const SizedBox(height: 8),
            Text("Card Preview Image Placeholder", style: GoogleFonts.jost(color: Colors.white30, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    IconData? prefixIcon,
    bool isObscured = false,
    bool isNumber = false,
    int maxLines = 1,
    String? Function(String?)? validator,
    Widget? suffix,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: GoogleFonts.jost(
              color: AppColors.text2,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.line),
            ),
            child: TextFormField(
              controller: controller,
              obscureText: isObscured,
              maxLines: maxLines,
              validator: validator,
              keyboardType: isNumber
                  ? const TextInputType.numberWithOptions(decimal: true, signed: true)
                  : TextInputType.text,
              style: GoogleFonts.jost(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: GoogleFonts.jost(color: Colors.white30, fontSize: 14),
                prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: AppColors.amber, size: 20) : null,
                suffixIcon: suffix,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final isCreate = widget.merchant == null;

    return Scaffold(
      backgroundColor: const Color(0xFF07070A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF07070A),
        elevation: 0,
        title: Text(
          isCreate ? "ADD NEW MERCHANT" : "EDIT MERCHANT",
          style: GoogleFonts.jost(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
            fontSize: 16,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          // Background gradients
          Positioned(
            top: -100,
            right: -50,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [AppColors.amber.withValues(alpha: 0.12), Colors.transparent],
                ),
              ),
            ),
          ),
          
          SafeArea(
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Live Card Preview Section
                    Text(
                      "LIVE CARD PREVIEW",
                      style: GoogleFonts.jost(
                        color: AppColors.text2,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildLiveCardPreview(),

                    // Card Image Picker
                    Text(
                      "MERCHANT CARD IMAGE",
                      style: GoogleFonts.jost(
                        color: AppColors.text2,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: _pickImage,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.03),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.line),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.cloud_upload_outlined, color: AppColors.amber, size: 20),
                            const SizedBox(width: 12),
                            Text(
                              _pickedImage != null ? "CHANGE SELECTED IMAGE" : "UPLOAD MERCHANT IMAGE",
                              style: GoogleFonts.jost(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                letterSpacing: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Section: Credentials (only in create mode)
                    if (isCreate) ...[
                      Text(
                        "ACCOUNT CREDENTIALS",
                        style: GoogleFonts.jost(
                          color: AppColors.amber,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildField(
                        controller: _emailController,
                        label: "Email Address",
                        hint: "merchant@example.com",
                        prefixIcon: Icons.email_outlined,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return "Email is required";
                          if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(v.trim())) {
                            return "Enter a valid email address";
                          }
                          return null;
                        },
                      ),
                      _buildField(
                        controller: _passwordController,
                        label: "Password",
                        hint: "Min. 8 characters",
                        prefixIcon: Icons.lock_outlined,
                        isObscured: !_showPassword,
                        validator: (v) {
                          if (v == null || v.isEmpty) return "Password is required";
                          if (v.length < 8) return "Password must be at least 8 characters";
                          return null;
                        },
                        suffix: IconButton(
                          icon: Icon(
                            _showPassword ? Icons.visibility_off : Icons.visibility,
                            color: Colors.white30,
                            size: 20,
                          ),
                          onPressed: () => setState(() => _showPassword = !_showPassword),
                        ),
                      ),
                      _buildField(
                        controller: _confirmPasswordController,
                        label: "Confirm Password",
                        hint: "Re-enter password",
                        prefixIcon: Icons.lock_outlined,
                        isObscured: !_showConfirmPassword,
                        validator: (v) {
                          if (v == null || v.isEmpty) return "Confirm password is required";
                          if (v != _passwordController.text) return "Passwords do not match";
                          return null;
                        },
                        suffix: IconButton(
                          icon: Icon(
                            _showConfirmPassword ? Icons.visibility_off : Icons.visibility,
                            color: Colors.white30,
                            size: 20,
                          ),
                          onPressed: () => setState(() => _showConfirmPassword = !_showConfirmPassword),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Section: Merchant Information
                    Text(
                      "MERCHANT INFORMATION",
                      style: GoogleFonts.jost(
                        color: AppColors.amber,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    _buildField(
                      controller: _nameController,
                      label: "Merchant Name",
                      hint: "Enter business name",
                      prefixIcon: Icons.business,
                      validator: (v) => v == null || v.trim().isEmpty ? "Merchant name is required" : null,
                    ),

                    if (isCreate) 
                      _buildField(
                        controller: _phoneController,
                        label: "Phone Number",
                        hint: "e.g. 9876543210",
                        prefixIcon: Icons.phone,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return "Phone number is required";
                          final digitsOnly = v.replaceAll(RegExp(r'\D'), '');
                          if (digitsOnly.length != 10) {
                            return "Phone number must be exactly 10 digits";
                          }
                          return null;
                        },
                      ),

                    // Category Dropdown
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "CATEGORY",
                          style: GoogleFonts.jost(
                            color: AppColors.text2,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.04),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.line),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButtonFormField<String>(
                              initialValue: _selectedCategory,
                              dropdownColor: const Color(0xFF1A1A2E),
                              style: GoogleFonts.jost(color: Colors.white, fontSize: 14),
                              decoration: const InputDecoration(border: InputBorder.none),
                              items: state.categories
                                  .map((c) => DropdownMenuItem(value: c.name, child: Text(c.name.toUpperCase())))
                                  .toList(),
                              onChanged: (val) => setState(() => _selectedCategory = val),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Status Dropdown
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "STATUS",
                          style: GoogleFonts.jost(
                            color: AppColors.text2,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.04),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.line),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButtonFormField<String>(
                              initialValue: _status,
                              dropdownColor: const Color(0xFF1A1A2E),
                              style: GoogleFonts.jost(color: Colors.white, fontSize: 14),
                              decoration: const InputDecoration(border: InputBorder.none),
                              items: const [
                                DropdownMenuItem(value: "active", child: Text("ACTIVE")),
                                DropdownMenuItem(value: "inactive", child: Text("INACTIVE")),
                              ],
                              onChanged: (val) => setState(() => _status = val!),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    const SizedBox(height: 20),

                    Text(
                      "DISCOUNT TYPE",
                      style: GoogleFonts.jost(
                        color: Colors.white60,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButtonFormField<String>(
                          initialValue: _discountType,
                          dropdownColor: const Color(0xFF1A1A2E),
                          style: GoogleFonts.jost(color: Colors.white, fontSize: 14),
                          decoration: const InputDecoration(border: InputBorder.none),
                          items: const [
                            DropdownMenuItem(value: "percentage", child: Text("PERCENTAGE DISCOUNT (%)")),
                            DropdownMenuItem(value: "flat", child: Text("FLAT AMOUNT DISCOUNT (₹)")),
                          ],
                          onChanged: (val) {
                            setState(() {
                              _discountType = val!;
                              if (_discountType == 'flat') {
                                if (int.tryParse(_discountController.text) == 50) {
                                  _discountController.text = '100';
                                }
                              } else {
                                if (int.tryParse(_discountController.text) == 100) {
                                  _discountController.text = '50';
                                }
                              }
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    _buildField(
                      controller: _discountController,
                      label: _discountType == 'flat' ? "Discount Amount (₹)" : "Discount Percentage (%)",
                      hint: _discountType == 'flat' ? "e.g. 150" : "e.g. 50",
                      prefixIcon: _discountType == 'flat' ? Icons.wallet_giftcard : Icons.percent,
                      isNumber: true,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return "Discount value is required";
                        final val = int.tryParse(v.trim());
                        if (val == null || val < 1) return "Enter a valid positive number";
                        if (_discountType == 'percentage' && val > 100) return "Percentage cannot exceed 100%";
                        return null;
                      },
                    ),

                    _buildField(
                      controller: _descriptionController,
                      label: "Description",
                      hint: "Brief merchant description...",
                      maxLines: 4,
                    ),

                    // Section: Location & Coordinates (Maps integration)
                    const SizedBox(height: 16),
                    Text(
                      "LOCATION & ADDRESS",
                      style: GoogleFonts.jost(
                        color: AppColors.amber,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 16),



                    // Interactive Google Map Picker Preview
                    _buildMiniMapPreview(state),

                    _buildField(
                      controller: _addressController,
                      label: "Full Address",
                      hint: "Enter shop address manually or drop a pin...",
                      maxLines: 3,
                      validator: (v) => v == null || v.trim().isEmpty ? "Address is required" : null,
                    ),

                    const SizedBox(height: 24),

                    // Submit Button
                    Container(
                      width: double.infinity,
                      height: 56,
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
                        onPressed: _isSaving ? null : _submitForm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          foregroundColor: Colors.black,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: _isSaving
                            ? const Center(child: CircularProgressIndicator(color: Colors.black))
                            : Text(
                                isCreate ? "CREATE MERCHANT" : "SAVE CHANGES",
                                style: GoogleFonts.jost(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 14,
                                  letterSpacing: 1.5,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 48),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
