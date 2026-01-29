import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../../../core/providers/items_provider.dart'; // For firestoreServiceProvider
import '../providers/order_provider.dart';
import '../../../../core/models/order_models.dart'; // Use new comprehensive order models
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/models/review_model.dart';
import '../../../reviews/presentation/widgets/review_dialog.dart';
import 'order_tracking_screen.dart';

class RentalsScreen extends ConsumerStatefulWidget {
  const RentalsScreen({super.key});

  @override
  ConsumerState<RentalsScreen> createState() => _RentalsScreenState();
}

class _RentalsScreenState extends ConsumerState<RentalsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ordersAsync = ref.watch(userOrdersProvider);

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar.large(
              floating: true,
              pinned: true,
              title: const Text('My Rentals'),
              bottom: TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(text: 'Active'),
                  Tab(text: 'Pending'),
                  Tab(text: 'Completed'),
                ],
              ),
            ),
          ];
        },
        body: ordersAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(child: Text('Error: $err')),
          data: (orders) {
            return TabBarView(
              controller: _tabController,
              children: [
                _buildRentalsList(orders, 'Active'),
                _buildRentalsList(orders, 'Pending'),
                _buildRentalsList(orders, 'Completed'),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildRentalsList(List<OrderModel> allOrders, String tabCategory) {
    // Filter logic
    final rentals = allOrders.where((order) {
      final s = order.orderStatus.toLowerCase(); // Updated to use orderStatus

      // Map tabs to statuses
      if (tabCategory == 'Pending') return s == 'pending';
      if (tabCategory == 'Active')
        return ['confirmed', 'active', 'picked up', 'in use'].contains(s);
      if (tabCategory == 'Completed')
        return ['completed', 'returned', 'cancelled'].contains(s);
      return false;
    }).toList();

    if (rentals.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 80, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'No $tabCategory rentals',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(color: Colors.grey),
            ),
          ],
        ).animate().fadeIn().scale(),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: rentals.length,
      itemBuilder: (context, index) {
        final rental = rentals[index];
        return _buildRentalCard(rental, index);
      },
    );
  }

  Widget _buildRentalCard(OrderModel order, int index) {
    // Helper to get color
    Color color;
    IconData icon;
    // Normalized status check
    final status = order.orderStatus.toLowerCase();

    switch (status) {
      case 'pending':
        color = Colors.orange;
        icon = Icons.pending;
        break;
      case 'confirmed':
        color = Colors.blue;
        icon = Icons.check_circle;
        break;
      case 'active':
      case 'picked up':
      case 'in use':
        color = Colors.green;
        icon = Icons.play_circle;
        break;
      case 'completed':
      case 'returned':
        color = Colors.grey;
        icon = Icons.task_alt;
        break;
      case 'cancelled':
        color = Colors.red;
        icon = Icons.cancel;
        break;
      default:
        color = Colors.grey;
        icon = Icons.info;
    }

    // Use Summary Fields from OrderModel (Snapshot Data)
    // STRICT ARCHITECTURE: Never re-read from products collection.
    // TODO: Get item details from order items subcollection
    final itemName = 'Order ${order.orderNumber}';
    if (itemName.isNotEmpty) {
      return _buildCardUI(
        context,
        order,
        itemName,
        null, // TODO: Get from subcollection
        color,
        icon,
        index,
      );
    }

    // If snapshot data is missing (legacy data), show placeholder.
    // Do NOT fetch product to prevent price/consistency errors.
    return _buildCardUI(
      context,
      order,
      'Item #${order.orderNumber.isNotEmpty ? order.orderNumber : order.id.substring(0, 4)}',
      null,
      color,
      icon,
      index,
    );
  }

  Widget _buildCardUI(
    BuildContext context,
    OrderModel order,
    String itemTitle,
    String? itemImage,
    Color color,
    IconData icon,
    int index,
  ) {
    // Display dates from Summary or N/A
    // TODO: Get rental dates from order items subcollection
    final start = order.createdAt; // Placeholder - use order creation date
    final end = order.createdAt.add(
      Duration(days: 7),
    ); // Placeholder - 7 days from creation
    final dateStr =
        '${DateFormat("dd MMM").format(start)} - ${DateFormat("dd MMM").format(end)}';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => OrderTrackingScreen(order: order),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  // Item Image or Category Icon
                  if (itemImage != null && itemImage.isNotEmpty)
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        image: DecorationImage(
                          image: NetworkImage(itemImage),
                          fit: BoxFit.cover,
                        ),
                      ),
                    )
                  else
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(icon, color: color, size: 30),
                    ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          itemTitle,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            // color: Colors.white, // Removed white color to be visible on light card
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          dateStr,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildStatusChip(order.orderStatus, color),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right),
                ],
              ),
              // Allow reviews for completed or returned orders
              if ([
                'completed',
                'returned',
              ].contains(order.orderStatus.toLowerCase())) ...[
                const Divider(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _showReviewDialog(context, order, itemTitle),
                    icon: const Icon(Icons.rate_review_outlined),
                    label: const Text('Write a Review'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.amber[800],
                      side: BorderSide(color: Colors.amber.shade800),
                    ),
                  ),
                ),
              ],

              // Cancel Action
              if (order.orderStatus.toLowerCase() == 'pending') ...[
                const Divider(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _confirmCancel(context, order),
                    icon: const Icon(Icons.cancel_outlined),
                    label: const Text('Cancel Order'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    ).animate().fadeIn(delay: (100 * index).ms).slideX(begin: -0.2);
  }

  Future<void> _confirmCancel(BuildContext context, OrderModel order) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Booking?'),
        content: const Text(
          'Are you sure you want to cancel this booking request? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Yes, Cancel',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await FirebaseFirestore.instance
            .collection('orders') // Changed from rentals
            .doc(order.id)
            .update({'status': 'cancelled'});

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Order cancelled successfully.')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Failed to cancel: $e')));
        }
      }
    }
  }

  void _showReviewDialog(
    BuildContext context,
    OrderModel order,
    String itemName,
  ) {
    showDialog(
      context: context,
      builder: (context) => ReviewDialog(
        targetName: itemName,
        onSubmit: (rating, comment) async {
          final user = FirebaseAuth.instance.currentUser;
          if (user == null) return;

          try {
             // 1. Get Order Items to find Product ID
            final orderItems = await ref.read(firestoreServiceProvider).getOrderItems(order.id);
            if (orderItems.isEmpty) {
              throw 'Order items not found';
            }
            final productId = orderItems.first.productId; // Assuming single product per rental for now

            // 2. Create Review Model
            final review = ReviewModel(
              id: Uuid().v4(), // Generate new ID
              reviewerId: user.uid,
              reviewerName: user.displayName ?? 'Renter',
              reviewerImage: user.photoURL,
              rating: rating,
              comment: comment,
              orderId: order.id,
              orderType: 'rental',
              reviewType: 'product',
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            );

            // 3. Submit Review via Service
            await ref.read(firestoreServiceProvider).addProductReview(productId, review);

            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Review submitted successfully!')),
              );
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Failed to submit review: $e')),
              );
            }
          }
        },
      ),
    );
  }

  Widget _buildStatusChip(String status, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
