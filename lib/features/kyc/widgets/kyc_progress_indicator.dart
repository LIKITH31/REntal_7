import 'package:flutter/material.dart';
import '../../../core/models/kyc_model.dart';

class KycProgressIndicator extends StatelessWidget {
  final KycModel kycData;
  final bool showText;

  const KycProgressIndicator({
    super.key,
    required this.kycData,
    this.showText = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _getProgressColor(context).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getProgressColor(context).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Progress Bar
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: kycData.progressPercentage,
                    backgroundColor: Colors.grey.shade300,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _getProgressColor(context),
                    ),
                    minHeight: 8,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${(kycData.progressPercentage * 100).toInt()}%',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: _getProgressColor(context),
                  fontSize: 16,
                ),
              ),
            ],
          ),

          if (showText) ...[
            const SizedBox(height: 12),

            // Status Text
            Row(
              children: [
                Icon(
                  _getStatusIcon(),
                  color: _getProgressColor(context),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  kycData.statusDisplayText,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: _getProgressColor(context),
                    fontSize: 16,
                  ),
                ),
              ],
            ),

            // Step Indicators
            if (kycData.status == 'not_submitted') ...[
              const SizedBox(height: 12),
              _buildStepIndicators(context),
            ],

            // Estimated Time (for pending status)
            if (kycData.status == 'pending') ...[
              const SizedBox(height: 8),
              Text(
                'Estimated approval time: ${kycData.estimatedApprovalTime}',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
              ),
            ],

            // Rejection reason (for rejected status)
            if (kycData.status == 'rejected' &&
                kycData.rejectionReason != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: Colors.red.shade600,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        kycData.rejectionReason!,
                        style: TextStyle(
                          color: Colors.red.shade700,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildStepIndicators(BuildContext context) {
    final steps = [
      {'title': 'Personal Info', 'icon': Icons.person},
      {'title': 'Documents', 'icon': Icons.document_scanner},
      {'title': 'Verification', 'icon': Icons.verified_user},
    ];

    return Row(
      children: steps.asMap().entries.map((entry) {
        final index = entry.key;
        final step = entry.value;
        final isCompleted = kycData.completionStep > index;
        final isCurrent = kycData.completionStep == index;

        return Expanded(
          child: Row(
            children: [
              // Step Circle
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isCompleted
                      ? Colors.green
                      : isCurrent
                      ? Theme.of(context).primaryColor
                      : Colors.grey.shade300,
                ),
                child: Icon(
                  isCompleted ? Icons.check : step['icon'] as IconData,
                  size: 14,
                  color: isCompleted || isCurrent ? Colors.white : Colors.grey,
                ),
              ),

              // Step Text
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  step['title'] as String,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isCurrent ? FontWeight.w600 : FontWeight.normal,
                    color: isCompleted || isCurrent
                        ? Theme.of(context).primaryColor
                        : Colors.grey,
                  ),
                ),
              ),

              // Line to next step (except for last step)
              if (index < steps.length - 1)
                Container(
                  width: 20,
                  height: 2,
                  color: isCompleted ? Colors.green : Colors.grey.shade300,
                ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Color _getProgressColor(BuildContext context) {
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
        return Icons.account_circle;
    }
  }
}
