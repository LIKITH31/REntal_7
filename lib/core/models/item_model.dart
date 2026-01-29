import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math' as math;

class ItemModel {
  final String id;
  final String title;
  final String description;
  final String category;
  final double rentalPricePerDay;
  final double? rentalPricePerWeek;
  final double? rentalPricePerMonth;
  final double? salePrice;
  final double? securityDeposit;
  final List<String> images;
  final String ownerId;
  final String ownerName;
  final ItemLocation location;
  final DateTime createdAt;
  final String status; // available, rented, sold
  final Map<String, dynamic>? specifications;
  final double? originalPrice; // NEW: Reference price
  final String? dimensions;    // NEW: Dimensions string
  final double averageRating;
  final int reviewCount;

  ItemModel({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.rentalPricePerDay,
    this.rentalPricePerWeek,
    this.rentalPricePerMonth,
    this.salePrice,
    this.securityDeposit,
    required this.images,
    required this.ownerId,
    required this.ownerName,
    required this.location,
    required this.createdAt,
    required this.status,
    this.specifications,
    this.originalPrice,
    this.dimensions,
    this.averageRating = 0.0,
    this.reviewCount = 0,
  });

  // Calculate distance from a given location (in kilometers)
  double distanceFrom(double lat, double lng) {
    return location.distanceFrom(lat, lng);
  }

  factory ItemModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ItemModel(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      category: data['category'] ?? '',
      rentalPricePerDay: (data['rentalPricePerDay'] ?? 0).toDouble(),
      rentalPricePerWeek: data['rentalPricePerWeek']?.toDouble(),
      rentalPricePerMonth: data['rentalPricePerMonth']?.toDouble(),
      salePrice: data['salePrice']?.toDouble(),
      securityDeposit: data['securityDeposit']?.toDouble(),
      images: List<String>.from(data['images'] ?? []),
      ownerId: data['ownerId'] ?? '',
      ownerName: data['ownerName'] ?? '',
      location: ItemLocation.fromMap(data['location'] ?? {}),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: data['status'] ?? 'available',
      specifications: data['specifications'],
      originalPrice: data['originalPrice']?.toDouble(),
      dimensions: data['dimensions'],
      averageRating: (data['averageRating'] ?? 0).toDouble(),
      reviewCount: data['reviewCount'] ?? 0,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'category': category,
      'rentalPricePerDay': rentalPricePerDay,
      'rentalPricePerWeek': rentalPricePerWeek,
      'rentalPricePerMonth': rentalPricePerMonth,
      'salePrice': salePrice,
      'securityDeposit': securityDeposit,
      'images': images,
      'ownerId': ownerId,
      'ownerName': ownerName,
      'location': location.toMap(),
      'createdAt': Timestamp.fromDate(createdAt),
      'status': status,
      'specifications': specifications,
      'originalPrice': originalPrice,
      'dimensions': dimensions,
      'averageRating': averageRating,
      'reviewCount': reviewCount,
    };
  }
}

class ItemLocation {
  final double latitude;
  final double longitude;
  final String address;
  final String? city;
  final String? state;
  final String? country;
  final GeoPoint geoPoint;

  ItemLocation({
    required this.latitude,
    required this.longitude,
    required this.address,
    this.city,
    this.state,
    this.country,
  }) : geoPoint = GeoPoint(latitude, longitude);

  // Haversine formula to calculate distance in kilometers
  double distanceFrom(double lat, double lng) {
    const double earthRadius = 6371; // km
    final double dLat = _toRadians(lat - latitude);
    final double dLng = _toRadians(lng - longitude);
    
    final double a = 
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(latitude)) * math.cos(_toRadians(lat)) *
        math.sin(dLng / 2) * math.sin(dLng / 2);
    
    final double c = 2 * math.asin(math.sqrt(a));
    return earthRadius * c;
  }

  double _toRadians(double degrees) {
    return degrees * (math.pi / 180);
  }

  factory ItemLocation.fromMap(Map<String, dynamic> map) {
    final geoPoint = map['geoPoint'] as GeoPoint?;
    // Support both 'lat'/'lng' (new rules) and 'latitude'/'longitude' (legacy)
    double lat = geoPoint?.latitude ?? map['lat'] ?? map['latitude'] ?? 0.0;
    double lng = geoPoint?.longitude ?? map['lng'] ?? map['longitude'] ?? 0.0;
    
    return ItemLocation(
      latitude: lat,
      longitude: lng,
      address: map['address'] ?? '',
      city: map['city'],
      state: map['state'],
      country: map['country'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'lat': latitude,     // Changed from 'latitude' to match rules
      'lng': longitude,    // Changed from 'longitude' to match rules
      'geoPoint': geoPoint,
      'address': address,
      'city': city,
      'state': state,
      'country': country,
    };
  }
}
