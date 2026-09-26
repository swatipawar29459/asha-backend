
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
      name: json['name']?.toString().trim().isNotEmpty == true
          ? json['name'].toString().trim()
          : 'Healthcare provider',
      type: json['type']?.toString() ?? 'healthcare',
      address: json['address']?.toString() ?? '',
      phone: _optionalString(json['phone']),
      website: _optionalString(json['website']),
      openingHours: _optionalString(json['opening_hours']),
      lat: _toDouble(json['lat']),
      lng: _toDouble(json['lng']),
    );
  }

  static String? _optionalString(dynamic value) {
    if (value == null) {
      return null;
    }

    final text = value.toString().trim();

    if (text.isEmpty || text == 'null') {
      return null;
    }

    return text;
  }

  static double _toDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
          value?.toString() ?? '',
        ) ??
        0.0;
  }
}
