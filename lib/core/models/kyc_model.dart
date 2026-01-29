import 'package:cloud_firestore/cloud_firestore.dart';

class KycModel {
  final String userId;
  final String status; // not_submitted, pending, approved, rejected

  // Personal Details (collected in app)
  final String? fullName;
  final String? address;
  final String? phone;
  final String? email;

  // Document Information
  final String documentType; // aadhaar, pan, driving_license
  final String? documentNumber; // Masked for security (last 4 digits only)
  final String? documentUrl;
  final String? selfieUrl;

  // Verification Details
  final DateTime? submittedAt;
  final DateTime? verifiedAt;
  final String? verifiedBy; // Admin user ID

  // Rejection/Resubmission Tracking
  final String? rejectionReason;
  final int resubmissionCount;
  final DateTime? lastRejectedAt;

  // Progress Tracking
  final int completionStep; // 1=personal, 2=documents, 3=submitted
  final String? estimatedApprovalTime; // "24-48 hours"

  final DateTime createdAt;
  final DateTime updatedAt;

  KycModel({
    required this.userId,
    required this.status,
    this.fullName,
    this.address,
    this.phone,
    this.email,
    required this.documentType,
    this.documentNumber,
    this.documentUrl,
    this.selfieUrl,
    this.submittedAt,
    this.verifiedAt,
    this.verifiedBy,
    this.rejectionReason,
    this.resubmissionCount = 0,
    this.lastRejectedAt,
    this.completionStep = 0,
    this.estimatedApprovalTime,
    required this.createdAt,
    required this.updatedAt,
  });

  // Security: Mask document number (show only last 4 digits)
  String get maskedDocumentNumber {
    if (documentNumber == null || documentNumber!.length <= 4) {
      return documentNumber ?? '';
    }
    return '****-****-${documentNumber!.substring(documentNumber!.length - 4)}';
  }

  // Progress percentage for UI
  double get progressPercentage {
    switch (status) {
      case 'not_submitted':
        return completionStep * 0.25; // 0%, 25%, 50%, 75% during form filling
      case 'pending':
        return 0.8; // 80% when submitted and pending review
      case 'approved':
        return 1.0; // 100% when approved
      case 'rejected':
        return 0.1; // Reset to 10% to encourage resubmission
      default:
        return 0.0;
    }
  }

  // Status display text
  String get statusDisplayText {
    switch (status) {
      case 'not_submitted':
        return 'Complete Your Profile';
      case 'pending':
        return 'Under Review';
      case 'approved':
        return 'Verified';
      case 'rejected':
        return 'Needs Attention';
      default:
        return 'Unknown';
    }
  }

  // Can user perform actions (book/list items)
  bool get canPerformActions => status == 'approved';

  factory KycModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return KycModel(
      userId: doc.id,
      status: data['status'] ?? 'not_submitted',
      fullName: data['fullName'],
      address: data['address'],
      phone: data['phone'],
      email: data['email'],
      documentType: data['documentType'] ?? 'aadhaar',
      documentNumber: data['documentNumber'],
      documentUrl: data['documentUrl'],
      selfieUrl: data['selfieUrl'],
      submittedAt: (data['submittedAt'] as Timestamp?)?.toDate(),
      verifiedAt: (data['verifiedAt'] as Timestamp?)?.toDate(),
      verifiedBy: data['verifiedBy'],
      rejectionReason: data['rejectionReason'],
      resubmissionCount: data['resubmissionCount'] ?? 0,
      lastRejectedAt: (data['lastRejectedAt'] as Timestamp?)?.toDate(),
      completionStep: data['completionStep'] ?? 0,
      estimatedApprovalTime: data['estimatedApprovalTime'] ?? '24-48 hours',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'documentType': documentType,
      'documentUrl': documentUrl ?? '',
      'selfieUrl': selfieUrl ?? '',
      'status': status,
      'submittedAt': submittedAt != null ? Timestamp.fromDate(submittedAt!) : null,
      'verifiedAt': verifiedAt != null ? Timestamp.fromDate(verifiedAt!) : null,
      'verifiedBy': verifiedBy,
    };
  }

  // Helper method to create a new KYC record for a user
  factory KycModel.createNew(String userId) {
    final now = DateTime.now();
    return KycModel(
      userId: userId,
      status: 'not_submitted',
      documentType: 'aadhaar',
      completionStep: 0,
      estimatedApprovalTime: '24-48 hours',
      createdAt: now,
      updatedAt: now,
    );
  }

  // Helper method to update progress step
  KycModel copyWithStep(int step, {Map<String, dynamic>? additionalData}) {
    return KycModel(
      userId: userId,
      status: step >= 3 ? 'pending' : status,
      fullName: additionalData?['fullName'] ?? fullName,
      address: additionalData?['address'] ?? address,
      phone: additionalData?['phone'] ?? phone,
      email: additionalData?['email'] ?? email,
      documentType: additionalData?['documentType'] ?? documentType,
      documentNumber: additionalData?['documentNumber'] ?? documentNumber,
      documentUrl: additionalData?['documentUrl'] ?? documentUrl,
      selfieUrl: additionalData?['selfieUrl'] ?? selfieUrl,
      submittedAt: step >= 3 ? (submittedAt ?? DateTime.now()) : submittedAt,
      verifiedAt: verifiedAt,
      verifiedBy: verifiedBy,
      rejectionReason: rejectionReason,
      resubmissionCount: resubmissionCount,
      lastRejectedAt: lastRejectedAt,
      completionStep: step,
      estimatedApprovalTime: estimatedApprovalTime,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}
