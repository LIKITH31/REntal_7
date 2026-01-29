import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/models/product_model.dart';
import '../../../../core/providers/items_provider.dart';

class AdminRentalRequestsScreen extends ConsumerWidget {
  const AdminRentalRequestsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Using pending products stream instead of processingProductsProvider
    final processingProductsAsyncValue = ref
        .watch(firestoreServiceProvider)
        .getPendingProductsStream();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rental Requests'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<List<ProductModel>>(
        stream: processingProductsAsyncValue,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error loading rental requests: ${snapshot.error}'),
            );
          }

          final products = snapshot.data ?? [];

          if (products.isEmpty) {
            return const Center(
              child: Text('No rental requests at the moment.'),
            );
          }

          return ListView.builder(
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              return _RentalRequestCard(product: product);
            },
          );
        },
      ),
    );
  }
}

class _RentalRequestCard extends ConsumerWidget {
  final ProductModel product;
  const _RentalRequestCard({required this.product});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // TODO: This screen needs to be updated to work with the new orders system
    // instead of booking fields on products. For now, showing basic product info.

    return Card(
      margin: const EdgeInsets.all(8),
      child: ListTile(
        title: Text(product.title),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Owner: ${product.ownerName}'),
            Text('Price: \₹${product.rentalPricePerDay} / day'),
            Text('Status: ${product.status}'),
            const Text(
              'TODO: Update to use orders system',
              style: TextStyle(color: Colors.red, fontStyle: FontStyle.italic),
            ),
          ],
        ),
        trailing: ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
          onPressed: null, // Disabled until updated
          child: const Text('Update Needed'),
        ),
      ),
    );
  }

  // TODO: Implement rental request approval using the new orders system
}
