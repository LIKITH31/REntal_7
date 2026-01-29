import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../core/providers/items_provider.dart';
import 'mock_payment_gateway_dialog.dart';

class SubscriptionPaymentScreen extends ConsumerStatefulWidget {
  final String tierId;
  final String tierName;
  final double amount;
  final String billingCycle;

  const SubscriptionPaymentScreen({
    super.key,
    required this.tierId,
    required this.tierName,
    required this.amount,
    required this.billingCycle,
  });

  @override
  ConsumerState<SubscriptionPaymentScreen> createState() => _SubscriptionPaymentScreenState();
}

class _SubscriptionPaymentScreenState extends ConsumerState<SubscriptionPaymentScreen> {
  bool _isProcessing = false;
  int _selectedMethod = 0;

  Future<void> _processPayment() async {
    setState(() => _isProcessing = true);

    // Simulate Network Delay (Processing the 'backend' confirmation)
    await Future.delayed(const Duration(seconds: 1));

    try {
      final user = ref.read(currentUserProvider);
      if (user == null) return;

      final duration = widget.billingCycle == 'yearly' ? const Duration(days: 365) : const Duration(days: 30);
      final expiryDate = DateTime.now().add(duration);

      // Update Subscription (Uses new 'subscriptions' collection path via service)
      await ref.read(firestoreServiceProvider).updateSubscription(
        user.uid, 
        widget.tierId, 
        expiryDate,
        widget.amount,
        _getPaymentMethodName(_selectedMethod),
      );

      if (mounted) {
        // Navigate to Success
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const SubscriptionSuccessScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  String _getPaymentMethodName(int index) {
    switch (index) {
      case 0: return 'Credit / Debit Card';
      case 1: return 'UPI';
      case 2: return 'QR Code';
      case 3: return 'Netbanking';
      case 4: return 'Wallet';
      default: return 'Unknown';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Subscription Payment')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order Summary
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Plan', style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w600)),
                      Text('${widget.tierName} (${widget.billingCycle})', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
                    ],
                  ),
                  const Divider(height: 24, thickness: 1),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Payable', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                      Text(
                        '₹${widget.amount.toStringAsFixed(0)}', 
                        style: const TextStyle(
                          fontWeight: FontWeight.bold, 
                          fontSize: 20,
                          color: Color(0xFF781C2E), 
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            const Text('Payment Method', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 16),
            
            _buildMethodTile(0, 'Credit / Debit Card', Icons.credit_card),
            _buildMethodTile(1, 'UPI (Google Pay / PhonePe)', Icons.qr_code_scanner),
            _buildMethodTile(2, 'Scan QR Code', Icons.qr_code_2),
            _buildMethodTile(3, 'Netbanking', Icons.account_balance),
            _buildMethodTile(4, 'Wallets', Icons.account_balance_wallet),

            const SizedBox(height: 48),

            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _isProcessing ? null : _openPaymentGateway,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF781C2E),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isProcessing 
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('PROCEED TO PAY', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMethodTile(int index, String title, IconData icon) {
    // Selection logic remains for 'preference', but actual entry happens in gateway
    final isSelected = _selectedMethod == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedMethod = index),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: isSelected ? const Color(0xFF781C2E) : Colors.grey[300]!, width: isSelected ? 2 : 1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? const Color(0xFF781C2E) : Colors.grey),
            const SizedBox(width: 16),
            Text(title, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
            const Spacer(),
            if (isSelected) const Icon(Icons.check_circle, color: Color(0xFF781C2E)),
          ],
        ),
      ),
    );
  }

  void _openPaymentGateway() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => MockPaymentGatewayDialog(
        amount: widget.amount, 
        paymentMethodIndex: _selectedMethod,
        onSuccess: _processPayment,
      ),
    );
  }
}

class SubscriptionSuccessScreen extends StatelessWidget {
  const SubscriptionSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Celebration Icon
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.verified, color: Colors.green, size: 80)
                    .animate().scale(curve: Curves.elasticOut, duration: 800.ms)
                    .then().shake(hz: 4, curve: Curves.easeInOut),
              ),
              const SizedBox(height: 32),
              
              const Text(
                'Payment Successful!', 
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black87)
              ).animate().fadeIn().moveY(begin: 10, end: 0),
              
              const SizedBox(height: 12),
              Text(
                'Your subscription is now active.', 
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 48),
              
              // Plan Card
              Container(
                width: double.infinity,
                constraints: const BoxConstraints(maxWidth: 400),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFF781C2E), // Brand Color
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(color: const Color(0xFF781C2E).withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))
                  ]
                ),
                child: Column(
                  children: [
                    const Text(
                      'CURRENT PLAN', 
                      style: TextStyle(color: Colors.white70, fontSize: 12, letterSpacing: 1.5, fontWeight: FontWeight.bold)
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Lender Pro', 
                      style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text('Active', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                    const SizedBox(height: 24),
                    const Divider(color: Colors.white24),
                    const SizedBox(height: 16),
                    const Text(
                       'Thank you for upgrading with us.',
                       style: TextStyle(color: Colors.white70, fontStyle: FontStyle.italic),
                    )
                  ],
                ),
              ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2, end: 0),
              
              const SizedBox(height: 64),
              
              SizedBox(
                width: 200,
                height: 50,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black87,
                    elevation: 1,
                    side: BorderSide(color: Colors.grey.shade300),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                  child: const Text('Continue to App', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
