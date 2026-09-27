
import 'dart:convert';

import 'package:asha_app/services/health_profile_store.dart';
import 'package:http/http.dart' as http;

import '../models/prediction.dart';
import '../models/doctor.dart';

// ============================================================
// API SERVICE
// ============================================================

class ApiService {
  static const String baseUrl = 'https://asha-backend-1.onrender.com';
  // ============================================================
  // PREDICTION
  // ============================================================

  static Future<Prediction> fetchPrediction({
    required String userId,
  }) async {
    final profile = HealthProfileStore.toJson();

    print('================================');
    print('ASHA ML PREDICTION');
    print('Firebase UID: $userId');
    print('Sending profile: $profile');
    print(
      'URL: $baseUrl/predict/$userId',
    );
    print('================================');

    try {
      final response = await http
          .post(
            Uri.parse(
              '$baseUrl/predict/$userId',
            ),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode(profile),
          )
          .timeout(
            const Duration(seconds: 30),
          );

      print('================================');
      print(
        'Prediction response: '
        '${response.statusCode}',
      );
      print(
        'Prediction body: '
        '${response.body}',
      );
      print('================================');

      if (response.statusCode != 200) {
        throw Exception(
          'Prediction failed: ${response.body}',
        );
      }

      final decoded = jsonDecode(
        response.body,
      );

      if (decoded is! Map<String, dynamic>) {
        throw Exception(
          'Invalid prediction response.',
        );
      }

      final prediction =
          Prediction.fromJson(decoded);

      print(
        'ML prediction parsed successfully.',
      );
      print(
        'Predicted next period: '
        '${prediction.nextPeriodLabel}',
      );

      return prediction;
    } catch (e) {
      print(
        'Prediction API error: $e',
      );
      rethrow;
    }
  }

  // ============================================================
  // LOG SYMPTOMS
  // ============================================================

