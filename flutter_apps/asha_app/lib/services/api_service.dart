import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/prediction.dart';
import '../models/doctor.dart';
import 'health_profile_store.dart';


// ==================================================
// NOTIFICATION MODEL
// ==================================================

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
 id: json['id'] ?? '',
 type: json['type'] ?? '',
 title: json['title'] ?? '',
 message: json['message'] ?? '',
 time: json['time'] ?? '',
 isRead: json['is_read'] ?? false,
 );
 }
}


// ==================================================
// API SERVICE
// ==================================================

class ApiService {

 // --------------------------------------------------
 // BASE URL
 // --------------------------------------------------

 static const baseUrl =
 'https://vittikapawar.pythonanywhere.com';


 // ==================================================
 // PREDICTION
 // ==================================================

 static Future<Prediction> fetchPrediction({
 required int userId,
 }) async {

 // Get the user's actual profile
 final profile =
 HealthProfileStore.toJson();

 print(
 'Sending prediction data: $profile',
 );

 final res = await http.post(
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
 'Prediction response: '
 '${res.statusCode} ${res.body}',
 );

 if (res.statusCode != 200) {
 throw Exception(
 'Prediction fetch failed: '
 '${res.body}',
 );
 }

 return Prediction.fromJson(
 jsonDecode(res.body),
 );
 }


 // ==================================================
 // LOG SYMPTOMS
 // ==================================================

 static Future<void> logSymptoms(
 int userId,
 Map<String, dynamic> log,
 ) async {

 final res = await http.post(
 Uri.parse(
 '$baseUrl/log/$userId',
 ),
 headers: {
 'Content-Type':
 'application/json',
 },
 body: jsonEncode(log),
 );

 if (res.statusCode != 200) {
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

 final res = await http.post(
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

 if (res.statusCode != 200) {
 throw Exception(
 'Could not reach Asha AI',
 );
 }

 final data =
 jsonDecode(res.body);

 return data['reply'];
 }


 // ==================================================
 // NOTIFICATIONS
 // ==================================================

 static Future<List<AshaNotification>>
 fetchNotifications({
 required int userId,
 }) async {

 final res = await http.get(
 Uri.parse(
 '$baseUrl/notifications/$userId',
 ),
 );

 if (res.statusCode != 200) {
 throw Exception(
 'Could not load notifications',
 );
 }

 final body =
 jsonDecode(res.body);

 final List notifications =
 body['notifications'] ?? [];

 return notifications
 .map(
 (notification) =>
 AshaNotification.fromJson(
 Map<String, dynamic>.from(
 notification,
 ),
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

 final res = await http.get(
 Uri.parse(
 '$baseUrl/doctors'
 '?lat=$lat&lng=$lng',
 ),
 );

 if (res.statusCode != 200) {
 throw Exception(
 'Could not find nearby doctors',
 );
 }

 final body =
 jsonDecode(res.body);

 return (body['results'] as List)
 .map(
 (d) => Doctor.fromJson(d),
 )
 .toList();
 }


 // ==================================================
 // GEOCODE ADDRESS
 // ==================================================

 static Future<Map<String, dynamic>>
 geocodeAddress(
 String address,
 ) async {

 final res = await http.get(
 Uri.parse(
 '$baseUrl/geocode?address='
 '${Uri.encodeComponent(address)}',
 ),
 );

 if (res.statusCode != 200) {
 throw Exception(
 'Location not found',
 );
 }

 return jsonDecode(
 res.body,
 );
 }
}