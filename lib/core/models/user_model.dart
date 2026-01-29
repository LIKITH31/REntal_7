import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String displayName;
  final String? photoURL;
  final DateTime createdAt;
  final int itemsListed;
  final int rentalsCount;
  final double rating;
  final List<String> favorites;
  final int reviewCount;

  // New Fields for Role & KYC
  final String role; // 'user', 'admin'
  final String kycStatus; // 'not_submitted', 'pending', 'approved', 'rejected'
  final DateTime? kycApprovedAt; // When KYC was approved

  // Subscription Fields
  final String subscriptionTier; // 'basic', 'premium'
  final String subscriptionStatus; // 'active', 'expired', 'none'
  final DateTime? subscriptionExpiry;

  const UserModel({
    required this.uid,
    required this.email,
    required this.displayName,
    this.photoURL,
    required this.createdAt,
    this.itemsListed = 0,
    this.rentalsCount = 0,
    this.rating = 0.0,
    this.favorites = const [],
    this.role = 'user',
    this.kycStatus = 'not_submitted',
    this.kycApprovedAt,
    this.subscriptionTier = 'basic',
    this.subscriptionStatus = 'none',
    this.subscriptionExpiry,
    this.reviewCount = 0,
  });

  bool get isAdmin => role == 'admin';
  bool get isKycApproved => kycStatus == 'approved' || kycStatus == 'verified';

  // Enhanced KYC status checks
  bool get needsKycCompletion => kycStatus == 'not_submitted';
  bool get isKycPending => kycStatus == 'pending';
  bool get isKycRejected => kycStatus == 'rejected';

  // Action permission checks
  bool get canListItems => isKycApproved;
  bool get canBookItems => isKycApproved;
  bool get canPerformActions => isKycApproved;

  // KYC status display text
  String get kycStatusDisplayText {
    switch (kycStatus) {
      case 'not_submitted':
        return 'Complete Your Profile';
      case 'pending':
        return 'Under Review';
      case 'approved':
      case 'verified':
        return 'Verified';
      case 'rejected':
        return 'Needs Attention';
      default:
        return 'Unknown';
    }
  }

  bool get isPremium =>
      ['renter_plus', 'lender_pro', 'pro_max'].contains(subscriptionTier);

  bool get hasReducedFees =>
      ['renter_plus', 'lender_pro', 'pro_max'].contains(subscriptionTier);

  bool get hasUnlimitedListings =>
      ['lender_pro', 'pro_max'].contains(subscriptionTier);

  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'photoURL': photoURL,
      'createdAt': Timestamp.fromDate(createdAt),
      'itemsListed': itemsListed,
      'rentalsCount': rentalsCount,
      'rating': rating,
      'favorites': favorites,
      'role': role,
      'kycStatus': kycStatus,
      'kycApprovedAt': kycApprovedAt != null
          ? Timestamp.fromDate(kycApprovedAt!)
          : null,
      'subscriptionTier': subscriptionTier,
      'subscriptionStatus': subscriptionStatus,
      'subscriptionExpiry': subscriptionExpiry != null
          ? Timestamp.fromDate(subscriptionExpiry!)
          : null,
      'reviewCount': reviewCount,
    };
  }

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: data['uid'] ?? '',
      email: data['email'] ?? '',
      displayName: data['displayName'] ?? 'User',
      photoURL: data['photoURL'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      itemsListed: data['itemsListed'] ?? 0,
      rentalsCount: data['rentalsCount'] ?? 0,
      rating: (data['rating'] ?? 0).toDouble(),
      favorites: List<String>.from(data['favorites'] ?? []),
      role: data['role'] ?? 'user',
      kycStatus: data['kycStatus'] ?? 'not_submitted',
      kycApprovedAt: (data['kycApprovedAt'] as Timestamp?)?.toDate(),
      subscriptionTier: data['subscriptionTier'] ?? 'basic',
      subscriptionStatus: data['subscriptionStatus'] ?? 'none',
      subscriptionExpiry: (data['subscriptionExpiry'] as Timestamp?)?.toDate(),
      reviewCount: data['reviewCount'] ?? 0,
    );
  }

  UserModel copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? photoURL,
    DateTime? createdAt,
    int? itemsListed,
    int? rentalsCount,
    double? rating,
    List<String>? favorites,
    String? role,
    String? kycStatus,
    String? subscriptionTier,
    String? subscriptionStatus,
    DateTime? subscriptionExpiry,
    int? reviewCount,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoURL: photoURL ?? this.photoURL,
      createdAt: createdAt ?? this.createdAt,
      itemsListed: itemsListed ?? this.itemsListed,
      rentalsCount: rentalsCount ?? this.rentalsCount,
      rating: rating ?? this.rating,
      favorites: favorites ?? this.favorites,
      role: role ?? this.role,
      kycStatus: kycStatus ?? this.kycStatus,
      subscriptionTier: subscriptionTier ?? this.subscriptionTier,
      subscriptionStatus: subscriptionStatus ?? this.subscriptionStatus,
      subscriptionExpiry: subscriptionExpiry ?? this.subscriptionExpiry,
      reviewCount: reviewCount ?? this.reviewCount,
    );
  }
}
