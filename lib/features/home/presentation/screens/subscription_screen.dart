import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../core/providers/items_provider.dart';
import '../../../booking/presentation/subscription_payment_screen.dart';

class SubscriptionScreen extends ConsumerStatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  ConsumerState<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends ConsumerState<SubscriptionScreen> {
  bool _isLoading = false;
  String _selectedTierId = 'lender_pro'; // Default selection
  String _selectedBilling = 'monthly'; // 'monthly' or 'yearly'

  // Colors
  static const Color kPrimaryBurgundy = Color(0xFF781C2E);
  static const Color kBackgroundCream = Color(0xFFF9F6EE);
  static const Color kLightBurgundy = Color(0xFF9E2F3C);

  // Plan Definitions
  final List<Map<String, dynamic>> _plans = [
    {
      'id': 'basic',
      'title': 'Basic',
      'subtitle': 'Free Forever',
      'monthly_price': 0,
      'yearly_price': 0,
      'features': ['Browse Items', '5 Listings Limit', '10% Platform Fee'],
      'pitch': 'Start renting or listing for free.',
    },
    {
      'id': 'renter_plus',
      'title': 'Renter Plus',
      'subtitle': 'For Renters',
      'monthly_price': 299,
      'yearly_price': 2999,
      'features': [
        'Faster delivery',
        'Reduced delivery charges',
        '5% Platform Fee (vs 10%)',
        'Priority customer support',
        'Flexible cancellation window',
        'Early access to new listings'
      ],
      'pitch': 'Save time & money on every rental with faster service & lower fees.',
    },
    {
      'id': 'lender_pro',
      'title': 'Lender Pro',
      'subtitle': 'For Lenders',
      'monthly_price': 499,
      'yearly_price': 4999,
      'features': [
        'High visibility (Top of search)',
        '5% Platform Fee (vs 10%)',
        'Unlimited listings (No limit)',
        'Performance insights',
        'Priority support',
        'Faster approval'
      ],
      'pitch': 'Get more exposure, more bookings, and keep more earnings.',
      'popular': true,
    },
    {
      'id': 'pro_max',
      'title': 'Pro Max',
      'subtitle': 'Power Users',
      'monthly_price': 699,
      'yearly_price': 6999,
      'features': [
        'All Renter Plus Benefits',
        'All Lender Pro Benefits',
        'Exclusive Pro Max Badge',
        'Ultimate Priority Support'
      ],
      'pitch': 'The ultimate all-in-one plan for serious renters and lenders.',
    }
  ];

