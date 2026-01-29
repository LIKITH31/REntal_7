import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/models/order_models.dart';

class OrderDebugScreen extends ConsumerWidget {
  const OrderDebugScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Debug - Real Time'),
        backgroundColor: Colors.red.shade100,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('orders')
            .orderBy('createdAt', descending: true)
            .limit(10)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final orders = snapshot.data?.docs ?? [];

          if (orders.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No orders found'),
                  Text('Try booking an item to see orders appear here'),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final doc = orders[index];
              final order = OrderModel.fromMap(
                doc.data() as Map<String, dynamic>,
              );

              return Card(
                margin: const EdgeInsets.all(8),
                child: ExpansionTile(
                  title: Text('Order ${order.id.substring(0, 8)}...'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Status: ${order.orderStatus}'),
                      Text('Payment: ${order.paymentStatus}'),
                      Text('Total: ₹${order.totalAmount}'),
                      Text('Created: ${order.createdAt}'),
                    ],
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Full Order ID: ${order.id}'),
                          Text('Order Number: ${order.orderNumber}'),
                          Text('Order Type: ${order.orderType}'),
                          Text('User ID: ${order.userId}'),
                          Text('Deposit: ₹${order.depositAmount}'),
                          Text('Final Amount: ₹${order.finalAmount}'),
                          const SizedBox(height: 16),

                          // Check subcollections
                          FutureBuilder<Map<String, int>>(
                            future: _getSubcollectionCounts(doc.reference),
                            builder: (context, subSnapshot) {
                              if (subSnapshot.hasData) {
                                final counts = subSnapshot.data!;
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Subcollections:',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text('Items: ${counts['items'] ?? 0}'),
                                    Text('Rentals: ${counts['rentals'] ?? 0}'),
                                    Text(
                                      'Transactions: ${counts['transactions'] ?? 0}',
                                    ),
                                  ],
                                );
                              }
                              return const Text('Loading subcollections...');
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<Map<String, int>> _getSubcollectionCounts(
    DocumentReference orderRef,
  ) async {
    final results = await Future.wait([
      orderRef.collection('items').get(),
      orderRef.collection('rentals').get(),
      orderRef.collection('transactions').get(),
    ]);

    return {
      'items': results[0].docs.length,
      'rentals': results[1].docs.length,
      'transactions': results[2].docs.length,
    };
  }
}
