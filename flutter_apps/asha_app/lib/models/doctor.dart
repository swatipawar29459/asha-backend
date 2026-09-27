// ============================================================
// DOCTOR / HEALTHCARE FACILITY MODEL
// ============================================================

class Doctor {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final String? address;
  final String type;
  final double? rating;
  final bool? isOpen;

  Doctor({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    this.address,
    required this.type,
    this.rating,
    this.isOpen,
  });

  factory Doctor.fromJson(
    Map<String, dynamic> json,
  ) {
    return Doctor(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ??
          'Unknown healthcare facility',
      latitude:
          (json['latitude'] as num?)
                  ?.toDouble() ??
              0.0,
      longitude:
          (json['longitude'] as num?)
                  ?.toDouble() ??
              0.0,
      address:
          json['address']?.toString(),
      type:
          json['type']?.toString() ??
              'medical_clinic',
      rating:
          (json['rating'] as num?)
              ?.toDouble(),
      isOpen:
          json['is_open'] is bool
              ? json['is_open'] as bool
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'type': type,
      'rating': rating,
      'is_open': isOpen,
    };
  }

  @override
  String toString() {
    return 'Doctor('
        'id: $id, '
        'name: $name, '
        'latitude: $latitude, '
        'longitude: $longitude, '
        'type: $type, '
        'rating: $rating, '
        'isOpen: $isOpen'
        ')';
  }
}

// ============================================================
// DOCTOR DETAILS MODEL
// ============================================================

class DoctorDetails {
  final String? address;
  final String? phone;
  final String? website;
  final Map<String, dynamic>? openingHours;
  final double? rating;
  final List<Map<String, dynamic>>? reviews;

  DoctorDetails({
    this.address,
    this.phone,
    this.website,
    this.openingHours,
    this.rating,
    this.reviews,
  });

  factory DoctorDetails.fromJson(
    Map<String, dynamic> json,
  ) {
    return DoctorDetails(
      address:
          json['address']?.toString(),
      phone:
          json['phone']?.toString(),
      website:
          json['website']?.toString(),
      openingHours:
          json['opening_hours']
              is Map<String, dynamic>
          ? json['opening_hours']
              as Map<String, dynamic>
          : null,
      rating:
          (json['rating'] as num?)
              ?.toDouble(),
      reviews:
          json['reviews'] is List
              ? (json['reviews'] as List)
                  .whereType<
                      Map<String, dynamic>>()
                  .toList()
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'address': address,
      'phone': phone,
      'website': website,
      'opening_hours': openingHours,
      'rating': rating,
      'reviews': reviews,
    };
  }

  @override
  String toString() {
    return 'DoctorDetails('
        'address: $address, '
        'phone: $phone, '
        'website: $website'
        ')';
  }
}