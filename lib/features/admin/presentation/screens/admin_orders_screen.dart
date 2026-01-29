import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/providers/items_provider.dart';
import '../../../../core/models/order_model.dart';

class AdminOrdersScreen extends ConsumerWidget {
  const AdminOrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Orders')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('orders')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) return const Center(child: Text('No orders found'));

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final order = OrderModel.fromFirestore(doc);

              return _AdminOrderCard(order: order);
            },
          );
        },
      ),
    );
  }
}

class _AdminOrderCard extends ConsumerWidget {
  final OrderModel order;
  const _AdminOrderCard({required this.order});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ExpansionTile(
        title: Text(
          'Order #${order.orderNumber.isNotEmpty ? order.orderNumber : order.id.substring(0, 8)}',
        ),
        subtitle: Text(
          'Status: ${order.status.toUpperCase()} | \₹${order.totalAmount}',
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Order Status:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Wrap(
                  spacing: 8,
                  children: [
                    if (order.status == 'pending')
                      ElevatedButton(
                        onPressed: () => _updateStatus(ref, 'confirmed'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                        ),
                        child: const Text('Confirm Order'),
                      ),
                    if (order.status == 'confirmed')
                      ElevatedButton(
                        onPressed: () => _updateStatus(ref, 'active'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                        ),
                        child: const Text('Simulate Pickup (Activate)'),
                      ),
                    if (order.status == 'active')
                      ElevatedButton(
                        onPressed: () => _updateStatus(ref, 'completed'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                        ),
                        child: const Text('Simulate Return (Complete)'),
                      ),
                  ],
                ),
                const Divider(),
                const Text(
                  'Quick Actions (Subcollections):',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Row(
                  children: [
                    TextButton.icon(
                      icon: const Icon(Icons.local_shipping),
                      label: const Text('Mark Delivered'),
                      onPressed: () => _updateDeliveryStatus(context),
                    ),
                    TextButton.icon(
                      icon: const Icon(Icons.assignment_return),
                      label: const Text('Mark Returned'),
                      onPressed: () => _updateReturnStatus(context),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _updateStatus(WidgetRef ref, String newStatus) async {
    // 1. Update Order Status
    await FirebaseFirestore.instance.collection('orders').doc(order.id).update({
      'status': newStatus,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // 2. If Consuming (Confirming), Mark Products as Unavailable
    // This runs as Admin, so it bypasses the 'users cannot update products' rule!
    if (newStatus == 'confirmed') {
      try {
        final itemsSnap = await FirebaseFirestore.instance
            .collection('orders')
            .doc(order.id)
            .collection('items')
            .get();

        for (var doc in itemsSnap.docs) {
          final productId = doc['productId'];
          // Mark strict as 'unavailable' to hide from listings
          await FirebaseFirestore.instance
              .collection('products')
              .doc(productId)
              .update({'status': 'unavailable'});
        }
      } catch (e) {
        print('Error locking products: $e');
      }
    }

    // 3. If Completed/Returned, Mark Products as Available again?
    if (newStatus == 'completed') {
      try {
        final itemsSnap = await FirebaseFirestore.instance
            .collection('orders')
            .doc(order.id)
            .collection('items')
            .get();

        for (var doc in itemsSnap.docs) {
          final productId = doc['productId'];
          await FirebaseFirestore.instance
              .collection('products')
              .doc(productId)
              .update({'status': 'approved'});
        }
      } catch (e) {
        print('Error unlocking products: $e');
      }
    }
  }

  Future<void> _updateDeliveryStatus(BuildContext context) async {
    await FirebaseFirestore.instance
        .collection('delivery') // ROOT Collection
        .doc(order.id)
        .set({'deliveryStatus': 'delivered'}, SetOptions(merge: true));

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Delivery marked as Delivered')),
    );
  }

  Future<void> _updateReturnStatus(BuildContext context) async {
    await FirebaseFirestore.instance
        .collection('orders')
        .doc(order.id)
        .collection('rentals') // Plural match
        .doc('details')
        .set({
          'returnStatus': 'returned',
          'returnedAt': Timestamp.now(),
        }, SetOptions(merge: true));

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Marked as Returned')));
  }
}
