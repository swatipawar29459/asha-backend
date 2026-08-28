
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../theme/asha_theme.dart';
import '../services/api_service.dart';
import '../models/doctor.dart';

class FindDoctorScreen extends StatefulWidget {
  const FindDoctorScreen({
    super.key,
  });

  @override
  State<FindDoctorScreen> createState() =>
      _FindDoctorScreenState();
}

class _FindDoctorScreenState
    extends State<FindDoctorScreen> {
  final TextEditingController _addressController =
      TextEditingController();

  List<Doctor> results = [];

  LatLng? selectedLocation;

  bool loading = false;

  String? error;

  // ==================================================
  // CURRENT LOCATION
  // ==================================================

  Future<void> _useCurrentLocation() async {
    setState(() {
      loading = true;
      error = null;
      results = [];
    });

    try {
      // Check whether phone location/GPS is ON
      final serviceEnabled =
          await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        throw Exception(
          'Location services are disabled. Please turn on GPS/location on your phone.',
        );
      }

      // Check permission
      LocationPermission permission =
          await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission =
            await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        throw Exception(
          'Location permission denied.',
        );
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception(
          'Location permission permanently denied. Please enable location permission in phone Settings.',
        );
      }

      // Get phone's current GPS location
      // No locationSettings parameter because
      // your installed Geolocator version does not
      // accept it here.
      final position =
          await Geolocator.getCurrentPosition();

      print(
        'Current location: '
        '${position.latitude}, '
        '${position.longitude}',
      );

      final location = LatLng(
        position.latitude,
        position.longitude,
      );

      // Send latitude/longitude to Render Flask backend
      final doctors =
          await ApiService.findDoctors(
        position.latitude,
        position.longitude,
      );

      if (!mounted) return;

      setState(() {
        selectedLocation = location;
        results = doctors;
        loading = false;

        if (doctors.isEmpty) {
          error =
              'No nearby doctors or clinics were found.';
        }
      });
    } catch (e) {
      print(
        'Find doctor error: $e',
      );

      if (!mounted) return;

      setState(() {
        error = e
            .toString()
            .replaceFirst(
              'Exception: ',
              '',
            );

        loading = false;
      });
    }
  }

  // ==================================================
  // MANUAL ADDRESS SEARCH
  // ==================================================

  Future<void> _searchByAddress() async {
    final address =
        _addressController.text.trim();

    if (address.isEmpty) {
      setState(() {
        error =
            'Please enter a location.';
      });
      return;
    }

    setState(() {
      loading = true;
      error = null;
      results = [];
    });

    try {
      // Send address to Render Flask /geocode
      final location =
          await ApiService.geocodeAddress(
        address,
      );

      final lat =
          (location['lat'] as num).toDouble();

      final lng =
          (location['lng'] as num).toDouble();

      final searchedLocation =
          LatLng(lat, lng);

      // Search doctors around searched location
      final doctors =
          await ApiService.findDoctors(
        lat,
        lng,
      );

      if (!mounted) return;

      setState(() {
        selectedLocation =
            searchedLocation;

        results = doctors;

        loading = false;

        if (doctors.isEmpty) {
          error =
              'Location found, but no nearby doctors or clinics were found.';
        }
      });
    } catch (e) {
      print(
        'Address search error: $e',
      );

      if (!mounted) return;

      setState(() {
        error =
            'Could not find this location. Please try a more specific area or city.';

        loading = false;
      });
    }
  }

  // ==================================================
  // MAP
  // ==================================================

  Widget _buildMap() {
    if (selectedLocation == null) {
      return Container(
        height: 280,
        width: double.infinity,
        decoration: BoxDecoration(
          color: AshaColors.peach
              .withOpacity(0.25),
          borderRadius:
              BorderRadius.circular(20),
        ),
        child: const Center(
          child: Text(
            'Search for a location to see the map',
            style: TextStyle(
              fontSize: 13,
              fontWeight:
                  FontWeight.w500,
            ),
          ),
        ),
      );
    }

    return SizedBox(
      height: 280,
      width: double.infinity,
      child: ClipRRect(
        borderRadius:
            BorderRadius.circular(20),
        child: FlutterMap(
          options: MapOptions(
            initialCenter:
                selectedLocation!,
            initialZoom: 14,
          ),
          children: [
            // OpenStreetMap
            TileLayer(
              urlTemplate:
                  'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName:
                  'com.example.asha_app',
            ),

            // Location + doctor markers
            MarkerLayer(
              markers: [
                // User/search location
                Marker(
                  point:
                      selectedLocation!,
                  width: 50,
                  height: 50,
                  child: const Icon(
                    Icons.location_pin,
                    size: 42,
                    color: Colors.blue,
                  ),
                ),

                // Doctor locations
                ...results.map(
                  (doctor) => Marker(
                    point: LatLng(
                      doctor.lat,
                      doctor.lng,
                    ),
                    width: 45,
                    height: 45,
                    child: const Icon(
                      Icons.location_on,
                      size: 38,
                      color: Colors.red,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ==================================================
  // DOCTOR CARD
  // ==================================================

  Widget _doctorCard(
    Doctor doctor,
  ) {
    return AshaCard(
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color:
                  AshaColors.peach,
              borderRadius:
                  BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons
                  .medical_services_rounded,
            ),
          ),

          const SizedBox(
            width: 12,
          ),

          Expanded(
            child: Text(
              doctor.name,
              style:
                  const TextStyle(
                fontWeight:
                    FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==================================================
  // UI
  // ==================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor:
            Colors.transparent,
        elevation: 0,
        title: const Text(
          'Find a doctor',
        ),
      ),

      body: SafeArea(
        child: Padding(
          padding:
              const EdgeInsets.all(20),

          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,

            children: [
              const Text(
                'Find nearby doctors and clinics',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),

              const SizedBox(
                height: 14,
              ),

              // ==================================================
              // MANUAL SEARCH
              // ==================================================

              TextField(
                controller:
                    _addressController,

                decoration:
                    InputDecoration(
                  hintText:
                      'Enter your area or address',

                  prefixIcon:
                      const Icon(
                    Icons.search,
                  ),

                  suffixIcon:
                      IconButton(
                    icon:
                        const Icon(
                      Icons
                          .arrow_forward_rounded,
                    ),
                    onPressed:
                        loading
                            ? null
                            : _searchByAddress,
                  ),

                  filled: true,

                  border:
                      OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(
                      16,
                    ),
                    borderSide:
                        BorderSide.none,
                  ),
                ),

                onSubmitted:
                    (_) =>
                        _searchByAddress(),
              ),

              const SizedBox(
                height: 10,
              ),

              // ==================================================
              // CURRENT LOCATION
              // ==================================================

              SizedBox(
                width:
                    double.infinity,

                child:
                    OutlinedButton.icon(
                  onPressed:
                      loading
                          ? null
                          : _useCurrentLocation,

                  icon:
                      const Icon(
                    Icons.my_location,
                  ),

                  label:
                      const Text(
                    'Use my current location',
                  ),

                  style:
                      OutlinedButton
                          .styleFrom(
                    padding:
                        const EdgeInsets
                            .symmetric(
                      vertical: 14,
                    ),

                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(
                        16,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(
                height: 16,
              ),

              // ==================================================
              // LOADING
              // ==================================================

              if (loading)
                const Padding(
                  padding:
                      EdgeInsets.symmetric(
                    vertical: 12,
                  ),
                  child: Center(
                    child:
                        CircularProgressIndicator(),
                  ),
                ),

              // ==================================================
              // ERROR
              // ==================================================

              if (error != null)
                Padding(
                  padding:
                      const EdgeInsets.only(
                    bottom: 12,
                  ),
                  child: Text(
                    error!,
                    style:
                        const TextStyle(
                      fontSize: 13,
                    ),
                  ),
                ),

              // ==================================================
              // MAP
              // ==================================================

              _buildMap(),

              const SizedBox(
                height: 16,
              ),

              const Text(
                'Nearby doctors',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),

              const SizedBox(
                height: 10,
              ),

              // ==================================================
              // DOCTOR LIST
              // ==================================================

              Expanded(
                child: results.isEmpty
                    ? const Center(
                        child: Text(
                          'No nearby doctors found.',
                        ),
                      )
                    : ListView.builder(
                        itemCount:
                            results.length,

                        itemBuilder:
                            (_, index) {
                          return _doctorCard(
                            results[index],
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==================================================
  // DISPOSE
  // ==================================================

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }
}
