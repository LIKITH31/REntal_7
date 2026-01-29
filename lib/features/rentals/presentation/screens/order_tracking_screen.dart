import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/providers/items_provider.dart';
import '../../../../core/models/order_models.dart';
import '../../../../core/models/product_model.dart';

class OrderTrackingScreen extends ConsumerWidget {
  final OrderModel order;
  const OrderTrackingScreen({super.key, required this.order});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Order #${order.orderNumber.isNotEmpty ? order.orderNumber : order.id.substring(0, 8)}',
        ),
      ),
      body: FutureBuilder(
        // Fetch items, rental info, and delivery info in parallel
        future: Future.wait([
          ref.read(firestoreServiceProvider).getOrderItems(order.id),
          // Fetch rental info: orders/{orderId}/rentals/details
          FirebaseFirestore.instance
              .collection('orders')
              .doc(order.id)
              .collection('rentals')
              .doc('details')
              .get(),
          // Fetch delivery info: delivery/{orderId} (ROOT)
          FirebaseFirestore.instance.collection('delivery').doc(order.id).get(),
        ]),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final results = snapshot.data as List<dynamic>;
          final items = results[0] as List<OrderItemModel>;
          final deliveryDoc = results[2] as DocumentSnapshot;

          final firstItem = items.isNotEmpty ? items.first : null;
          final title = firstItem?.productName ?? 'Order Items';
          final totalAmount = order.totalAmount;

          final deliveryStatus =
              (deliveryDoc.exists && deliveryDoc.data() != null)
              ? (deliveryDoc.data()
                        as Map<String, dynamic>)['deliveryStatus'] ??
                    'pending'
              : 'pending';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.shopping_bag),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text('Total: \₹${totalAmount.toStringAsFixed(0)}'),
                          Text('${items.length} Items'),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                const Text(
                  'Order Status',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 24),

                _buildTimeline(order.orderStatus, deliveryStatus),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTimeline(String orderStatus, String deliveryStatus) {
    // Mapping complex architecture statuses to UI
    // Order: pending -> confirmed -> active -> completed
    // Delivery: assigned -> picked -> delivered

    // Simplistic timeline for now
    final steps = [
      {'title': 'Order Placed', 'isActive': true},
      {
        'title': 'Confirmed',
        'isActive': [
          'confirmed',
          'active',
          'completed',
          'returned',
        ].contains(orderStatus.toLowerCase()),
      },
      {
        'title': 'Out for Delivery',
        'isActive': [
          'picked',
          'delivered',
        ].contains(deliveryStatus.toLowerCase()),
      },
      {
        'title': 'Active / delivered',
        'isActive': [
          'active',
          'delivered',
          'completed',
          'returned',
        ].contains(orderStatus.toLowerCase()),
      },
      {
        'title': 'Completed / Returned',
        'isActive': [
          'completed',
          'returned',
        ].contains(orderStatus.toLowerCase()),
      },
    ];

    if (orderStatus == 'cancelled') {
      return const Center(
        child: Text(
          'This order has been Cancelled',
          style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: steps.length,
      itemBuilder: (context, index) {
        final step = steps[index];
        final isActive = step['isActive'] as bool;
        final isLast = index == steps.length - 1;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isActive ? Colors.green : Colors.grey[300],
                  ),
                  child: isActive
                      ? const Icon(Icons.check, size: 16, color: Colors.white)
                      : null,
                ),
                if (!isLast)
                  Container(
                    width: 2,
                    height: 40,
                    color: isActive && (steps[index + 1]['isActive'] as bool)
                        ? Colors.green
                        : Colors.grey[300],
                  ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    step['title'] as String,
                    style: TextStyle(
                      fontWeight: isActive
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: isActive ? Colors.black : Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 48),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
