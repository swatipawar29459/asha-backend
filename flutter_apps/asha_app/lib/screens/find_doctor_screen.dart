import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/doctor.dart';

class FindDoctorScreen extends StatefulWidget {
  const FindDoctorScreen({super.key});

  @override
  State<FindDoctorScreen> createState() =>
      _FindDoctorScreenState();
}

class _FindDoctorScreenState
    extends State<FindDoctorScreen> {
  static const String baseUrl =
      'https://asha-backend-1.onrender.com';

  final TextEditingController _locationController =
      TextEditingController();

  final MapController _mapController =
      MapController();

  bool _mapReady = false;

  double? _pendingMapLatitude;
  double? _pendingMapLongitude;

  String selectedType = 'doctor';

  double? latitude;
  double? longitude;

  String locationText = '';

  String sourceText = '';

  List<Doctor> doctors = [];

  bool loadingLocation = false;
  bool loadingDoctors = false;

  String? errorMessage;

  @override
  void dispose() {
    _locationController.dispose();
    super.dispose();
  }

  // ============================================================
  // MAP
  // ============================================================

  void moveMapTo(
    double lat,
    double lng,
    double zoom,
  ) {
    _pendingMapLatitude = lat;
    _pendingMapLongitude = lng;

    if (!_mapReady) {
      return;
    }

    _mapController.move(
      LatLng(lat, lng),
      zoom,
    );
  }

  // ============================================================
  // CURRENT LOCATION
  // ============================================================

  Future<void> useCurrentLocation() async {
    setState(() {
      loadingLocation = true;
      errorMessage = null;
      sourceText = '';
    });

    try {
      final bool serviceEnabled =
          await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        setState(() {
          loadingLocation = false;
          errorMessage =
              'Please turn on location services and try again.';
        });
        return;
      }

      LocationPermission permission =
          await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission =
            await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        setState(() {
          loadingLocation = false;
          errorMessage =
              'Location permission was denied.';
        });
        return;
      }

      if (permission ==
          LocationPermission.deniedForever) {
        setState(() {
          loadingLocation = false;
          errorMessage =
              'Location permission is permanently denied. Please enable it from app settings.';
        });
        return;
      }

      final Position position =
          await Geolocator.getCurrentPosition(
        desiredAccuracy:
            LocationAccuracy.high,
      );

      if (!mounted) return;

      setState(() {
        latitude = position.latitude;
        longitude = position.longitude;
        locationText = 'Current location';
        loadingLocation = false;
      });

      moveMapTo(
        position.latitude,
        position.longitude,
        14,
      );

      await findHealthcare(
        position.latitude,
        position.longitude,
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        loadingLocation = false;
        errorMessage =
            'Could not get your current location.';
      });
    }
  }

  // ============================================================
  // SEARCH LOCATION
  // ============================================================

  Future<void> searchLocation() async {
    final String address =
        _locationController.text.trim();

    if (address.isEmpty) {
      setState(() {
        errorMessage =
            'Please enter a location.';
      });
      return;
    }

    setState(() {
      loadingLocation = true;
      errorMessage = null;
      sourceText = '';
      doctors = [];
    });

    try {
      final Uri uri = Uri.https(
        'nominatim.openstreetmap.org',
        '/search',
        {
          'q':
              '$address, Mumbai, India',
          'format':
              'json',
          'limit':
              '1',
        },
      );

      final response = await http.get(
        uri,
        headers: {
          'User-Agent':
              'Asha-Womens-Health-App/1.0',
          'Accept':
              'application/json',
        },
      ).timeout(
        const Duration(seconds: 15),
      );

      if (response.statusCode != 200) {
        throw Exception(
          'Location search failed',
        );
      }

      final List<dynamic> results =
          jsonDecode(response.body);

      if (results.isEmpty) {
        setState(() {
          loadingLocation = false;
          errorMessage =
              'Location not found. Try Kurla East or Nehru Nagar, Kurla.';
        });
        return;
      }

      final Map<String, dynamic> decoded =
          Map<String, dynamic>.from(
        results.first,
      );

      final double newLat =
          double.parse(
        decoded['lat'].toString(),
      );

      final double newLng =
          double.parse(
        decoded['lon'].toString(),
      );

      if (!mounted) return;

      setState(() {
        latitude = newLat;
        longitude = newLng;

        locationText =
            decoded['display_name']
                    ?.toString() ??
                address;

        loadingLocation = false;
      });

      moveMapTo(
        newLat,
        newLng,
        14,
      );

      await findHealthcare(
        newLat,
        newLng,
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        loadingLocation = false;
        errorMessage =
            'Could not search this location.';
      });
    }
  }

  // ============================================================
  // HEALTHCARE SEARCH
  // ============================================================

  Future<void> findHealthcare(
    double lat,
    double lng,
  ) async {
    setState(() {
      loadingDoctors = true;
      errorMessage = null;
      sourceText = '';
      doctors = [];
    });

    try {
      final Uri uri = Uri.parse(
        '$baseUrl/doctors'
        '?lat=$lat'
        '&lng=$lng'
        '&type=$selectedType',
      );

      final response =
          await http.get(uri).timeout(
        const Duration(seconds: 55),
      );

      if (response.statusCode != 200) {
        throw Exception(
          'Server returned ${response.statusCode}',
        );
      }

      final Map<String, dynamic> data =
          jsonDecode(response.body);

      final List<dynamic> results =
          data['results'] is List
              ? data['results']
              : [];

      final List<Doctor> loadedDoctors =
          results
              .map(
                (item) =>
                    Doctor.fromJson(
                  Map<String, dynamic>.from(
                    item,
                  ),
                ),
              )
              .where(
                (doctor) =>
                    doctor.lat != 0 &&
                    doctor.lng != 0,
              )
              .toList();

      final String source =
          data['source']?.toString() ??
              'Healthcare search';

      if (!mounted) return;

      setState(() {
        doctors = loadedDoctors;
        loadingDoctors = false;
        sourceText = source;

        if (loadedDoctors.isEmpty) {
          errorMessage =
              'No $selectedType facilities were found at this location.';
        }
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        loadingDoctors = false;
        errorMessage =
            'Could not load healthcare providers. Please try again.';
      });
    }
  }

  // ============================================================
  // CATEGORY
  // ============================================================

  Future<void> changeType(
    String type,
  ) async {
    if (selectedType == type) {
      return;
    }

    setState(() {
      selectedType = type;
    });

    if (latitude != null &&
        longitude != null) {
      await findHealthcare(
        latitude!,
        longitude!,
      );
    }
  }

  // ============================================================
  // MAP MARKERS
  // ============================================================

  List<Marker> getMarkers() {
    final List<Marker> markers = [];

    if (latitude != null &&
        longitude != null) {
      markers.add(
        Marker(
          point: LatLng(
            latitude!,
            longitude!,
          ),
          width: 40,
          height: 40,
          child: const Icon(
            Icons.my_location,
            color: Color(0xFFD8754E),
            size: 30,
          ),
        ),
      );
    }

    for (final Doctor doctor in doctors) {
      markers.add(
        Marker(
          point: LatLng(
            doctor.lat,
            doctor.lng,
          ),
          width: 45,
          height: 45,
          child: GestureDetector(
            onTap: () {
              if (!_mapReady) {
                return;
              }

              _mapController.move(
                LatLng(
                  doctor.lat,
                  doctor.lng,
                ),
                16,
              );
            },
            child: const Icon(
              Icons.location_on,
              color: Color(0xFFD8754E),
              size: 40,
            ),
          ),
        ),
      );
    }

    return markers;
  }

  // ============================================================
  // DIRECTIONS
  // ============================================================

  Future<void> openDirections(
    Doctor doctor,
  ) async {
    final Uri uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1'
      '&destination=${doctor.lat},${doctor.lng}',
    );

    await launchUrl(
      uri,
      mode:
          LaunchMode.externalApplication,
    );
  }

  // ============================================================
  // CALL
  // ============================================================

  Future<void> callDoctor(
    String phone,
  ) async {
    final Uri uri = Uri.parse(
      'tel:$phone',
    );

    await launchUrl(uri);
  }

  // ============================================================
  // WEBSITE
  // ============================================================

  Future<void> openWebsite(
    String website,
  ) async {
    String url = website.trim();

    if (!url.startsWith('http://') &&
        !url.startsWith('https://')) {
      url = 'https://$url';
    }

    await launchUrl(
      Uri.parse(url),
      mode:
          LaunchMode.externalApplication,
    );
  }

  // ============================================================
  // DOCTOR CARD
  // ============================================================

  Widget buildDoctorCard(
    Doctor doctor,
  ) {
    return Card(
      margin:
          const EdgeInsets.only(
        bottom: 14,
      ),
      elevation: 2,
      shape:
          RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(18),
      ),
      child: Padding(
        padding:
            const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [

            Row(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [

                Container(
                  width: 48,
                  height: 48,
                  decoration:
                      BoxDecoration(
                    color:
                        const Color(
                      0xFFFFE9DC,
                    ),
                    borderRadius:
                        BorderRadius.circular(
                      14,
                    ),
                  ),
                  child: const Icon(
                    Icons
                        .local_hospital_outlined,
                    color:
                        Color(0xFFD8754E),
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
                          fontSize: 16,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),

                      const SizedBox(
                        height: 4,
                      ),

                      Text(
                        doctor.type
                            .toUpperCase(),
                        style:
                            const TextStyle(
                          fontSize: 11,
                          color:
                              Color(
                            0xFFD8754E,
                          ),
                          fontWeight:
                              FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            if (doctor.address.isNotEmpty)
              ...[

                const SizedBox(
                  height: 12,
                ),

                Row(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [

                    const Icon(
                      Icons
                          .location_on_outlined,
                      size: 19,
                      color:
                          Colors.grey,
                    ),

                    const SizedBox(
                      width: 7,
                    ),

                    Expanded(
                      child: Text(
                        doctor.address,
                        style:
                            const TextStyle(
                          fontSize: 13,
                          color:
                              Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
              ],

            if (doctor.openingHours !=
                null)
              ...[

                const SizedBox(
                  height: 8,
                ),

                Row(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [

                    const Icon(
                      Icons.access_time,
                      size: 18,
                      color:
                          Colors.grey,
                    ),

                    const SizedBox(
                      width: 7,
                    ),

                    Expanded(
                      child: Text(
                        doctor
                            .openingHours!,
                        style:
                            const TextStyle(
                          fontSize: 13,
                          color:
                              Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
              ],

            const SizedBox(
              height: 14,
            ),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [

                OutlinedButton.icon(
                  onPressed: () =>
                      openDirections(
                    doctor,
                  ),
                  icon: const Icon(
                    Icons
                        .directions_outlined,
                    size: 18,
                  ),
                  label:
                      const Text(
                    'Directions',
                  ),
                ),

                if (doctor.phone != null)
                  OutlinedButton.icon(
                    onPressed: () =>
                        callDoctor(
                      doctor.phone!,
                    ),
                    icon: const Icon(
                      Icons.call_outlined,
                      size: 18,
                    ),
                    label:
                        const Text(
                      'Call',
                    ),
                  ),

                if (doctor.website != null)
                  OutlinedButton.icon(
                    onPressed: () =>
                        openWebsite(
                      doctor.website!,
                    ),
                    icon: const Icon(
                      Icons.language,
                      size: 18,
                    ),
                    label:
                        const Text(
                      'Website',
                    ),
                  ),
              ],
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
      backgroundColor:
          const Color(0xFFFFF8F3),

      appBar: AppBar(
        title: const Text(
          'Find a Doctor',
          style: TextStyle(
            fontWeight:
                FontWeight.bold,
          ),
        ),
        backgroundColor:
            const Color(0xFFFFF8F3),
        elevation: 0,
        foregroundColor:
            Colors.black87,
      ),

      body: SafeArea(
        child: Column(
          children: [

            Padding(
              padding:
                  const EdgeInsets.fromLTRB(
                16,
                12,
                16,
                8,
              ),
              child: Column(
                children: [

                  TextField(
                    controller:
                        _locationController,
                    textInputAction:
                        TextInputAction.search,
                    onSubmitted: (_) =>
                        searchLocation(),
                    decoration:
                        InputDecoration(
                      hintText:
                          'Enter area, city or landmark',
                      prefixIcon:
                          const Icon(
                        Icons.search,
                      ),
                      suffixIcon:
                          IconButton(
                        onPressed:
                            loadingLocation
                                ? null
                                : searchLocation,
                        icon:
                            const Icon(
                          Icons.arrow_forward,
                        ),
                      ),
                      filled: true,
                      fillColor:
                          Colors.white,
                      border:
                          OutlineInputBorder(
                        borderRadius:
                            BorderRadius
                                .circular(
                          16,
                        ),
                        borderSide:
                            BorderSide.none,
                      ),
                    ),
                  ),

                  const SizedBox(
                    height: 10,
                  ),

                  SizedBox(
                    width:
                        double.infinity,
                    child:
                        OutlinedButton.icon(
                      onPressed:
                          loadingLocation
                              ? null
                              : useCurrentLocation,
                      icon:
                          loadingLocation
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child:
                                      CircularProgressIndicator(
                                    strokeWidth:
                                        2,
                                  ),
                                )
                              : const Icon(
                                  Icons
                                      .my_location,
                                ),
                      label:
                          const Text(
                        'Use my current location',
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ==================================================
            // CATEGORY BUTTONS
            // ==================================================

            Padding(
              padding:
                  const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 6,
              ),
              child: Row(
                children: [

                  Expanded(
                    child:
                        _categoryButton(
                      'doctor',
                      'Doctors',
                      Icons
                          .person_outline,
                    ),
                  ),

                  const SizedBox(
                    width: 8,
                  ),

                  Expanded(
                    child:
                        _categoryButton(
                      'clinic',
                      'Clinics',
                      Icons
                          .medical_services_outlined,
                    ),
                  ),

                  const SizedBox(
                    width: 8,
                  ),

                  Expanded(
                    child:
                        _categoryButton(
                      'hospital',
                      'Hospitals',
                      Icons
                          .local_hospital_outlined,
                    ),
                  ),
                ],
              ),
            ),

            // ==================================================
            // LOCATION
            // ==================================================

            if (locationText.isNotEmpty)
              Padding(
                padding:
                    const EdgeInsets.fromLTRB(
                  16,
                  4,
                  16,
                  4,
                ),
                child: Row(
                  children: [

                    const Icon(
                      Icons.location_on,
                      size: 17,
                      color:
                          Color(0xFFD8754E),
                    ),

                    const SizedBox(
                      width: 5,
                    ),

                    Expanded(
                      child: Text(
                        locationText,
                        maxLines: 2,
                        overflow:
                            TextOverflow.ellipsis,
                        style:
                            const TextStyle(
                          fontSize: 12,
                          color:
                              Colors.black54,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // ==================================================
            // SOURCE
            // ==================================================

            if (sourceText.isNotEmpty)
              Padding(
                padding:
                    const EdgeInsets.fromLTRB(
                  16,
                  2,
                  16,
                  6,
                ),
                child: Align(
                  alignment:
                      Alignment.centerLeft,
                  child: Text(
                    'Results from $sourceText',
                    style:
                        const TextStyle(
                      fontSize: 10,
                      color:
                          Colors.black45,
                    ),
                  ),
                ),
              ),

            // ==================================================
            // MAP
            // ==================================================

            Expanded(
              flex: 5,
              child:
                  latitude == null ||
                          longitude == null
                      ? Container(
                          margin:
                              const EdgeInsets
                                  .symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration:
                              BoxDecoration(
                            color:
                                const Color(
                              0xFFFFE9DC,
                            ),
                            borderRadius:
                                BorderRadius
                                    .circular(
                              20,
                            ),
                          ),
                          child:
                              const Center(
                            child: Column(
                              mainAxisSize:
                                  MainAxisSize
                                      .min,
                              children: [

                                Icon(
                                  Icons
                                      .map_outlined,
                                  size: 45,
                                  color:
                                      Color(
                                    0xFFD8754E,
                                  ),
                                ),

                                SizedBox(
                                  height: 10,
                                ),

                                Text(
                                  'Search a location to see nearby healthcare providers',
                                  textAlign:
                                      TextAlign
                                          .center,
                                ),
                              ],
                            ),
                          ),
                        )
                      : ClipRRect(
                          borderRadius:
                              BorderRadius
                                  .circular(
                            20,
                          ),
                          child:
                              FlutterMap(
                            mapController:
                                _mapController,
                            options:
                                MapOptions(
                              initialCenter:
                                  LatLng(
                                latitude!,
                                longitude!,
                              ),
                              initialZoom:
                                  14,
                              onMapReady:
                                  () {
                                _mapReady =
                                    true;

                                if (_pendingMapLatitude !=
                                        null &&
                                    _pendingMapLongitude !=
                                        null) {
                                  _mapController
                                      .move(
                                    LatLng(
                                      _pendingMapLatitude!,
                                      _pendingMapLongitude!,
                                    ),
                                    14,
                                  );
                                }
                              },
                            ),
                            children: [

                              TileLayer(
                                urlTemplate:
                                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                userAgentPackageName:
                                    'com.asha.womenshealth',
                              ),

                              MarkerLayer(
                                markers:
                                    getMarkers(),
                              ),

                              RichAttributionWidget(
                                attributions:
                                    [
                                  TextSourceAttribution(
                                    'OpenStreetMap contributors',
                                    onTap:
                                        () {
                                      launchUrl(
                                        Uri.parse(
                                          'https://www.openstreetmap.org/copyright',
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
            ),

            // ==================================================
            // RESULTS
            // ==================================================

            Expanded(
              flex: 4,
              child: Padding(
                padding:
                    const EdgeInsets.fromLTRB(
                  16,
                  12,
                  16,
                  0,
                ),
                child:
                    loadingDoctors
                        ? const Center(
                            child:
                                CircularProgressIndicator(),
                          )
                        : errorMessage !=
                                    null &&
                                doctors.isEmpty
                            ? Center(
                                child:
                                    Padding(
                                  padding:
                                      const EdgeInsets
                                          .all(
                                    20,
                                  ),
                                  child:
                                      Column(
                                    mainAxisSize:
                                        MainAxisSize
                                            .min,
                                    children: [

                                      const Icon(
                                        Icons
                                            .location_searching,
                                        size: 40,
                                        color:
                                            Color(
                                          0xFFD8754E,
                                        ),
                                      ),

                                      const SizedBox(
                                        height: 10,
                                      ),

                                      Text(
                                        errorMessage!,
                                        textAlign:
                                            TextAlign
                                                .center,
                                        style:
                                            const TextStyle(
                                          color:
                                              Colors
                                                  .black54,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            : doctors.isEmpty
                                ? const Center(
                                    child:
                                        Text(
                                      'Search a location to find nearby providers.',
                                      textAlign:
                                          TextAlign
                                              .center,
                                    ),
                                  )
                                : ListView
                                    .builder(
                                    itemCount:
                                        doctors.length,
                                    itemBuilder:
                                        (
                                      context,
                                      index,
                                    ) {
                                      return buildDoctorCard(
                                        doctors[
                                            index],
                                      );
                                    },
                                  ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // CATEGORY BUTTON
  // ============================================================

  Widget _categoryButton(
    String type,
    String label,
    IconData icon,
  ) {
    final bool selected =
        selectedType == type;

    return OutlinedButton.icon(
      onPressed: () =>
          changeType(type),

      style:
          OutlinedButton.styleFrom(
        backgroundColor:
            selected
                ? const Color(
                    0xFFD8754E,
                  )
                : Colors.white,

        foregroundColor:
            selected
                ? Colors.white
                : const Color(
                    0xFFD8754E,
                  ),

        side:
            const BorderSide(
          color:
              Color(0xFFD8754E),
        ),

        padding:
            const EdgeInsets.symmetric(
          vertical: 11,
          horizontal: 4,
        ),

        shape:
            RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(
            14,
          ),
        ),
      ),

      icon:
          Icon(
        icon,
        size: 18,
      ),

      label:
          Text(
        label,
        style:
            const TextStyle(
          fontSize: 12,
          fontWeight:
              FontWeight.w600,
        ),
      ),
    );
  }
}