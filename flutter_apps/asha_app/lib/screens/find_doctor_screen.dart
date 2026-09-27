import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../models/doctor.dart';
import '../services/api_service.dart';

class FindDoctorScreen extends StatefulWidget {
  const FindDoctorScreen({super.key});

  @override
  State<FindDoctorScreen> createState() => _FindDoctorScreenState();
}

class _FindDoctorScreenState extends State<FindDoctorScreen> {
  GoogleMapController? _mapController;

  Position? _currentPosition;

  List<Doctor> _doctors = <Doctor>[];
  Set<Marker> _markers = <Marker>{};

  bool _loading = true;
  bool _searching = false;

  String? _errorMessage;

  final TextEditingController _searchController =
      TextEditingController();

  static const LatLng _defaultLocation = LatLng(
    19.0760,
    72.8777,
  );

  @override
  void initState() {
    super.initState();
    _loadCurrentLocation();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  // ============================================================
  // LOCATION
  // ============================================================

  Future<void> _loadCurrentLocation() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _errorMessage = null;
      });
    }

    try {
      final bool serviceEnabled =
          await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        throw Exception(
          'Location services are disabled. Please enable location.',
        );
      }

      LocationPermission permission =
          await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        throw Exception(
          'Location permission was denied.',
        );
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception(
          'Location permission is permanently denied. '
          'Please enable it from Settings.',
        );
      }

      final Position position =
    await Geolocator.getCurrentPosition(
  desiredAccuracy: LocationAccuracy.high,
);

      if (!mounted) return;

      setState(() {
        _currentPosition = position;
      });

      await _loadDoctors(
        position.latitude,
        position.longitude,
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _searching = false;
        _errorMessage = _cleanError(e);
      });
    }
  }

  // ============================================================
  // FIND DOCTORS
  // ============================================================

  Future<void> _loadDoctors(
    double latitude,
    double longitude,
  ) async {
    if (!mounted) return;

    setState(() {
      _searching = true;
      _errorMessage = null;
    });

    try {
      final List<Doctor> doctors =
          await ApiService.findDoctors(
        latitude: latitude,
        longitude: longitude,
        radius: 5000,
      );

      if (!mounted) return;

      setState(() {
        _doctors = doctors;
        _markers = _createMarkers(doctors);
        _loading = false;
        _searching = false;
      });

      await _moveCamera(
        latitude,
        longitude,
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _searching = false;
        _errorMessage = _cleanError(e);
      });
    }
  }

  // ============================================================
  // MARKERS
  // ============================================================

  Set<Marker> _createMarkers(
    List<Doctor> doctors,
  ) {
    return doctors.map((Doctor doctor) {
      return Marker(
        markerId: MarkerId(
          doctor.id.isNotEmpty
              ? doctor.id
              : '${doctor.latitude}_${doctor.longitude}',
        ),
        position: LatLng(
          doctor.latitude,
          doctor.longitude,
        ),
        infoWindow: InfoWindow(
          title: doctor.name,
          snippet:
              doctor.address ?? 'Healthcare facility',
        ),
        onTap: () {
          _showDoctorDetails(doctor);
        },
      );
    }).toSet();
  }

  // ============================================================
  // MAP CAMERA
  // ============================================================

  Future<void> _moveCamera(
    double latitude,
    double longitude,
  ) async {
    final GoogleMapController? controller =
        _mapController;

    if (controller == null) return;

    await controller.animateCamera(
      CameraUpdate.newLatLngZoom(
        LatLng(latitude, longitude),
        14,
      ),
    );
  }

  // ============================================================
  // SEARCH ADDRESS
  // ============================================================

  Future<void> _searchAddress() async {
    final String address =
        _searchController.text.trim();

    if (address.isEmpty) {
      return;
    }

    FocusScope.of(context).unfocus();

    if (mounted) {
      setState(() {
        _searching = true;
        _errorMessage = null;
      });
    }

    try {
      final Map<String, dynamic>? result =
          await ApiService.geocodeAddress(address);

      if (result == null) {
        throw Exception(
          'Location not found. Please try another address.',
        );
      }

      final double? latitude =
          (result['latitude'] as num?)?.toDouble();

      final double? longitude =
          (result['longitude'] as num?)?.toDouble();

      if (latitude == null || longitude == null) {
        throw Exception(
          'Could not get coordinates for this location.',
        );
      }

      await _loadDoctors(
        latitude,
        longitude,
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _searching = false;
        _errorMessage = _cleanError(e);
      });
    }
  }

  // ============================================================
  // CURRENT LOCATION
  // ============================================================

  Future<void> _goToCurrentLocation() async {
    if (_currentPosition == null) {
      await _loadCurrentLocation();
      return;
    }

    final double latitude =
        _currentPosition!.latitude;
    final double longitude =
        _currentPosition!.longitude;

    await _moveCamera(
      latitude,
      longitude,
    );

    await _loadDoctors(
      latitude,
      longitude,
    );
  }

  // ============================================================
  // DOCTOR DETAILS
  // ============================================================

  void _showDoctorDetails(
    Doctor doctor,
  ) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return _doctorBottomSheet(doctor);
      },
    );
  }

  Widget _doctorBottomSheet(
    Doctor doctor,
  ) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        20,
        12,
        20,
        24,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(28),
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 45,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius:
                      BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD8754E)
                        .withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    doctor.type == 'hospital'
                        ? Icons.local_hospital
                        : Icons.medical_services,
                    color: const Color(0xFFD8754E),
                    size: 28,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        doctor.name,
                        style: const TextStyle(
                          fontSize: 19,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        doctor.type
                            .replaceAll('_', ' ')
                            .toUpperCase(),
                        style: TextStyle(
                          fontSize: 12,
                          color:
                              Colors.grey.shade600,
                          fontWeight:
                              FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            if (doctor.address != null) ...[
              Row(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.location_on_outlined,
                    size: 21,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      doctor.address!,
                      style: const TextStyle(
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
            if (doctor.rating != null) ...[
              Row(
                children: [
                  const Icon(
                    Icons.star,
                    color: Colors.amber,
                    size: 20,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    doctor.rating!
                        .toStringAsFixed(1),
                    style: const TextStyle(
                      fontWeight:
                          FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
            if (doctor.isOpen != null)
              Row(
                children: [
                  Icon(
                    doctor.isOpen!
                        ? Icons.check_circle
                        : Icons.cancel,
                    color: doctor.isOpen!
                        ? Colors.green
                        : Colors.red,
                    size: 20,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    doctor.isOpen!
                        ? 'Open now'
                        : 'Closed',
                    style: const TextStyle(
                      fontWeight:
                          FontWeight.w600,
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _loadPlaceDetails(doctor);
                },
                icon: const Icon(
                  Icons.info_outline,
                ),
                label: const Text(
                  'View Details',
                ),
                style:
                    ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(
                    vertical: 14,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // PLACE DETAILS
  // ============================================================

  Future<void> _loadPlaceDetails(
    Doctor doctor,
  ) async {
    try {
      final DoctorDetails? details =
          await ApiService.getDoctorDetails(
        doctor.id,
      );

      if (!mounted) return;

      if (details == null) {
        ScaffoldMessenger.of(context)
            .showSnackBar(
          const SnackBar(
            content: Text(
              'No additional details available.',
            ),
          ),
        );
        return;
      }

      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (BuildContext context) {
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius:
                  BorderRadius.vertical(
                top: Radius.circular(28),
              ),
            ),
            child: SafeArea(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      doctor.name,
                      style: const TextStyle(
                        fontSize: 21,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 18),
                    if (details.address != null)
                      _detailRow(
                        Icons.location_on_outlined,
                        details.address!,
                      ),
                    if (details.phone != null)
                      _detailRow(
                        Icons.phone_outlined,
                        details.phone!,
                      ),
                    if (details.website != null)
                      _detailRow(
                        Icons.language,
                        details.website!,
                      ),
                    if (details.rating != null)
                      _detailRow(
                        Icons.star,
                        details.rating!
                            .toStringAsFixed(1),
                      ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child:
                            const Text('Close'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'Could not load details: ${_cleanError(e)}',
          ),
        ),
      );
    }
  }

  Widget _detailRow(
    IconData icon,
    String text,
  ) {
    return Padding(
      padding:
          const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 21,
            color: const Color(0xFFD8754E),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ERROR CLEANUP
  // ============================================================

  String _cleanError(Object error) {
    return error
        .toString()
        .replaceFirst('Exception: ', '')
        .trim();
  }

  // ============================================================
  // UI
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final LatLng initialPosition =
        _currentPosition != null
            ? LatLng(
                _currentPosition!.latitude,
                _currentPosition!.longitude,
              )
            : _defaultLocation;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Find a Doctor',
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition:
                CameraPosition(
              target: initialPosition,
              zoom: 13,
            ),
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            compassEnabled: true,
            markers: _markers,
            onMapCreated:
                (GoogleMapController controller) {
              _mapController = controller;

              if (_currentPosition != null) {
                _moveCamera(
                  _currentPosition!.latitude,
                  _currentPosition!.longitude,
                );
              }
            },
          ),

          // SEARCH BAR
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Material(
              elevation: 5,
              borderRadius:
                  BorderRadius.circular(16),
              child: TextField(
                controller: _searchController,
                textInputAction:
                    TextInputAction.search,
                onSubmitted: (_) =>
                    _searchAddress(),
                decoration: InputDecoration(
                  hintText:
                      'Search an area or address',
                  prefixIcon:
                      const Icon(Icons.search),
                  suffixIcon: _searching
                      ? const Padding(
                          padding:
                              EdgeInsets.all(14),
                          child: SizedBox(
                            width: 18,
                            height: 18,
                            child:
                                CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          ),
                        )
                      : IconButton(
                          icon: const Icon(
                            Icons.arrow_forward,
                          ),
                          onPressed:
                              _searchAddress,
                        ),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(16),
                    borderSide:
                        BorderSide.none,
                  ),
                ),
              ),
            ),
          ),

          // CURRENT LOCATION
          Positioned(
            right: 16,
            bottom: 220,
            child: FloatingActionButton(
              heroTag: 'currentLocation',
              mini: true,
              onPressed:
                  _goToCurrentLocation,
              child: const Icon(
                Icons.my_location,
              ),
            ),
          ),

          // LOADING
          if (_loading)
            const Center(
              child:
                  CircularProgressIndicator(),
            ),

          // ERROR
          if (_errorMessage != null &&
              !_loading)
            Positioned(
              left: 16,
              right: 16,
              bottom: 25,
              child: Card(
                elevation: 5,
                child: Padding(
                  padding:
                      const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: Colors.red,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                        ),
                      ),
                      IconButton(
                        onPressed:
                            _loadCurrentLocation,
                        icon: const Icon(
                          Icons.refresh,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // RESULTS COUNT
          if (!_loading &&
              _errorMessage == null)
            Positioned(
              left: 16,
              right: 16,
              bottom: 25,
              child: Card(
                elevation: 5,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.local_hospital,
                        color:
                            const Color(0xFFD8754E),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          '${_doctors.length} healthcare facilities found nearby',
                          style:
                              const TextStyle(
                            fontWeight:
                                FontWeight.w600,
                          ),
                        ),
                      ),
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
