import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/user_model.dart';
import '../../../core/providers/auth_provider.dart';
import '../helpers/kyc_enforcement.dart';

class KycStatusCard extends ConsumerWidget {
  final VoidCallback? onStartKyc;

  const KycStatusCard({super.key, this.onStartKyc});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userModel = ref.watch(userModelProvider).value;

    if (userModel == null) {
      return const SizedBox.shrink();
    }

    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _getStatusColor(userModel).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getStatusIcon(userModel),
                    color: _getStatusColor(userModel),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'KYC Verification',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        userModel.kycStatusDisplayText,
                        style: TextStyle(
                          color: _getStatusColor(userModel),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                // Status Badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(userModel),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _getStatusBadgeText(userModel),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Progress Indicator (if not approved)
            if (!userModel.isKycApproved) ...[
              // Create a simple progress indicator since we can't access the private method
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _getStatusColor(userModel).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _getStatusColor(userModel).withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: _getProgressValue(userModel),
                          backgroundColor: Colors.grey.shade300,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            _getStatusColor(userModel),
                          ),
                          minHeight: 8,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${(_getProgressValue(userModel) * 100).toInt()}%',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _getStatusColor(userModel),
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Description
            Text(
              _getDescription(userModel),
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
                height: 1.4,
              ),
            ),

            // Benefits (if not approved)
            if (!userModel.isKycApproved) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info, color: Colors.blue.shade600, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          'KYC Benefits',
                          style: TextStyle(
                            color: Colors.blue.shade800,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ...([
                      '✓ List unlimited items for rent',
                      '✓ Book any item instantly',
                      '✓ Higher trust score with other users',
                      '✓ Priority customer support',
                      '✓ Access to premium features',
                    ].map(
                      (benefit) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          benefit,
                          style: TextStyle(
                            color: Colors.blue.shade700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    )),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 16),

            // Action Button
            SizedBox(
              width: double.infinity,
              child: _buildActionButton(context, userModel),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, UserModel userModel) {
    switch (userModel.kycStatus) {
      case 'approved':
        return ElevatedButton.icon(
          onPressed: () => _showKycStatus(context, userModel),
          icon: const Icon(Icons.verified),
          label: const Text('View KYC Status'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );

      case 'pending':
        return ElevatedButton.icon(
          onPressed: () => _showKycStatus(context, userModel),
          icon: const Icon(Icons.hourglass_empty),
          label: const Text('Check Status'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );

      case 'rejected':
        return ElevatedButton.icon(
          onPressed: onStartKyc ?? () => _showKycStatus(context, userModel),
          icon: const Icon(Icons.refresh),
          label: const Text('Resubmit KYC'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );

      default: // not_submitted
        return ElevatedButton.icon(
          onPressed: onStartKyc ?? () => _showKycStatus(context, userModel),
          icon: const Icon(Icons.start),
          label: const Text('Start KYC Verification'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
    }
  }

  void _showKycStatus(BuildContext context, UserModel userModel) {
    KycEnforcement.showKycStatus(
      context: context,
      user: userModel,
      onStartKyc: onStartKyc,
    );
  }

  Color _getStatusColor(UserModel userModel) {
    switch (userModel.kycStatus) {
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'pending':
        return Colors.orange;
      default:
        return Colors.blue;
    }
  }

  IconData _getStatusIcon(UserModel userModel) {
    switch (userModel.kycStatus) {
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

  String _getStatusBadgeText(UserModel userModel) {
    switch (userModel.kycStatus) {
      case 'approved':
        return 'VERIFIED';
      case 'rejected':
        return 'REJECTED';
      case 'pending':
        return 'PENDING';
      default:
        return 'REQUIRED';
    }
  }

  String _getDescription(UserModel userModel) {
    switch (userModel.kycStatus) {
      case 'approved':
        return 'Your identity has been verified successfully. You have full access to all platform features including listing and booking items.';
      case 'rejected':
        return 'Your KYC verification was rejected. Please resubmit your documents with the correct information to continue using the platform.';
      case 'pending':
        return 'Your KYC documents are under review. This usually takes 1-2 business days. You\'ll be notified once the review is complete.';
      default:
        return 'Complete KYC verification to unlock all features including listing items for rent and booking items from other users.';
    }
  }

  double _getProgressValue(UserModel userModel) {
    switch (userModel.kycStatus) {
      case 'approved':
        return 1.0;
      case 'pending':
        return 0.8;
      case 'rejected':
        return 0.3;
      default:
        return 0.1;
    }
  }
}