  static Future<void> logSymptoms(
    String userId,
    Map<String, dynamic> log,
  ) async {
    final response = await http.post(
      Uri.parse(
        '$baseUrl/log/$userId',
      ),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode(log),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Could not save symptoms',
      );
    }
  }

  // ============================================================
  // AI CHAT
  // ============================================================

  static Future<String> sendChatMessage(
    String message, {
    List<Map<String, String>> history =
        const [],
  }) async {
    try {
      print(
        '--------------------------------',
      );
      print('ASHA CHAT REQUEST');
      print('Message: $message');
      print('History: $history');
      print(
        'URL: $baseUrl/chat',
      );

      final response = await http
          .post(
            Uri.parse(
              '$baseUrl/chat',
            ),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({
              'message': message,
              'history': history,
            }),
          )
          .timeout(
            const Duration(seconds: 30),
          );

      print(
        '--------------------------------',
      );
      print('ASHA CHAT RESPONSE');
      print(
        'Status: ${response.statusCode}',
      );
      print(
        'Body: ${response.body}',
      );
      print(
        '--------------------------------',
      );

      if (response.statusCode != 200) {
        throw Exception(
          'Chat failed: ${response.body}',
        );
      }

      final decoded =
          jsonDecode(response.body);

      if (decoded is! Map<String, dynamic>) {
        throw Exception(
          'Invalid chat response.',
        );
      }

      final reply =
          decoded['reply'] as String?;

      if (reply == null) {
        throw Exception(
          'No reply in response.',
        );
      }

      return reply;
    } catch (e) {
      print(
        'Chat error: $e',
      );
      rethrow;
    }
  }

  // ============================================================
  // FIND DOCTORS
  // ============================================================

 static Future<List<Doctor>> findDoctors({
  required double latitude,
  required double longitude,
  int radius = 5000,
}) async {
  try {
    print('================================');
    print('DOCTOR FINDER REQUEST');
    print('Latitude: $latitude');
    print('Longitude: $longitude');
    print('Radius: $radius meters');

    final response = await http
        .post(
          Uri.parse('$baseUrl/find-doctors'),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: jsonEncode({
            'latitude': latitude,
            'longitude': longitude,
            'radius': radius,
          }),
        )
        .timeout(
          const Duration(seconds: 40),
        );

    print(
      'Doctor Finder Response: ${response.statusCode}',
    );

    print(
      'Response body: ${response.body}',
    );

    print('================================');

    if (response.statusCode != 200) {
      try {
        final errorBody = jsonDecode(response.body);

        if (errorBody is Map<String, dynamic>) {
          throw Exception(
            errorBody['error'] ??
                errorBody['message'] ??
                'Server returned ${response.statusCode}',
          );
        }
      } catch (_) {
        throw Exception(
          'Doctor search failed '
          '(${response.statusCode}): ${response.body}',
        );
      }
    }

    final decoded = jsonDecode(response.body);

    if (decoded is! Map<String, dynamic>) {
      throw Exception(
        'Invalid doctor response from server.',
      );
    }

    if (decoded['error'] != null) {
      throw Exception(
        decoded['error'].toString(),
      );
    }

    final rawFacilities = decoded['facilities'];

    if (rawFacilities is! List) {
      throw Exception(
        'Server did not return a facilities list.',
      );
    }

    final facilities = rawFacilities
        .whereType<Map<String, dynamic>>()
        .map(
          (item) => Doctor.fromJson(item),
        )
        .where(
          (doctor) =>
              doctor.latitude != 0 &&
              doctor.longitude != 0 &&
              doctor.name.isNotEmpty,
        )
        .toList();

    print(
      'Found ${facilities.length} valid healthcare facilities',
    );

    return facilities;
  } catch (e) {
    print(
      'ERROR IN DOCTOR FINDER: $e',
    );

    rethrow;
  }
}
  

  // ============================================================
  // GEOCODE ADDRESS
  // ============================================================

  static Future<Map<String, dynamic>>
      geocodeAddress(
    String address,
  ) async {
    try {
      print(
        '================================',
      );
      print('GEOCODING ADDRESS');
      print('Address: $address');

      final uri = Uri.https(
        'nominatim.openstreetmap.org',
        '/search',
        {
          'q': address,
          'format': 'jsonv2',
          'limit': '1',
          'countrycodes': 'in',
          'addressdetails': '1',
        },
      );

      final response = await http
          .get(
            uri,
            headers: {
              'Accept': 'application/json',
              'User-Agent':
                  'AshaMenstrualHealthApp/1.0',
            },
          )
          .timeout(
            const Duration(seconds: 20),
          );

      print(
        'Geocoding Response: '
        '${response.statusCode}',
      );

      print(
        'Geocoding Body: '
        '${response.body}',
      );

      print(
        '================================',
      );

      if (response.statusCode != 200) {
        throw Exception(
          'Address search failed: '
          '${response.statusCode}',
        );
      }

      final decoded =
          jsonDecode(response.body);

      if (decoded is! List ||
          decoded.isEmpty) {
        throw Exception(
          'No location found for this address.',
        );
      }

      final firstResult =
          decoded.first;

      if (firstResult
          is! Map<String, dynamic>) {
        throw Exception(
          'Invalid geocoding response.',
        );
      }

      final latitude =
          double.tryParse(
        firstResult['lat']
                ?.toString() ??
            '',
      );

      final longitude =
          double.tryParse(
        firstResult['lon']
                ?.toString() ??
            '',
      );

      if (latitude == null ||
          longitude == null) {
        throw Exception(
          'Location coordinates were not found.',
        );
      }

      final displayName =
          firstResult['display_name']
                  ?.toString() ??
              address;

      print(
        'Geocoded location: '
        '$latitude, $longitude',
      );

      return {
        'lat': latitude,
        'lng': longitude,
        'display_name': displayName,
      };
    } catch (e) {
      print(
        'Geocoding error: $e',
      );
      rethrow;
    }
  }

  // ============================================================
  // GET DOCTOR DETAILS
  // ============================================================

  static Future<DoctorDetails>
      getDoctorDetails({
    required String placeId,
  }) async {
    try {
      print(
        'Getting details for place: '
        '$placeId',
      );

      final response = await http
          .get(
            Uri.parse(
              '$baseUrl/find-doctors/$placeId',
            ),
          )
          .timeout(
            const Duration(seconds: 30),
          );

      print(
        'Doctor Details Response: '
        '${response.statusCode}',
      );

      if (response.statusCode != 200) {
        throw Exception(
          'Failed to get doctor details: '
          '${response.body}',
        );
      }

      final decoded =
          jsonDecode(response.body);

      if (decoded is! Map<String, dynamic>) {
        throw Exception(
          'Invalid response format',
        );
      }

      final rawDetails =
          decoded['details'];

      if (rawDetails
          is! Map<String, dynamic>) {
        throw Exception(
          'Doctor details not found.',
        );
      }

      return DoctorDetails.fromJson(
        rawDetails,
      );
    } catch (e) {
      print(
        'Error getting doctor details: $e',
      );
      rethrow;
    }
  }
}

