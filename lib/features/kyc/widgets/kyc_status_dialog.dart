import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../../../core/models/kyc_model.dart';
import 'kyc_progress_indicator.dart';

class KycStatusDialog extends StatelessWidget {
  final KycModel kycData;
  final VoidCallback? onStartKyc;
  final VoidCallback? onResubmit;

  const KycStatusDialog({
    super.key,
    required this.kycData,
    this.onStartKyc,
    this.onResubmit,
  });

  static Future<void> show({
    required BuildContext context,
    required KycModel kycData,
    VoidCallback? onStartKyc,
    VoidCallback? onResubmit,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => KycStatusDialog(
        kycData: kycData,
        onStartKyc: onStartKyc,
        onResubmit: onResubmit,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
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
                color: _getStatusColor(context).withOpacity(0.1),
              ),
              child: Icon(
                _getStatusIcon(),
                size: 30,
                color: _getStatusColor(context),
              ),
            ),

            const SizedBox(height: 16),

            // Title
            Text(
              _getTitle(),
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 12),

            // Progress Indicator
            KycProgressIndicator(kycData: kycData, showText: true),

            const SizedBox(height: 16),

            // Description
            Text(
              _getDescription(),
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 20),

            // Action Buttons
            _buildActionButtons(context),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    switch (kycData.status) {
      case 'not_submitted':
        return Column(
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
                onPressed: () {
                  debugPrint('🔍 KYC Dialog: User pressed "Maybe Later"');
                  Navigator.of(context).pop();
                },
                child: const Text('Maybe Later'),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        );

      case 'pending':
        return SizedBox(
          width: double.infinity,
          child: TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        );

      case 'rejected':
        return Column(
          children: [
            // Resubmit Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                  onResubmit?.call();
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Resubmit Documents'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
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
        );

      case 'approved':
      default:
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Great!'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        );
    }
  }

  String _getTitle() {
    switch (kycData.status) {
      case 'not_submitted':
        return 'KYC Verification Required';
      case 'pending':
        return 'KYC Under Review';
      case 'rejected':
        return 'KYC Verification Failed';
      case 'approved':
        return 'KYC Verified Successfully';
      default:
        return 'KYC Status';
    }
  }

  String _getDescription() {
    switch (kycData.status) {
      case 'not_submitted':
        return 'To list or book items on our platform, you need to complete KYC verification. This helps us maintain a safe and trusted community.';
      case 'pending':
        return 'Your KYC documents are being reviewed by our team. You\'ll receive a notification once the review is complete. Thank you for your patience!';
      case 'rejected':
        return 'Your KYC verification was rejected. Please check the reason above and resubmit your documents with the correct information.';
      case 'approved':
        return 'Congratulations! Your KYC verification is complete. You can now enjoy all features of our platform including listing and booking items.';
      default:
        return 'Please complete your KYC verification to continue.';
    }
  }

  Color _getStatusColor(BuildContext context) {
    switch (kycData.status) {
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'pending':
        return Colors.orange;
      default:
        return Theme.of(context).primaryColor;
    }
  }

  IconData _getStatusIcon() {
    switch (kycData.status) {
      case 'approved':
        return Icons.verified;
      case 'rejected':
        return Icons.error;
      case 'pending':
        return Icons.hourglass_empty;
      default:
        return Icons.security;
    }
  }
}
