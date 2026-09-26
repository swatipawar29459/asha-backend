// ============================================================
// DOCTOR MODEL
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

  factory Doctor.fromJson(Map<String, dynamic> json) {
    return Doctor(
      id: json['id'] ?? '',
      name: json['name'] ?? 'Unknown',
      latitude:
          (json['latitude'] as num?)?.toDouble() ?? 0,
      longitude:
          (json['longitude'] as num?)?.toDouble() ?? 0,
      address: json['address'],
      type: json['type'] ?? 'hospital',
      rating: (json['rating'] as num?)?.toDouble(),
      isOpen: json['is_open'],
    );
  }

  get openingHours => null;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'latitude': latitude,
        'longitude': longitude,
        'address': address,
        'type': type,
        'rating': rating,
        'is_open': isOpen,
      };

  @override
  String toString() => 'Doctor(name: $name, rating: $rating)';
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

  factory DoctorDetails.fromJson(Map<String, dynamic> json) {
    return DoctorDetails(
      address: json['address'],
      phone: json['phone'],
      website: json['website'],
      openingHours:
          json['opening_hours'] as Map<String, dynamic>?,
      rating: (json['rating'] as num?)?.toDouble(),
      reviews: (json['reviews'] as List<dynamic>?)
          ?.cast<Map<String, dynamic>>(),
    );
  }

  Map<String, dynamic> toJson() => {
        'address': address,
        'phone': phone,
        'website': website,
        'opening_hours': openingHours,
        'rating': rating,
        'reviews': reviews,
      };

  @override
  String toString() => 'DoctorDetails(address: $address, phone: $phone)';
}