import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

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

  // Doctor / Clinic / Hospital
  String selectedType = 'Doctor';

  // ============================================================
  // TYPE NAME
  // ============================================================


  String get _typeNamePlural {
    switch (selectedType) {
      case 'Doctor':
        return 'doctors';

      case 'Clinic':
        return 'clinics';

      case 'Hospital':
        return 'hospitals';

      default:
        return 'healthcare providers';
    }
  }

  // ============================================================
  // CURRENT LOCATION
  // ============================================================

  Future<void> _useCurrentLocation() async {
    setState(() {
      loading = true;
      error = null;
      results = [];
    });

    try {
      final serviceEnabled =
          await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        throw Exception(
          'Location services are disabled. Please turn on GPS/location on your phone.',
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
          'Location permission denied.',
        );
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception(
          'Location permission permanently denied. Please enable location permission in phone Settings.',
        );
      }

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

      final places =
          await ApiService.findDoctors(
        position.latitude,
        position.longitude,
        type: selectedType,
      );

      if (!mounted) return;

      setState(() {
        selectedLocation = location;
        results = places;
        loading = false;

        if (places.isEmpty) {
          error =
              'No nearby $_typeNamePlural were found in this area.';
        }
      });
    } catch (e) {
      print(
        'Find healthcare error: $e',
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

  // ============================================================
  // MANUAL ADDRESS SEARCH
  // ============================================================

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

      final places =
          await ApiService.findDoctors(
        lat,
        lng,
        type: selectedType,
      );

      if (!mounted) return;

      setState(() {
        selectedLocation =
            searchedLocation;

        results = places;

        loading = false;

        if (places.isEmpty) {
          error =
              'Location found, but no nearby $_typeNamePlural were found.';
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

  // ============================================================
  // TYPE SELECTION
  // ============================================================

  void _selectType(String type) {
    setState(() {
      selectedType = type;
      results = [];
      error = null;
    });

    if (selectedLocation != null) {
      _searchSelectedLocation();
    }
  }

  Future<void> _searchSelectedLocation() async {
    if (selectedLocation == null) {
      return;
    }

    setState(() {
      loading = true;
      error = null;
      results = [];
    });

    try {
      final places =
          await ApiService.findDoctors(
        selectedLocation!.latitude,
        selectedLocation!.longitude,
        type: selectedType,
      );

      if (!mounted) return;

      setState(() {
        results = places;
        loading = false;

        if (places.isEmpty) {
          error =
              'No nearby $_typeNamePlural were found.';
        }
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        error =
            'Could not load nearby $_typeNamePlural.';
        loading = false;
      });
    }
  }

  // ============================================================
  // OPEN WEBSITE
  // ============================================================

  Future<void> _openWebsite(
    String website,
  ) async {
    try {
      final url =
          Uri.parse(website);

      if (!await launchUrl(
        url,
        mode: LaunchMode.externalApplication,
      )) {
        throw Exception();
      }
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Could not open this website.',
          ),
        ),
      );
    }
  }

  // ============================================================
  // CALL
  // ============================================================

  Future<void> _callPlace(
    String phone,
  ) async {
    try {
      final cleanedPhone =
          phone.replaceAll(
        RegExp(r'[^0-9+]'),
        '',
      );

      final url =
          Uri.parse(
        'tel:$cleanedPhone',
      );

      if (!await launchUrl(url)) {
        throw Exception();
      }
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Could not open the phone dialer.',
          ),
        ),
      );
    }
  }

  // ============================================================
  // DIRECTIONS
  // ============================================================

  Future<void> _openDirections(
    Doctor doctor,
  ) async {
    final url = Uri.parse(
      'https://www.google.com/maps/dir/?api=1'
      '&destination=${doctor.lat},${doctor.lng}',
    );

    try {
      if (!await launchUrl(
        url,
        mode: LaunchMode.externalApplication,
      )) {
        throw Exception();
      }
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Could not open directions.',
          ),
        ),
      );
    }
  }

  // ============================================================
  // TYPE ICON
  // ============================================================

  IconData _getTypeIcon(
    String type,
  ) {
    switch (type) {
      case 'Doctor':
        return Icons.person_rounded;

      case 'Clinic':
        return Icons.medical_services_rounded;

      case 'Hospital':
        return Icons.local_hospital_rounded;

      default:
        return Icons.health_and_safety_rounded;
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
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Text(
              'Choose a location to see nearby healthcare',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight:
                    FontWeight.w500,
              ),
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

            MarkerLayer(
              markers: [
                // User location
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

                // Healthcare locations
                ...results.map(
                  (place) => Marker(
                    point: LatLng(
                      place.lat,
                      place.lng,
                    ),
                    width: 45,
                    height: 45,
                    child: Icon(
                      _getTypeIcon(
                        place.type,
                      ),
                      size: 34,
                      color:
                          AshaColors.coral,
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
  // HEALTHCARE CARD
  // ============================================================

  Widget _doctorCard(
    Doctor doctor,
  ) {
    return AshaCard(
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          // ----------------------------------------------------
          // NAME + TYPE
          // ----------------------------------------------------

          Row(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color:
                      AshaColors.peach,
                  borderRadius:
                      BorderRadius.circular(
                    14,
                  ),
                ),
                child: Icon(
                  _getTypeIcon(
                    doctor.type,
                  ),
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
                        fontSize: 15,
                      ),
                    ),

                    const SizedBox(
                      height: 6,
                    ),

                    Container(
                      padding:
                          const EdgeInsets
                              .symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration:
                          BoxDecoration(
                        color:
                            AshaColors.peach,
                        borderRadius:
                            BorderRadius
                                .circular(
                          8,
                        ),
                      ),
                      child: Text(
                        doctor.type,
                        style:
                            const TextStyle(
                          fontSize: 10,
                          fontWeight:
                              FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // ----------------------------------------------------
          // ADDRESS
          // ----------------------------------------------------

          if (doctor.address
              .trim()
              .isNotEmpty) ...[
            const SizedBox(
              height: 12,
            ),

            Row(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.location_on_outlined,
                  size: 18,
                  color:
                      AshaColors.slate,
                ),

                const SizedBox(
                  width: 8,
                ),

                Expanded(
                  child: Text(
                    doctor.address,
                    style:
                        const TextStyle(
                      fontSize: 12,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ],

          // ----------------------------------------------------
          // PHONE
          // ----------------------------------------------------

          if (doctor.phone != null &&
              doctor.phone!
                  .trim()
                  .isNotEmpty) ...[
            const SizedBox(
              height: 10,
            ),

            Row(
              children: [
                const Icon(
                  Icons.phone_outlined,
                  size: 18,
                  color:
                      AshaColors.slate,
                ),

                const SizedBox(
                  width: 8,
                ),

                Expanded(
                  child: Text(
                    doctor.phone!,
                    style:
                        const TextStyle(
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ],

          // ----------------------------------------------------
          // OPENING HOURS
          // ----------------------------------------------------

          if (doctor.openingHours != null &&
              doctor.openingHours!
                  .trim()
                  .isNotEmpty) ...[
            const SizedBox(
              height: 10,
            ),

            Row(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.access_time_rounded,
                  size: 18,
                  color:
                      AshaColors.slate,
                ),

                const SizedBox(
                  width: 8,
                ),

                Expanded(
                  child: Text(
                    doctor.openingHours!,
                    style:
                        const TextStyle(
                      fontSize: 12,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(
            height: 16,
          ),

          // ----------------------------------------------------
          // ACTION BUTTONS
          // ----------------------------------------------------

          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              // CALL
              if (doctor.phone != null &&
                  doctor.phone!
                      .trim()
                      .isNotEmpty)
                OutlinedButton.icon(
                  onPressed: () =>
                      _callPlace(
                    doctor.phone!,
                  ),
                  icon: const Icon(
                    Icons.phone_outlined,
                    size: 17,
                  ),
                  label: const Text(
                    'Call',
                  ),
                ),

              // WEBSITE
              if (doctor.website != null &&
                  doctor.website!
                      .trim()
                      .isNotEmpty)
                OutlinedButton.icon(
                  onPressed: () =>
                      _openWebsite(
                    doctor.website!,
                  ),
                  icon: const Icon(
                    Icons.language_rounded,
                    size: 17,
                  ),
                  label: const Text(
                    'Website',
                  ),
                ),

              // DIRECTIONS
              OutlinedButton.icon(
                onPressed: () =>
                    _openDirections(
                  doctor,
                ),
                icon: const Icon(
                  Icons.directions_outlined,
                  size: 17,
                ),
                label: const Text(
                  'Directions',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // TYPE BUTTON
  // ============================================================

  Widget _typeButton({
    required String type,
    required String label,
    required IconData icon,
  }) {
    final selected =
        selectedType == type;

    return Expanded(
      child: GestureDetector(
        onTap: loading
            ? null
            : () => _selectType(type),
        child: AnimatedContainer(
          duration:
              const Duration(
            milliseconds: 200,
          ),
          padding:
              const EdgeInsets.symmetric(
            vertical: 14,
            horizontal: 8,
          ),
          decoration: BoxDecoration(
            color: selected
                ? AshaColors.coral
                : AshaColors.peach
                    .withOpacity(0.45),
            borderRadius:
                BorderRadius.circular(16),
            border: Border.all(
              color: selected
                  ? AshaColors.coral
                  : Colors.transparent,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 24,
                color: selected
                    ? Colors.white
                    : AshaColors.coral,
              ),

              const SizedBox(
                height: 6,
              ),

              Text(
                label,
                textAlign:
                    TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight:
                      FontWeight.w600,
                  color: selected
                      ? Colors.white
                      : AshaColors.ink,
                ),
              ),
            ],
          ),
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
        title: const Text(
          'Find healthcare',
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
                'What are you looking for?',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),

              const SizedBox(
                height: 5,
              ),

              const Text(
                'Find nearby doctors, clinics and hospitals.',
                style: TextStyle(
                  fontSize: 12,
                ),
              ),

              const SizedBox(
                height: 14,
              ),

              // ==================================================
              // TYPE SELECTION
              // ==================================================

              Row(
                children: [
                  _typeButton(
                    type: 'Doctor',
                    label: 'Doctor',
                    icon:
                        Icons.person_rounded,
                  ),

                  const SizedBox(
                    width: 8,
                  ),

                  _typeButton(
                    type: 'Clinic',
                    label: 'Clinic',
                    icon:
                        Icons.medical_services_rounded,
                  ),

                  const SizedBox(
                    width: 8,
                  ),

                  _typeButton(
                    type: 'Hospital',
                    label: 'Hospital',
                    icon:
                        Icons.local_hospital_rounded,
                  ),
                ],
              ),

              const SizedBox(
                height: 18,
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
                      'Enter area or address',

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
                height: 14,
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
                Padding(
                  padding:
                      const EdgeInsets.only(
                    bottom: 10,
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
                height: 14,
              ),

              Text(
                'Nearby $_typeNamePlural',
                style:
                    const TextStyle(
                  fontSize: 16,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),

              const SizedBox(
                height: 8,
              ),

              // ==================================================
              // RESULTS
              // ==================================================

              Expanded(
                child: results.isEmpty
                    ? Center(
                        child: Text(
                          selectedLocation ==
                                  null
                              ? 'Choose a location to find nearby $_typeNamePlural.'
                              : 'No nearby $_typeNamePlural found.',
                          textAlign:
                              TextAlign.center,
                          style:
                              const TextStyle(
                            fontSize: 12,
                          ),
                        ),
                      )
                    : ListView.separated(
                        itemCount:
                            results.length,
                        separatorBuilder:
                            (_, __) =>
                                const SizedBox(
                          height: 10,
                        ),
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