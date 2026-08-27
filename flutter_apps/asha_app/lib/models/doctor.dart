class Doctor {
  final String name;
  final double lat;
  final double lng;
  Doctor({required this.name, required this.lat, required this.lng});
  factory Doctor.fromJson(Map<String, dynamic> j) => Doctor(
        name: j['name'] ?? 'Unnamed clinic',
        lat: (j['lat'] as num).toDouble(),
        lng: (j['lng'] as num).toDouble(),
      );
}