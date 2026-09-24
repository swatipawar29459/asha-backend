class Doctor {
  final String name;
  final double lat;
  final double lng;
  final String type;

  Doctor({
    required this.name,
    required this.lat,
    required this.lng,
    required this.type,
  });

  factory Doctor.fromJson(
    Map<String, dynamic> json,
  ) {
    return Doctor(
      name: json['name']?.toString() ?? 'Unnamed medical facility',
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
      type: json['type']?.toString() ?? 'Medical facility',
    );
  }
}