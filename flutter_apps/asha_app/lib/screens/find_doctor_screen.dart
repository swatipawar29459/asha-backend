
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

  // ============================================================
  // CURRENT LOCATION
  // ============================================================

  Future<void> _useCurrentLocation() async {
    if (loading) return;

    setState(() {
      loading = true;
      error = null;
      results = [];
      selectedLocation = null;
    });

    try {
      final serviceEnabled =
          await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        throw Exception(
          'Location services are disabled. Please turn on GPS/location.',
        );
      }

      LocationPermission permission =
          await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission =
            await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        throw Exception(
          'Location permission denied. Please allow location access.',
        );
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception(
          'Location permission is permanently denied. Please enable it from phone Settings.',
        );
      }

      final position =
    await Geolocator.getCurrentPosition();

      debugPrint(
        'Current location: '
        '${position.latitude}, ${position.longitude}',
      );

      final location = LatLng(
        position.latitude,
        position.longitude,
      );

      if (!mounted) return;

      setState(() {
        selectedLocation = location;
      });

      // ----------------------------------------------------------
      // FETCH NEARBY HEALTHCARE
      // ----------------------------------------------------------

      final doctors =
          await ApiService.findDoctors(
        position.latitude,
        position.longitude,
        type: '',
      );

      if (!mounted) return;

      setState(() {
        results = doctors;
        loading = false;

        if (doctors.isEmpty) {
          error =
              'No nearby medical facilities were found.';
        }
      });
    } catch (e) {
      debugPrint(
        'Find doctor error: $e',
      );

      if (!mounted) return;

      setState(() {
        loading = false;

        error = e
            .toString()
            .replaceFirst(
              'Exception: ',
              '',
            );
      });
    }
  }

  // ============================================================
  // MANUAL ADDRESS SEARCH
  // ============================================================

  Future<void> _searchByAddress() async {
    final address =
        _addressController.text.trim();

    if (address.isEmpty) {
      setState(() {
        error = 'Please enter a location.';
      });
      return;
    }

    if (loading) return;

    FocusScope.of(context).unfocus();

    setState(() {
      loading = true;
      error = null;
      results = [];
      selectedLocation = null;
    });

    try {
      debugPrint(
        'Searching address: $address',
      );

      final location =
          await ApiService.geocodeAddress(
        address,
      );

      final lat =
          (location['lat'] as num).toDouble();

      final lng =
          (location['lng'] as num).toDouble();

      debugPrint(
        'Geocoded location: $lat, $lng',
      );

      final searchedLocation =
          LatLng(lat, lng);

      if (!mounted) return;

      setState(() {
        selectedLocation =
            searchedLocation;
      });

      // ----------------------------------------------------------
      // FETCH NEARBY HEALTHCARE
      // ----------------------------------------------------------

      final doctors =
          await ApiService.findDoctors(
        lat,
        lng,
        type: '',
      );

      if (!mounted) return;

      setState(() {
        results = doctors;
        loading = false;

        if (doctors.isEmpty) {
          error =
              'Location found, but no nearby medical facilities were found.';
        }
      });
    } catch (e) {
      debugPrint(
        'Address search error: $e',
      );

      if (!mounted) return;

      setState(() {
        loading = false;

        error =
            'Could not find this location. Please try a more specific area or city.';
      });
    }
  }

  // ============================================================
  // MAP
  // ============================================================

  Widget _buildMap() {
    if (selectedLocation == null) {
      return Container(
        height: 280,
        width: double.infinity,
        decoration: BoxDecoration(
          color:
              AshaColors.peach.withOpacity(0.25),
          borderRadius:
              BorderRadius.circular(20),
        ),
        child: const Center(
          child: Text(
            'Search for a location to see the map',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
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
            TileLayer(
              urlTemplate:
                  'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName:
                  'com.example.asha_app',
            ),

            // ----------------------------------------------------
            // MARKERS
            // ----------------------------------------------------

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

                // Healthcare facilities
                ...results
                    .where(
                      (doctor) =>
                          doctor.lat != 0 &&
                          doctor.lng != 0,
                    )
                    .map(
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

            const RichAttributionWidget(
              attributions: [
                TextSourceAttribution(
                  'OpenStreetMap contributors',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // FACILITY CARD
  // ============================================================

  Widget _doctorCard(
    Doctor doctor,
  ) {
    IconData icon;

    final type =
        doctor.type.toLowerCase();

    if (type == 'hospital') {
      icon =
          Icons.local_hospital_rounded;
    } else if (type == 'clinic') {
      icon =
          Icons.medical_services_rounded;
    } else {
      icon =
          Icons.health_and_safety_rounded;
    }

    return Padding(
      padding:
          const EdgeInsets.only(bottom: 10),
      child: AshaCard(
        child: Row(
          crossAxisAlignment:
              CrossAxisAlignment.start,
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
              child: Icon(
                icon,
                color:
                    AshaColors.coral,
              ),
            ),

            const SizedBox(
              width: 12,
            ),

            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    doctor.name,
                    style:
                        const TextStyle(
                      fontWeight:
                          FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),

                  const SizedBox(
                    height: 5,
                  ),

                  if (doctor.address
                      .isNotEmpty)
                    Text(
                      doctor.address,
                      maxLines: 2,
                      overflow:
                          TextOverflow.ellipsis,
                      style:
                          TextStyle(
                        fontSize: 11,
                        color:
                            AshaColors.slate,
                      ),
                    ),

                  if (doctor.openingHours !=
                      null) ...[
                    const SizedBox(
                      height: 5,
                    ),
                    Text(
                      doctor.openingHours!,
                      style:
                          TextStyle(
                        fontSize: 10,
                        color:
                            AshaColors.slate,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // UI
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor:
            Colors.transparent,
        elevation: 0,
        title:
            const Text('Find a doctor'),
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
                'Find nearby doctors, clinics and hospitals',
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
              // ADDRESS SEARCH
              // ==================================================

              TextField(
                controller:
                    _addressController,

                textInputAction:
                    TextInputAction.search,

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
                height: 12,
              ),

              // ==================================================
              // LOADING
              // ==================================================

              if (loading)
                const Padding(
                  padding:
                      EdgeInsets.symmetric(
                    vertical: 8,
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
                Container(
                  width:
                      double.infinity,
                  margin:
                      const EdgeInsets.only(
                    bottom: 12,
                  ),
                  padding:
                      const EdgeInsets.all(
                    12,
                  ),
                  decoration:
                      BoxDecoration(
                    color:
                        AshaColors.peach
                            .withOpacity(
                      0.45,
                    ),
                    borderRadius:
                        BorderRadius.circular(
                      14,
                    ),
                  ),
                  child: Text(
                    error!,
                    style:
                        const TextStyle(
                      fontSize: 12,
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
                'Nearby medical facilities',
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
              // RESULTS
              // ==================================================

              Expanded(
                child: results.isEmpty
                    ? Center(
                        child: Text(
                          loading
                              ? 'Finding nearby medical facilities...'
                              : 'No nearby medical facilities found.',
                          textAlign:
                              TextAlign.center,
                          style:
                              TextStyle(
                            fontSize: 12,
                            color:
                                AshaColors.slate,
                          ),
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

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }
}

