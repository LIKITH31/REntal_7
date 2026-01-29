import 'package:cloud_firestore/cloud_firestore.dart';

class BookingRequestModel {
  final String id;
  final String productId;
  final String renterId;
  final String ownerId;
  final DateTime startDate;
  final DateTime endDate;
  final double totalPrice;
  final String status; // 'pending', 'approved', 'rejected'
  final DateTime createdAt;
  
  // UI Helpers
  final String productName;
  final String? productImage;
  final String renterName; // Denormalized for Admin UI

  BookingRequestModel({
    required this.id,
    required this.productId,
    required this.renterId,
    required this.ownerId,
    required this.startDate,
    required this.endDate,
    required this.totalPrice,
    this.status = 'pending',
    required this.createdAt,
    required this.productName,
    this.productImage,
    required this.renterName,
  });

  factory BookingRequestModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return BookingRequestModel(
      id: doc.id,
      productId: data['productId'] ?? '',
      renterId: data['buyerId'] ?? data['renterId'] ?? '', // Support both for safety
      ownerId: data['ownerId'] ?? '',
      startDate: (data['startDate'] as Timestamp).toDate(),
      endDate: (data['endDate'] as Timestamp).toDate(),
      totalPrice: (data['totalPrice'] ?? 0).toDouble(),
      status: data['status'] ?? 'pending',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      productName: data['productName'] ?? '',
      productImage: data['productImage'],
      renterName: data['renterName'] ?? 'Unknown',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'productId': productId,
      'buyerId': renterId, // Rule requires 'buyerId'
      'ownerId': ownerId,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'totalPrice': totalPrice,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'productName': productName,
      'productImage': productImage,
      'renterName': renterName,
    };
  }
}
