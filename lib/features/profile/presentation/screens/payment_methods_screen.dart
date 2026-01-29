import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class PaymentMethodsScreen extends StatelessWidget {
  const PaymentMethodsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Methods'),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Saved Methods Section
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Saved Methods',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
              ),
            ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.withOpacity(0.2)),
              ),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.credit_card_off, size: 48, color: Colors.grey.shade400),
                    const SizedBox(height: 12),
                    const Text('No saved payment methods'),
                  ],
                ),
              ),
            ).animate().fadeIn(),

            const SizedBox(height: 24),

            // Add New Method Section
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Add Payment Method',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
              ),
            ),
            
            _buildPaymentOption(
              context,
              'Credit / Debit Card',
              'Visa, Mastercard, Rupay',
              Icons.credit_card,
              Colors.blue,
              0,
            ),
            _buildPaymentOption(
              context,
              'UPI',
              'Google Pay, PhonePe, Paytm',
              Icons.qr_code_scanner,
              Colors.green,
              100,
            ),
            _buildPaymentOption(
              context,
              'Netbanking',
              'All Indian banks supported',
              Icons.account_balance,
              Colors.orange,
              200,
            ),
            _buildPaymentOption(
              context,
              'Wallets',
              'Amazon Pay, Ola Money, etc.',
              Icons.account_balance_wallet,
              Colors.purple,
              300,
            ),
            
            const SizedBox(height: 24),
            
             // UPI Apps List (Visual Only)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                'Supported UPI Apps',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Colors.grey,
                ),
              ),
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _buildAppPill(context, 'Google Pay', Colors.blue.shade700),
                  _buildAppPill(context, 'PhonePe', Colors.purple.shade700),
                  _buildAppPill(context, 'Paytm', Colors.blue.shade400),
                  _buildAppPill(context, 'BHIM', Colors.green.shade600),
                  _buildAppPill(context, 'Cred', Colors.black),
                ],
              ),
            ).animate().fadeIn(delay: 400.ms).slideX(),
            
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentOption(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color color,
    int delay,
  ) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(color: Colors.grey, fontSize: 12),
      ),
      trailing: const Icon(Icons.chevron_right, size: 20),
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Add $title feature coming soon')),
        );
      },
    ).animate().fadeIn(delay: delay.ms).slideX(begin: -0.1);
  }

  Widget _buildAppPill(BuildContext context, String name, Color color) {
    return Container(
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            name,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
