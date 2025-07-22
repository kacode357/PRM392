import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import 'package:user/constants/app_colors.dart';
import 'package:user/constants/app_fonts.dart';

class MapTab extends StatefulWidget {
  const MapTab({super.key});

  @override
  State<MapTab> createState() => _MapTabState();
}

class _MapTabState extends State<MapTab> {
  GoogleMapController? _mapController;
  LatLng? _currentLocation;
  LatLng? _destination;
  bool _isLoadingLocation = true;
  bool _isSearchLoading = false;
  bool _isRouting = false;
  final TextEditingController _searchController = TextEditingController();
  final List<Map<String, dynamic>> _predictions = [];
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  String? _sessionToken;
  Timer? _debounce;

  // API Keys (store securely in production, e.g., using .env)
  // LƯU Ý: Đây là các API key công khai, trong ứng dụng thật bạn cần bảo mật chúng tốt hơn.
  static const String _orsApiKey = '5b3ce3597851110001cf6248c89e354a30184841becfff9d2f7b69a4';
  static const String _openMapApiKey = 'kKuOnsjlYksE6rRQ2gk2pzGhky4jivXk';
  static const String _openMapBaseUrl = 'https://mapapis.openmap.vn/v1';

  static const CameraPosition _defaultPosition = CameraPosition(
    target: LatLng(10.7769, 106.7009), // TP.HCM
    zoom: 15.0,
  );

