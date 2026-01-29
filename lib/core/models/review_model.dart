import 'package:cloud_firestore/cloud_firestore.dart';

// Review Model for /products/{productId}/reviews/{reviewId} subcollection
class ReviewModel {
  final String id;
  final String reviewerId;
  final String reviewerName;
  final String? reviewerImage;

  final double rating; // Overall rating 1-5 stars
  final String comment;
  final String orderId; // Must be valid order with this product
  final String orderType; // rental | sale

  final String reviewType; // product | owner (can rate both)

  final DateTime createdAt;
  final DateTime updatedAt;

  // Optional detailed ratings
  final double? itemConditionRating; // Condition as advertised
  final double? communicationRating; // Owner responsiveness
  final double? deliveryRating; // Pickup/delivery experience
  final double? valueForMoneyRating; // Worth the price

  ReviewModel({
    required this.id,
    required this.reviewerId,
    required this.reviewerName,
    this.reviewerImage,
    required this.rating,
    required this.comment,
    required this.orderId,
    required this.orderType,
    required this.reviewType,
    required this.createdAt,
    required this.updatedAt,
    this.itemConditionRating,
    this.communicationRating,
    this.deliveryRating,
    this.valueForMoneyRating,
  });

  // Legacy constructor for backward compatibility
  factory ReviewModel.legacy({
    required String id,
    required String reviewerId,
    required String reviewerName,
    String? reviewerImage,
    required String targetId,
    required String targetType,
    required double rating,
    required String comment,
    required DateTime createdAt,
    DateTime? updatedAt,
  }) {
    return ReviewModel(
      id: id,
      reviewerId: reviewerId,
      reviewerName: reviewerName,
      reviewerImage: reviewerImage,
      rating: rating,
      comment: comment,
      orderId: targetId, // Map targetId to orderId for legacy support
      orderType: targetType == 'item' ? 'rental' : targetType,
      reviewType: 'product',
      createdAt: createdAt,
      updatedAt: updatedAt ?? createdAt,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'reviewerId': reviewerId,
      'reviewerName': reviewerName,
      'reviewerImage': reviewerImage,
      'rating': rating,
      'comment': comment,
      'orderId': orderId,
      'orderType': orderType,
      'reviewType': reviewType,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'itemConditionRating': itemConditionRating,
      'communicationRating': communicationRating,
      'deliveryRating': deliveryRating,
      'valueForMoneyRating': valueForMoneyRating,
    };
  }

  factory ReviewModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ReviewModel(
      id: doc.id,
      reviewerId: data['reviewerId'] ?? '',
      reviewerName: data['reviewerName'] ?? 'Anonymous',
      reviewerImage: data['reviewerImage'],
      rating: (data['rating'] ?? 0).toDouble(),
      comment: data['comment'] ?? '',
      orderId:
          data['orderId'] ?? data['targetId'] ?? '', // Support legacy targetId
      orderType: data['orderType'] ?? data['targetType'] ?? 'rental',
      reviewType: data['reviewType'] ?? 'product',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      itemConditionRating: (data['itemConditionRating'] as num?)?.toDouble(),
      communicationRating: (data['communicationRating'] as num?)?.toDouble(),
      deliveryRating: (data['deliveryRating'] as num?)?.toDouble(),
      valueForMoneyRating: (data['valueForMoneyRating'] as num?)?.toDouble(),
    );
  }

  // Legacy toFirestore for compatibility
  Map<String, dynamic> toLegacyFirestore() {
    return {
      'reviewerId': reviewerId,
      'reviewerName': reviewerName,
      'reviewerImage': reviewerImage,
      'targetId': orderId, // Map orderId back to targetId
      'targetType': orderType,
      'rating': rating,
      'comment': comment,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  // Helper methods
  bool get hasDetailedRatings =>
      itemConditionRating != null ||
      communicationRating != null ||
      deliveryRating != null ||
      valueForMoneyRating != null;

  double get averageDetailedRating {
    final ratings = [
      itemConditionRating,
      communicationRating,
      deliveryRating,
      valueForMoneyRating,
    ].where((r) => r != null).cast<double>().toList();

    if (ratings.isEmpty) return rating;
    return ratings.reduce((a, b) => a + b) / ratings.length;
  }
}