  void _subscribe() {
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    
    // Basic has no action
    if (_selectedTierId == 'basic') {
      Navigator.pop(context);
      return;
    }

    final selectedPlan = _plans.firstWhere((p) => p['id'] == _selectedTierId);
    final price = _selectedBilling == 'yearly' ? selectedPlan['yearly_price'] : selectedPlan['monthly_price'];

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SubscriptionPaymentScreen(
          tierId: _selectedTierId,
          tierName: selectedPlan['title'],
          amount: (price as num).toDouble(),
          billingCycle: _selectedBilling,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Current plan check
    final userModel = ref.watch(userModelProvider).value;
    final currentTier = userModel?.subscriptionTier ?? 'basic';

    final selectedPlan = _plans.firstWhere((p) => p['id'] == _selectedTierId);

    return Scaffold(
      backgroundColor: kBackgroundCream,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: kPrimaryBurgundy),
        title: const Text(
          'Unlock Premium Access',
          style: TextStyle(color: kPrimaryBurgundy, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 1. Horizontal Cards (Unchanged logic, just copy-paste not needed here as I'm replacing below)
            SizedBox(
              height: 160,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _plans.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final plan = _plans[index];
                  final isSelected = _selectedTierId == plan['id'];
                  final isPopular = plan['popular'] == true;

                  return GestureDetector(
                    onTap: () => setState(() => _selectedTierId = plan['id']),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: 120, // Slightly wider for new titles
                      decoration: BoxDecoration(
                        color: isSelected ? kPrimaryBurgundy : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected ? kPrimaryBurgundy : Colors.grey.shade300,
                          width: 2,
                        ),
                        boxShadow: isSelected 
                            ? [BoxShadow(color: kPrimaryBurgundy.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 6))]
                            : [],
                      ),
                      child: Stack(
                        children: [
                          if (isPopular)
                            Positioned(
                              top: 0,
                              left: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                decoration: const BoxDecoration(
                                  color: Color(0xFF5A1522), 
                                  borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
                                ),
                                child: const Text(
                                  'Most Popular',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  plan['title'],
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: isSelected ? Colors.white : Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  plan['subtitle'], 
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: isSelected ? Colors.white70 : Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          if (isSelected)
                            const Positioned(
                              bottom: 8,
                              left: 0,
                              right: 0,
                              child: Icon(Icons.check_circle, color: Colors.white, size: 20),
                            ),
                        ],
                      ),
                    ).animate().scale(delay: (index * 50).ms),
                  );
                },
              ),
            ),

            const SizedBox(height: 32),

            // 2. Billing Selection (Side by Side)
            if (_selectedTierId != 'basic') ...[
               Row(
                children: [
                  Expanded(
                    child: _buildBillingOption(
                      'Monthly',
                      '₹${selectedPlan['monthly_price']}',
                      'per month',
                      'monthly',
                      isSelected: _selectedBilling == 'monthly',
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildBillingOption(
                      'Yearly',
                      '₹${selectedPlan['yearly_price']}',
                      '2 months free',
                      'yearly',
                      isSelected: _selectedBilling == 'yearly',
                      isBestValue: true,
                    ),
                  ),
                ],
              ).animate().fadeIn().slideY(begin: 0.1),
            ],

            const SizedBox(height: 32),

            // 3. Plan Details List
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0,4))
                ]
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Row(
                    children: [
                      Icon(
                        _selectedTierId == 'lender_pro' ? Icons.storefront : 
                        _selectedTierId == 'renter_plus' ? Icons.shopping_bag : Icons.workspace_premium,
                        color: kPrimaryBurgundy,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '${selectedPlan['title']} Benefits',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kPrimaryBurgundy),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  ...(selectedPlan['features'] as List<String>).map((feature) => Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.check_circle, color: kPrimaryBurgundy, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            feature, 
                            style: const TextStyle(
                              fontSize: 15, 
                              fontWeight: FontWeight.w600, 
                              height: 1.3,
                              color: Colors.black, // Enforce dark black color
                            )
                          ),
                        ),
                      ],
                    ),
                  )).toList(),
                  
                  const Divider(height: 40),
                  
                  // Pitch Section
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: kPrimaryBurgundy.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: kPrimaryBurgundy.withValues(alpha: 0.1))
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'WHY YOU\'LL LOVE IT',
                          style: TextStyle(
                            fontSize: 11, 
                            fontWeight: FontWeight.bold, 
                            color: kPrimaryBurgundy.withValues(alpha: 0.7),
                            letterSpacing: 1.2
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          selectedPlan['pitch'] ?? '',
                          style: const TextStyle(
                            fontSize: 14, 
                            fontStyle: FontStyle.italic, 
                            color: Colors.black87
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 200.ms),

            const SizedBox(height: 32),

            // 4. Action Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: (_isLoading || (_selectedTierId == currentTier && _selectedTierId != 'basic'))
                    ? null 
                    : _subscribe,
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimaryBurgundy,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 4,
                  disabledForegroundColor: Colors.white, // Visible text when disabled
                  disabledBackgroundColor: Colors.grey,  // Visible background when disabled
                ),
                child: _isLoading 
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        _selectedTierId == 'basic' 
                            ? 'Stay on Basic' 
                            : 'Subscribe ₹${_selectedBilling == 'monthly' ? selectedPlan['monthly_price'] : selectedPlan['yearly_price']}',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
              ),
            ).animate().scale(delay: 300.ms),
            
            const SizedBox(height: 16),
            const Text(
              'Cancel anytime. Terms apply.',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBillingOption(String title, String price, String sub, String billingId, {required bool isSelected, bool isBestValue = false}) {
    return GestureDetector(
      onTap: () => setState(() => _selectedBilling = billingId),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? kPrimaryBurgundy.withValues(alpha: 0.1) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? kPrimaryBurgundy : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: isSelected ? kPrimaryBurgundy : Colors.grey)),
                if (isBestValue)
                 Container(
                   margin: const EdgeInsets.only(left: 6),
                   padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                   decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(4)),
                   child: const Text('SAVE', style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
                 )
              ],
            ),
            const SizedBox(height: 8),
            Text(price, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.black)),
            const SizedBox(height: 4),
            Text(sub, style: TextStyle(fontSize: 12, color: isBestValue ? Colors.green : Colors.grey)),
            const SizedBox(height: 12),
            Container(
              height: 20,
              width: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: isSelected ? kPrimaryBurgundy : Colors.grey),
                color: isSelected ? kPrimaryBurgundy : Colors.transparent,
              ),
              child: isSelected ? const Icon(Icons.check, size: 14, color: Colors.white) : null,
            )
          ],
        ),
      ),
    );
  }
}
