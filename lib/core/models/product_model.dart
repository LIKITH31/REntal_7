import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math' as math;

class ProductModel {
  final String id;
  final String title;
  final String description;
  final String categoryId; // Added categoryId
  final String categoryName; // Denormalized name
  final double rentalPricePerDay;
  final double? rentalPricePerWeek;
  final double? rentalPricePerMonth;
  final double? salePrice;
  final double? securityDeposit;
  final List<String> images;
  final String ownerId;
  final String ownerName;
  final ProductLocation location;
  final DateTime createdAt;
  final DateTime updatedAt; // Added
  final String status; // pending, approved, rejected, processing, unavailable
  final Map<String, dynamic>? specifications;
  final double? originalPrice;
  final String? dimensions;
  final double averageRating;
  final int reviewCount;
  final bool isFlagged; // Added for admin flagging
  final bool isActive; // Added to match schema
  final int riskScore; // Added to match schema

  // Additional review aggregation fields
  final double? itemConditionAvg; // Average condition rating from reviews
  final double? communicationAvg; // Average communication rating
  final String transactionMode; // 'rent' or 'sell'

  const ProductModel({
    required this.id,
    required this.title,
    required this.description,
    required this.categoryId,
    required this.categoryName,
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
    required this.updatedAt,
    required this.status,
    this.specifications,
    this.originalPrice,
    this.dimensions,
    this.averageRating = 0.0,
    this.reviewCount = 0,
    this.isFlagged = false,
    this.isActive = true, // Default true
    this.riskScore = 0, // Default 0
    this.itemConditionAvg,
    this.communicationAvg,
    this.transactionMode = 'rent',
  });

  factory ProductModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ProductModel(
      id: doc.id,
      title:
          data['name'] ??
          data['title'] ??
          '', // Map 'name' from DB to 'title' in app
      description: data['description'] ?? '',
      categoryId: data['categoryId'] ?? '',
      categoryName: data['categoryName'] ?? data['category'] ?? 'Uncategorized',
      rentalPricePerDay: _parseDouble(
        data['price'] ?? data['rentalPricePerDay'],
      ),
      rentalPricePerWeek: _parseDouble(data['rentalPricePerWeek']),
      rentalPricePerMonth: _parseDouble(data['rentalPricePerMonth']),
      salePrice: _parseDouble(data['salePrice']),
      securityDeposit: _parseDouble(data['securityDeposit']),
      images: List<String>.from(data['images'] ?? []),
      ownerId: data['ownerId'] ?? '',
      ownerName: data['ownerName'] ?? '',
      location: ProductLocation.fromMap(data['location'] ?? {}),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: data['status'] ?? 'pending',
      specifications: data['specifications'],
      originalPrice: _parseDouble(data['originalPrice']),
      dimensions: data['dimensions'],
      averageRating: _parseDouble(data['averageRating']),
      reviewCount: _parseInt(data['reviewCount']),
      isFlagged: data['isFlagged'] ?? false,
      isActive: data['isActive'] ?? true,
      riskScore: _parseInt(data['riskScore']),
      itemConditionAvg: _parseDouble(data['itemConditionAvg']),
      communicationAvg: _parseDouble(data['communicationAvg']),
      transactionMode: data['transactionMode'] ?? 'rent',
    );
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': title, // Screenshot uses 'name'
      'price': rentalPricePerDay, // Screenshot uses 'price'
      'categoryId': categoryId,
      'categoryName': categoryName,
      'createdAt': Timestamp.fromDate(createdAt),
      'isActive': isActive,
      'isFlagged': isFlagged,
      'riskScore': riskScore,
      'status': status,

      // Keeping these system fields as they are required for App Logic
      'description': description,
      'updatedAt': Timestamp.fromDate(updatedAt),
      'rentalPricePerWeek': rentalPricePerWeek,
      'rentalPricePerMonth': rentalPricePerMonth,
      'salePrice': salePrice,
      'securityDeposit': securityDeposit,
      'images': images,
      'ownerId': ownerId,
      'ownerName': ownerName,
      'location': location.toMap(),
      'specifications': specifications,
      'originalPrice': originalPrice,
      'dimensions': dimensions,
      'averageRating': averageRating,
      'reviewCount': reviewCount,
      'itemConditionAvg': itemConditionAvg,
      'communicationAvg': communicationAvg,
      'transactionMode': transactionMode,
    };
  }
}

class ProductLocation {
  final double latitude;
  final double longitude;
  final String address;
  final String? city;
  final String? state;
  final String? country;
  final GeoPoint geoPoint;

  ProductLocation({
    required this.latitude,
    required this.longitude,
    required this.address,
    this.city,
    this.state,
    this.country,
  }) : geoPoint = GeoPoint(latitude, longitude);

  double distanceFrom(double lat, double lng) {
    const double earthRadius = 6371; // km
    final double dLat = _toRadians(lat - latitude);
    final double dLng = _toRadians(lng - longitude);

    final double a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(latitude)) *
            math.cos(_toRadians(lat)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);

    final double c = 2 * math.asin(math.sqrt(a));
    return earthRadius * c;
  }

  double _toRadians(double degrees) {
    return degrees * (math.pi / 180);
  }

  factory ProductLocation.fromMap(Map<String, dynamic> map) {
    final geoPoint = map['geoPoint'] as GeoPoint?;
    double lat = geoPoint?.latitude ?? map['lat'] ?? map['latitude'] ?? 0.0;
    double lng = geoPoint?.longitude ?? map['lng'] ?? map['longitude'] ?? 0.0;

    return ProductLocation(
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
      'lat': latitude,
      'lng': longitude,
      'geoPoint': geoPoint,
      'address': address,
      'city': city,
      'state': state,
      'country': country,
    };
  }
}
