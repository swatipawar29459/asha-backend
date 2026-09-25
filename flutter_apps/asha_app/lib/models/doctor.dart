class Doctor {
  final String name;
  final String type;
  final String address;
  final String? phone;
  final String? website;
  final String? openingHours;
  final double lat;
  final double lng;

  Doctor({
    required this.name,
    required this.type,
    required this.address,
    required this.lat,
    required this.lng,
    this.phone,
    this.website,
    this.openingHours,
  });

  factory Doctor.fromJson(Map<String, dynamic> json) {
    return Doctor(
      name: json['name']?.toString() ?? 'Unnamed healthcare provider',
      type: json['type']?.toString() ?? 'Healthcare',
      address: json['address']?.toString() ?? '',
      phone: _nullable(json['phone']),
      website: _nullable(json['website']),
      openingHours: _nullable(json['opening_hours']),
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
    );
  }

  static String? _nullable(dynamic value) {
    final text = value?.toString().trim();

    if (text == null || text.isEmpty) {
      return null;
    }

    return text;
  }
}