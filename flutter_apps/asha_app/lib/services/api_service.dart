import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/prediction.dart';
import '../models/doctor.dart';
import 'health_profile_store.dart';

class AshaNotification {

  final String id;
  final String type;
  final String title;
  final String message;
  final String time;
  final bool isRead;

  AshaNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.time,
    required this.isRead,
  });

  factory AshaNotification.fromJson(
    Map<String, dynamic> json,
  ) {

    return AshaNotification(
      id: json['id']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      time: json['time']?.toString() ?? '',
      isRead: json['is_read'] == true,
    );
  }
}


class ApiService {

  static const String baseUrl =
      'https://asha-backend-1.onrender.com';


  // ==================================================
  // PREDICTION
  // ==================================================

  static Future<Prediction> fetchPrediction({
    required String userId,
  }) async {

    final profile =
        HealthProfileStore.toJson();

    print('Firebase UID: $userId');
    print('Sending profile: $profile');

    final response = await http.post(

      Uri.parse(
        '$baseUrl/predict/$userId',
      ),

      headers: {
        'Content-Type':
            'application/json',
      },

      body: jsonEncode(profile),
    );

    print(
      'Prediction: '
      '${response.statusCode} '
      '${response.body}',
    );

    if (response.statusCode != 200) {

      throw Exception(
        'Prediction failed: ${response.body}',
      );
    }

    return Prediction.fromJson(
      jsonDecode(response.body),
    );
  }


  // ==================================================
  // LOG SYMPTOMS
  // ==================================================

  static Future<void> logSymptoms(
    String userId,
    Map<String, dynamic> log,
  ) async {

    final response = await http.post(

      Uri.parse(
        '$baseUrl/log/$userId',
      ),

      headers: {
        'Content-Type':
            'application/json',
      },

      body: jsonEncode(log),
    );

    if (response.statusCode != 200) {

      throw Exception(
        'Could not save symptoms',
      );
    }
  }


  // ==================================================
  // AI CHAT
  // ==================================================

  static Future<String> sendChatMessage(
    String message, {
    List<Map<String, String>> history =
        const [],
  }) async {

    final response = await http.post(

      Uri.parse(
        '$baseUrl/chat',
      ),

      headers: {
        'Content-Type':
            'application/json',
      },

      body: jsonEncode({
        'message': message,
        'history': history,
      }),
    );

    if (response.statusCode != 200) {

      throw Exception(
        'Could not reach Asha AI',
      );
    }

    final data =
        jsonDecode(response.body);

    return data['reply']?.toString() ??
        'Sorry, I could not respond.';
  }


  // ==================================================
  // NOTIFICATIONS
  // ==================================================

  static Future<List<AshaNotification>>
      fetchNotifications({
    required String userId,
  }) async {

    final response = await http.get(

      Uri.parse(
        '$baseUrl/notifications/$userId',
      ),
    );

    if (response.statusCode != 200) {

      throw Exception(
        'Could not load notifications',
      );
    }

    final body =
        jsonDecode(response.body);

    final List list =
        body['notifications'] ?? [];

    return list
        .map(
          (item) =>
              AshaNotification.fromJson(
            Map<String, dynamic>.from(item),
          ),
        )
        .toList();
  }


  // ==================================================
  // FIND DOCTORS
  // ==================================================

  static Future<List<Doctor>> findDoctors(
    double lat,
    double lng,
  ) async {

    final response = await http.get(

      Uri.parse(
        '$baseUrl/doctors'
        '?lat=$lat&lng=$lng',
      ),
    );

    if (response.statusCode != 200) {

      throw Exception(
        'Could not find nearby doctors',
      );
    }

    final body =
        jsonDecode(response.body);

    final List results =
        body['results'] ?? [];

    return results
        .map(
          (item) =>
              Doctor.fromJson(
            Map<String, dynamic>.from(item),
          ),
        )
        .toList();
  }


  // ==================================================
  // GEOCODE
  // ==================================================

  static Future<Map<String, dynamic>>
      geocodeAddress(
    String address,
  ) async {

    final response = await http.get(

      Uri.parse(
        '$baseUrl/geocode'
        '?address='
        '${Uri.encodeComponent(address)}',
      ),
    );

    if (response.statusCode != 200) {

      throw Exception(
        'Location not found',
      );
    }

    return Map<String, dynamic>.from(
      jsonDecode(response.body),
    );
  }
}