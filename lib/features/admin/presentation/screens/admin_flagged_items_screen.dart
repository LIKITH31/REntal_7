import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/items_provider.dart';
import '../../../../core/models/product_model.dart';
import '../../../home/presentation/screens/item_details_screen.dart';

class AdminFlaggedItemsScreen extends ConsumerWidget {
  const AdminFlaggedItemsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final flaggedStream = ref.watch(firestoreServiceProvider).getFlaggedProducts();

    return Scaffold(
      appBar: AppBar(title: const Text('Flagged Products')),
      body: StreamBuilder<List<ProductModel>>(
        stream: flaggedStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
             return Center(child: Text('Error: ${snapshot.error}'));
          }

          final products = snapshot.data ?? [];
          if (products.isEmpty) {
            return const Center(child: Text('No flagged products.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              return Card(
                color: Colors.red.shade50,
                child: ListTile(
                  leading: product.images.isNotEmpty 
                      ? Image.network(product.images.first, width: 50, height: 50, fit: BoxFit.cover)
                      : const Icon(Icons.image_not_supported),
                  title: Text(product.title),
                  subtitle: Text('Owner: ${product.ownerName}'),
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => ItemDetailsScreen(item: product)));
                  },
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                       IconButton(
                         icon: const Icon(Icons.check, color: Colors.green),
                         tooltip: 'Keep (Unflag)',
                         onPressed: () async {
                            await ref.read(firestoreServiceProvider).unflagProduct(product.id);
                            if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Product unflagged')));
                         },
                       ),
                       IconButton(
                         icon: const Icon(Icons.delete_forever, color: Colors.red),
                         tooltip: 'Delete',
                         onPressed: () async {
                              final confirm = await showDialog(context: context, builder: (_) => AlertDialog(
                                title: const Text('Delete Product?'),
                                content: const Text('This cannot be undone.'),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                                  TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
                                ],
                              ));
                              if (confirm == true) {
                                await ref.read(firestoreServiceProvider).deleteProductAdmin(product.id);
                              }
                         },
                       ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
