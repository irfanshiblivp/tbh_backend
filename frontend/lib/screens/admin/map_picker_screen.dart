import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:frontend/core/app_theme.dart';

import 'map_js_check.dart';

class MapPickerScreen extends StatefulWidget {
  final LatLng? initialLocation;
  const MapPickerScreen({super.key, this.initialLocation});

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  late LatLng _currentLocation;
  GoogleMapController? _mapController;
  late TextEditingController _latController;
  late TextEditingController _lngController;
  late FocusNode _latFocusNode;
  late FocusNode _lngFocusNode;
  bool _mapHasError = false;

  // Premium Custom Dark Mode styling for Google Maps
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
    // Default to New Delhi if no initial location is provided
    _currentLocation = widget.initialLocation ?? const LatLng(28.6139, 77.2090);
    _latController = TextEditingController(text: _currentLocation.latitude.toStringAsFixed(6));
    _lngController = TextEditingController(text: _currentLocation.longitude.toStringAsFixed(6));
    _latFocusNode = FocusNode();
    _lngFocusNode = FocusNode();
  }

  @override
  void dispose() {
    _latController.dispose();
    _lngController.dispose();
    _latFocusNode.dispose();
    _lngFocusNode.dispose();
    super.dispose();
  }

  void _updateLocationFromInputs() {
    final double? lat = double.tryParse(_latController.text);
    final double? lng = double.tryParse(_lngController.text);
    if (lat != null && lng != null) {
      setState(() {
        _currentLocation = LatLng(lat, lng);
      });
      try {
        _mapController?.animateCamera(
          CameraUpdate.newLatLng(_currentLocation),
        );
      } catch (e) {
        debugPrint("Error moving map camera: $e");
      }
    }
  }

  Widget _buildMapErrorFallback() {
    return Container(
      color: const Color(0xFF07070A),
      width: double.infinity,
      height: double.infinity,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.amber.withOpacity(0.05),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.amber.withOpacity(0.15)),
                ),
                child: const Icon(
                  Icons.map_outlined,
                  size: 64,
                  color: AppColors.amber,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                "MAP FAILED TO INITIALIZE",
                style: GoogleFonts.jost(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "Google Maps is currently unavailable. You can still input coordinates manually below.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.text2,
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMapView() {
    if (_mapHasError || !isGoogleMapsJsLoaded()) {
      if (!_mapHasError) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          setState(() {
            _mapHasError = true;
          });
        });
      }
      return _buildMapErrorFallback();
    }
    try {
      return GoogleMap(
        initialCameraPosition: CameraPosition(
          target: _currentLocation,
          zoom: 15.0,
        ),
        myLocationEnabled: true,
        myLocationButtonEnabled: false,
        zoomControlsEnabled: false,
        compassEnabled: false,
        mapToolbarEnabled: false,
        onMapCreated: (controller) {
          _mapController = controller;
          try {
            _mapController!.setMapStyle(_darkMapStyle);
          } catch (e) {
            debugPrint("Error setting custom map style: $e");
          }
        },
        onCameraMove: (position) {
          setState(() {
            _currentLocation = position.target;
            if (!_latFocusNode.hasFocus) {
              _latController.text = _currentLocation.latitude.toStringAsFixed(6);
            }
            if (!_lngFocusNode.hasFocus) {
              _lngController.text = _currentLocation.longitude.toStringAsFixed(6);
            }
          });
        },
      );
    } catch (e) {
      debugPrint("GoogleMap build crash caught: $e");
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          _mapHasError = true;
        });
      });
      return _buildMapErrorFallback();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF07070A),
      body: Stack(
        children: [
          // 1. Google Map view
          _buildMapView(),

          // 2. Fixed custom pin selector in the center of the screen
          if (!_mapHasError)
            const IgnorePointer(
              child: Center(
              child: Padding(
                padding: EdgeInsets.only(bottom: 36), // Align pin tip with exact center
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.location_on,
                      size: 44,
                      color: AppColors.amber,
                    ),
                    Icon(
                      Icons.circle_outlined,
                      size: 8,
                      color: AppColors.amber,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 3. Custom Header with close button
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.ink2.withOpacity(0.9),
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.line),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.4),
                          blurRadius: 10,
                        )
                      ],
                    ),
                    child: const Icon(Icons.close, color: Colors.white, size: 20),
                  ),
                ),
                Text(
                  "SELECT LOCATION",
                  style: GoogleFonts.jost(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                    fontSize: 16,
                    shadows: [
                      const Shadow(color: Colors.black, blurRadius: 10, offset: Offset(0, 2))
                    ],
                  ),
                ),
                const SizedBox(width: 44), // Balancer
              ],
            ),
          ),

          // 4. Coordinates Detail Card & Confirm Button at Bottom
          Positioned(
            bottom: 32,
            left: 24,
            right: 24,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.ink2.withOpacity(0.95),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: AppColors.line),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.5),
                    blurRadius: 20,
                  )
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "PINNED COORDINATES",
                    style: GoogleFonts.jost(
                      color: AppColors.text2,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "LATITUDE",
                              style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 9, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 2),
                            TextField(
                              controller: _latController,
                              focusNode: _latFocusNode,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                              style: GoogleFonts.dmMono(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                              onChanged: (v) => _updateLocationFromInputs(),
                              decoration: const InputDecoration(
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(vertical: 4),
                                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white12)),
                                focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.amber)),
                                border: UnderlineInputBorder(),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 24),
                      Container(width: 1, height: 32, color: AppColors.line),
                      const SizedBox(width: 24),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "LONGITUDE",
                              style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 9, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 2),
                            TextField(
                              controller: _lngController,
                              focusNode: _lngFocusNode,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                              style: GoogleFonts.dmMono(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                              onChanged: (v) => _updateLocationFromInputs(),
                              decoration: const InputDecoration(
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(vertical: 4),
                                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white12)),
                                focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.amber)),
                                border: UnderlineInputBorder(),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, _currentLocation),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.amber,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      child: Text(
                        "CONFIRM MERCHANT LOCATION",
                        style: GoogleFonts.jost(fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 1.5),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