  @override
  void initState() {
    super.initState();
    _sessionToken = const Uuid().v4();
    _getCurrentLocation();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _mapController?.dispose();
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoadingLocation = true);

    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showSnackBar('Dịch vụ định vị bị tắt.');
      setState(() => _isLoadingLocation = false);
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _showSnackBar('Quyền truy cập vị trí bị từ chối.');
        setState(() => _isLoadingLocation = false);
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      _showSnackBar('Quyền truy cập vị trí bị từ chối vĩnh viễn.');
      setState(() => _isLoadingLocation = false);
      return;
    }

    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      final newLocation = LatLng(position.latitude, position.longitude);

      setState(() {
        _currentLocation = newLocation;
        _isLoadingLocation = false;
        _markers.add(
          Marker(
            markerId: const MarkerId('currentLocation'),
            position: newLocation,
            infoWindow: const InfoWindow(title: 'Vị trí của bạn'),
          ),
        );
      });

      _mapController?.animateCamera(CameraUpdate.newLatLngZoom(newLocation, 15.0));
    } catch (e) {
      _showSnackBar('Lỗi khi lấy vị trí: $e');
      setState(() => _isLoadingLocation = false);
    }
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (_searchController.text.trim().isNotEmpty) {
        _fetchAutocomplete(_searchController.text);
      } else {
        setState(() => _predictions.clear());
      }
    });
  }

  Future<void> _fetchAutocomplete(String input) async {
    setState(() => _isSearchLoading = true);
    try {
      final response = await http.get(
        Uri.parse('$_openMapBaseUrl/autocomplete').replace(
          queryParameters: {
            'apikey': _openMapApiKey,
            'input': input,
            'sessiontoken': _sessionToken,
          },
        ),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'OK') {
          setState(() => _predictions
            ..clear()
            ..addAll(List<Map<String, dynamic>>.from(data['predictions'])));
        } else {
          setState(() => _predictions.clear());
        }
      }
    } catch (e) {
      print('Autocomplete error: $e');
    } finally {
      setState(() => _isSearchLoading = false);
    }
  }

  Future<LatLng?> _getPlaceDetails(String placeId) async {
    setState(() => _isSearchLoading = true);
    try {
      final response = await http.get(
        Uri.parse('$_openMapBaseUrl/place').replace(
          queryParameters: {
            'apikey': _openMapApiKey,
            'ids': placeId,
            'sessiontoken': _sessionToken,
          },
        ),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['features']?.isNotEmpty ?? false) {
          final coords = data['features'][0]['geometry']['coordinates'];
          return LatLng(coords[1], coords[0]);
        }
      }
      return null;
    } catch (e) {
      print('Place details error: $e');
      return null;
    } finally {
      setState(() => _isSearchLoading = false);
    }
  }

  Future<void> _getRouteFromORS(LatLng start, LatLng end) async {
    setState(() => _isRouting = true);
    const url = 'https://api.openrouteservice.org/v2/directions/driving-car/geojson';
    final body = {
      'coordinates': [
        [start.longitude, start.latitude],
        [end.longitude, end.latitude],
      ],
    };

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Authorization': _orsApiKey,
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final coords = (data['features'][0]['geometry']['coordinates'] as List)
            .map((c) => LatLng(c[1], c[0]))
            .toList();

        setState(() {
          _polylines.clear();
          _polylines.add(
            Polyline(
              polylineId: const PolylineId('route'),
              points: coords,
              color: AppColors.lightPrimaryText,
              width: 4,
            ),
          );
        });

        _fitMapToCoordinates([start, end]);
      }
    } catch (e) {
      print('ORS error: $e');
    } finally {
      setState(() => _isRouting = false);
    }
  }

  void _fitMapToCoordinates(List<LatLng> coords) {
    if (_mapController == null || coords.length < 2) return;

    final bounds = LatLngBounds(
      southwest: LatLng(
        coords.map((c) => c.latitude).reduce((a, b) => a < b ? a : b),
        coords.map((c) => c.longitude).reduce((a, b) => a < b ? a : b),
      ),
      northeast: LatLng(
        coords.map((c) => c.latitude).reduce((a, b) => a > b ? a : b),
        coords.map((c) => c.longitude).reduce((a, b) => a > b ? a : b),
      ),
    );

    _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 150),
    );
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    if (_currentLocation != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(_currentLocation!, 15.0),
      );
    }
  }

  void _centerOnUser() {
    if (_currentLocation != null && _mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(_currentLocation!, 15.0),
      );
    }
  }

  void _showSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  Future<void> _handleSuggestionTap(Map<String, dynamic> prediction) async {
    setState(() {
      _predictions.clear();
      _searchController.text = prediction['description'];
    });

    final dest = await _getPlaceDetails(prediction['place_id']);
    if (dest != null && _currentLocation != null) {
      setState(() {
        _destination = dest;
        _markers
          ..removeWhere((m) => m.markerId.value == 'destination')
          ..add(
            Marker(
              markerId: const MarkerId('destination'),
              position: dest,
              infoWindow: const InfoWindow(title: 'Điểm đến'),
              icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueAzure,
              ),
            ),
          );
      });

      await _getRouteFromORS(_currentLocation!, dest);
    } else {
      _showSnackBar('Không thể lấy thông tin điểm đến.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: _defaultPosition,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            markers: _markers,
            polylines: _polylines,
            zoomControlsEnabled: true,
          ),
          Positioned(
            top: 50,
            left: 15,
            right: 15,
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.lightBackground,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.lightBlackText.withOpacity(0.2),
                        offset: const Offset(0, 2),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: TextField( // <-- Đây là TextField đã được cập nhật
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Nhập địa điểm...',
                      hintStyle: AppFonts.comfortaaRegular.copyWith(
                        color: AppColors.lightIcon,
                        fontSize: 16,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      // Sử dụng suffixIcon để hiển thị icon Clear hoặc Search
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                        icon: Icon(
                          Icons.clear,
                          color: AppColors.lightIcon,
                          size: 22,
                        ),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _predictions.clear());
                        },
                      )
                          : IconButton(
                        icon: Icon(
                          Icons.search, // Icon Search
                          color: AppColors.lightPrimaryText, // Màu icon Search
                          size: 22,
                        ),
                        onPressed: () {
                          // Trigger tìm kiếm khi nhấn icon nếu có text
                          if (_searchController.text.trim().isNotEmpty) {
                            _fetchAutocomplete(_searchController.text);
                          }
                        },
                      ),
                    ),
                    style: AppFonts.comfortaaRegular.copyWith(
                      color: AppColors.lightText,
                      fontSize: 16,
                    ),
                    onTap: () => setState(() {
                      _destination = null;
                      _markers.removeWhere(
                            (m) => m.markerId.value == 'destination',
                      );
                      _polylines.clear();
                    }),
                    onSubmitted: (value) { // Trigger tìm kiếm khi nhấn Enter/Done trên bàn phím
                      if (value.trim().isNotEmpty) {
                        _fetchAutocomplete(value);
                      }
                    },
                  ),
                ),
                if (_isSearchLoading)
                  const Padding(
                    padding: EdgeInsets.only(top: 10),
                    child: CircularProgressIndicator(
                      color: AppColors.lightTint,
                    ),
                  ),
                if (_predictions.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    decoration: BoxDecoration(
                      color: AppColors.lightBackground,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.lightBlackText.withOpacity(0.2),
                          offset: const Offset(0, 2),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    constraints: const BoxConstraints(maxHeight: 350),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: _predictions.length,
                            itemBuilder: (context, index) {
                              final prediction = _predictions[index];
                              return ListTile(
                                contentPadding: const EdgeInsets.all(15),
                                title: Text(
                                  prediction['structured_formatting']
                                  ['main_text'],
                                  style: AppFonts.comfortaaMedium.copyWith(
                                    fontSize: 15,
                                  ),
                                ),
                                subtitle: Text(
                                  prediction['structured_formatting']
                                  ['secondary_text'],
                                  style: AppFonts.comfortaaRegular.copyWith(
                                    fontSize: 13,
                                    color: AppColors.lightIcon,
                                  ),
                                ),
                                onTap: () => _handleSuggestionTap(prediction),
                                shape: Border(
                                  bottom: BorderSide(
                                    color: AppColors.lightGrayBackground,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        TextButton(
                          onPressed: () => setState(() => _predictions.clear()),
                          style: TextButton.styleFrom(
                            backgroundColor: AppColors.lightGrayBackground,
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.vertical(
                                bottom: Radius.circular(12),
                              ),
                            ),
                          ),
                          child: Text(
                            'Đóng',
                            style: AppFonts.comfortaaMedium.copyWith(
                              fontSize: 16,
                              color: AppColors.lightPrimaryText,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          if (_currentLocation != null)
            Positioned(
              bottom: 30,
              left: 20, // <-- Nút My Location đã dịch sang trái
              child: FloatingActionButton(
                backgroundColor: AppColors.lightBackground,
                elevation: 8,
                onPressed: _centerOnUser,
                child: Icon(
                  Icons.my_location,
                  color: AppColors.lightPrimaryText,
                  size: 24,
                ),
              ),
            ),
          if (_isRouting)
            Container(
              color: Colors.black.withOpacity(0.6),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(
                      color: AppColors.lightWhiteText,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Đang tìm đường...',
                      style: AppFonts.comfortaaMedium.copyWith(
                        color: AppColors.lightWhiteText,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (_isLoadingLocation && _currentLocation == null)
            const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}