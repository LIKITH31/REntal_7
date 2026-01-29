import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../../../core/models/user_model.dart';
import '../../../core/models/kyc_model.dart';
import '../widgets/kyc_status_dialog.dart';

class KycEnforcement {
  /// Check if user can list items and show appropriate dialog if not
  static Future<bool> canUserListItems({
    required BuildContext context,
    required UserModel user,
    VoidCallback? onStartKyc,
  }) async {
    debugPrint('🔍 KYC: Checking canUserListItems for user ${user.uid}');
    debugPrint('🔍 KYC: User KYC Status: ${user.kycStatus}');
    debugPrint('🔍 KYC: User canListItems: ${user.canListItems}');

    if (user.canListItems) {
      debugPrint('✅ KYC: User can list items');
      return true;
    }

    debugPrint('❌ KYC: User cannot list items - showing dialog');

    // Create KYC model from user's KYC status
    final kycData = KycModel(
      userId: user.uid,
      status: user.kycStatus,
      documentType: 'aadhaar', // Default document type
      submittedAt: null, // Would be populated from separate KYC document
      verifiedAt: user.kycApprovedAt,
      rejectionReason: null, // Would be populated from separate KYC document
      // Default values for missing fields
      fullName: user.displayName,
      email: user.email,
      phone: null,
      address: null,
      documentNumber: null,
      documentUrl: null,
      selfieUrl: null,
      completionStep: 0,
      estimatedApprovalTime: '24-48 hours',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await KycStatusDialog.show(
      context: context,
      kycData: kycData,
      onStartKyc: onStartKyc,
      onResubmit: onStartKyc, // Same action for resubmit
    );

    return false;
  }

  /// Check if user can book items and show appropriate dialog if not
  static Future<bool> canUserBookItems({
    required BuildContext context,
    required UserModel user,
    VoidCallback? onStartKyc,
  }) async {
    debugPrint('🔍 KYC: Checking canUserBookItems for user ${user.uid}');
    debugPrint('🔍 KYC: User KYC Status: ${user.kycStatus}');
    debugPrint('🔍 KYC: User canBookItems: ${user.canBookItems}');

    if (user.canBookItems) {
      debugPrint('✅ KYC: User can book items');
      return true;
    }

    debugPrint('❌ KYC: User cannot book items - showing dialog');

    // Create KYC model from user's KYC status
    final kycData = KycModel(
      userId: user.uid,
      status: user.kycStatus,
      documentType: 'aadhaar', // Default document type
      submittedAt: null, // Would be populated from separate KYC document
      verifiedAt: user.kycApprovedAt,
      rejectionReason: null, // Would be populated from separate KYC document
      // Default values for missing fields
      fullName: user.displayName,
      email: user.email,
      phone: null,
      address: null,
      documentNumber: null,
      documentUrl: null,
      selfieUrl: null,
      completionStep: 0,
      estimatedApprovalTime: '24-48 hours',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await KycStatusDialog.show(
      context: context,
      kycData: kycData,
      onStartKyc: onStartKyc,
      onResubmit: onStartKyc, // Same action for resubmit
    );

    return false;
  }

  /// Generic KYC check with custom action description
  static Future<bool> checkKycAndShowDialog({
    required BuildContext context,
    required UserModel user,
    required String actionDescription, // e.g., "add an item to favorites"
    VoidCallback? onStartKyc,
  }) async {
    if (user.isKycApproved) {
      return true;
    }

    // Create KYC model from user's KYC status
    final kycData = _createKycModelFromUser(user);

    await _showCustomKycDialog(
      context: context,
      kycData: kycData,
      actionDescription: actionDescription,
      onStartKyc: onStartKyc,
    );

    return false;
  }

  /// Show KYC status info (non-blocking)
  static Future<void> showKycStatus({
    required BuildContext context,
    required UserModel user,
    VoidCallback? onStartKyc,
  }) async {
    final kycData = _createKycModelFromUser(user);

    await KycStatusDialog.show(
      context: context,
      kycData: kycData,
      onStartKyc: onStartKyc,
      onResubmit: onStartKyc,
    );
  }

  /// Create a KycModel from UserModel data
  static KycModel _createKycModelFromUser(UserModel user) {
    return KycModel(
      userId: user.uid,
      status: user.kycStatus,
      documentType: 'aadhaar', // Default document type
      submittedAt: null, // Would be populated from separate KYC document
      verifiedAt: user.kycApprovedAt,
      rejectionReason: null, // Would be populated from separate KYC document
      // Default values for missing fields
      fullName: user.displayName,
      email: user.email,
      phone: null,
      address: null,
      documentNumber: null,
      documentUrl: null,
      selfieUrl: null,
      completionStep: _calculateCompletionStep(user.kycStatus),
      estimatedApprovalTime: '24-48 hours',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  /// Calculate completion step based on status
  static int _calculateCompletionStep(String status) {
    switch (status) {
      case 'not_submitted':
        return 0;
      case 'pending':
        return 3; // All steps completed, waiting for approval
      case 'approved':
        return 3;
      case 'rejected':
        return 0; // Reset to beginning for resubmission
      default:
        return 0;
    }
  }

  /// Show custom KYC dialog with action description
  static Future<void> _showCustomKycDialog({
    required BuildContext context,
    required KycModel kycData,
    required String actionDescription,
    VoidCallback? onStartKyc,
  }) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header Icon
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                ),
                child: Icon(
                  Icons.security,
                  size: 30,
                  color: Theme.of(context).primaryColor,
                ),
              ),

              const SizedBox(height: 16),

              // Title
              const Text(
                'KYC Verification Required',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 12),

              // Description
              Text(
                'To $actionDescription, you need to complete KYC verification first. This helps us maintain a safe and trusted community.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 20),

              // Action Buttons
              Column(
                children: [
                  // Start KYC Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                        onStartKyc?.call();
                      },
                      icon: const Icon(Icons.start),
                      label: const Text('Start KYC Verification'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Cancel Button
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Quick status check methods
  static bool isKycRequired(UserModel user) {
    return !user.isKycApproved;
  }

  static bool canPerformAction(UserModel user) {
    return user.isKycApproved;
  }

  static String getKycStatusMessage(UserModel user) {
    return user.kycStatusDisplayText;
  }
}
