import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/doctor.dart';
import '../models/prediction.dart';
import '../services/health_profile_store.dart';

class ApiService {
  static const String baseUrl =
      'https://asha-backend-1.onrender.com';

  // ============================================================
  // PREDICTION
  // ============================================================

  static Future<Prediction> fetchPrediction({
  String? userId,
}) async {
  final uid =
      userId ??
      FirebaseAuth.instance.currentUser?.uid;

  if (uid == null || uid.isEmpty) {
    throw Exception('Firebase user not found.');
  }

  // IMPORTANT:
  // Prediction is generated ONLY from the user's saved
  // HealthProfileStore data.
  final profileData =
      HealthProfileStore.toJson();

  final url =
      Uri.parse('$baseUrl/predict/$uid');

  final response = await http.post(
    url,
    headers: {
      'Content-Type': 'application/json',
    },
    body: jsonEncode(profileData),
  );

  if (response.statusCode != 200) {
    throw Exception(
      'Prediction failed: ${response.statusCode}\n'
      '${response.body}',
    );
  }

  final decoded = jsonDecode(response.body);

  if (decoded is! Map<String, dynamic>) {
    throw Exception(
      'Invalid prediction response from server.',
    );
  }

  return Prediction.fromJson(decoded);
}

  // Compatibility alias
  static Future<Prediction> predict({
    String? userId,
  }) {
    return fetchPrediction(
      userId: userId,
    );
  }

  // ============================================================
  // HEALTH DATA LOG
  // ============================================================

  static Future<void> logHealthData(
    Map<String, dynamic> data,
  ) async {
    final String? id =
        HealthProfileStore.userId?.toString();

    if (id == null || id.isEmpty) {
      throw Exception('User ID not found.');
    }

    final Uri url =
        Uri.parse('$baseUrl/log/$id');

    final http.Response response =
        await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode(data),
    );

    if (response.statusCode < 200 ||
        response.statusCode >= 300) {
      throw Exception(
        'Failed to save health data: '
        '${response.statusCode}\n${response.body}',
      );
    }
  }

  // ============================================================
  // SYMPTOMS
  // ============================================================

  static Future<void> logSymptoms(
  String userId,
  Map<String, dynamic> symptoms,
) async {
  if (userId.isEmpty) {
    throw Exception('User ID not found.');
  }

  try {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('health_logs')
        .add({
      ...symptoms,
      'createdAt': FieldValue.serverTimestamp(),
    });
  } catch (e) {
    throw Exception('Failed to save health log: $e');
  }
}
  // ============================================================
  // CHAT
  // ============================================================

  static Future<String> sendChatMessage(
    String message,
  ) async {
    final Uri url =
        Uri.parse('$baseUrl/chat');

    final http.Response response =
        await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'message': message,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Chat failed: ${response.statusCode}\n${response.body}',
      );
    }

    final dynamic decoded =
        jsonDecode(response.body);

    if (decoded is! Map<String, dynamic>) {
      throw Exception(
        'Invalid chat response.',
      );
    }

    return decoded['reply']?.toString() ??
        decoded['message']?.toString() ??
        'Sorry, I could not generate a response.';
  }

  // Compatibility alias
  static Future<String> chat(
    String message,
  ) {
    return sendChatMessage(message);
  }

  // ============================================================
  // GOOGLE PLACES - FIND DOCTORS
  // ============================================================

  static Future<List<Doctor>> findDoctors({
    required double latitude,
    required double longitude,
    double radius = 5000,
  }) async {
    final Uri url =
        Uri.parse(
      '$baseUrl/find-doctors'
      '?lat=$latitude'
      '&lng=$longitude'
      '&radius=$radius',
    );

    final http.Response response =
        await http.get(url);

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to find healthcare facilities: '
        '${response.statusCode}\n${response.body}',
      );
    }

    final dynamic decoded =
        jsonDecode(response.body);

    if (decoded is! Map<String, dynamic>) {
      throw Exception(
        'Invalid doctor search response.',
      );
    }

    final dynamic facilitiesJson =
    decoded['facilities'];

if (facilitiesJson is! List) {
  return <Doctor>[];
}

return facilitiesJson
    .whereType<Map<String, dynamic>>()
    .map(Doctor.fromJson)
    .toList();
  }

  // ============================================================
  // GOOGLE GEOCODING
  // ============================================================

  static Future<Map<String, dynamic>?> geocodeAddress(
    String address,
  ) async {
    if (address.trim().isEmpty) {
      return null;
    }

    final Uri url =
        Uri.parse(
      '$baseUrl/geocode'
      '?address=${Uri.encodeComponent(address)}',
    );

    final http.Response response =
        await http.get(url);

    if (response.statusCode != 200) {
      throw Exception(
        'Geocoding failed: '
        '${response.statusCode}\n${response.body}',
      );
    }

    final dynamic decoded =
        jsonDecode(response.body);

    if (decoded is! Map<String, dynamic>) {
      throw Exception(
        'Invalid geocoding response.',
      );
    }

    return decoded;
  }

  // ============================================================
  // GOOGLE PLACES DETAILS
  // ============================================================

  static Future<DoctorDetails?> getDoctorDetails(
    String placeId,
  ) async {
    if (placeId.isEmpty) {
      return null;
    }

    final Uri url =
        Uri.parse(
      '$baseUrl/find-doctors/'
      '${Uri.encodeComponent(placeId)}',
    );

    final http.Response response =
        await http.get(url);

    if (response.statusCode == 404) {
      return null;
    }

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to load doctor details: '
        '${response.statusCode}\n${response.body}',
      );
    }

    final dynamic decoded =
        jsonDecode(response.body);

    if (decoded is! Map<String, dynamic>) {
      throw Exception(
        'Invalid doctor details response.',
      );
    }

    return DoctorDetails.fromJson(decoded);
  }
}