import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/models/product_model.dart';
import '../../../../core/models/order_model.dart';
import '../../../booking/presentation/booking_screen.dart';
import '../../../booking/presentation/payment_screen.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/models/review_model.dart';
import '../../../../core/models/review_model.dart';
import '../../../../core/services/firestore_service.dart';
import '../../../../core/providers/items_provider.dart'; // Correct import for firestoreServiceProvider


class ItemDetailsScreen extends ConsumerWidget {
  final ProductModel item;

  const ItemDetailsScreen({super.key, required this.item});

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Item'),
        content: const Text(
          'Are you sure you want to delete this item? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      try {
        final firestoreService = ref.read(firestoreServiceProvider);
        await firestoreService.deleteProduct(item.id);
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Item deleted successfully')),
          );
          Navigator.of(context).pop(); // Go back to Home
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete item: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  void _handleAction(BuildContext context, WidgetRef ref, ProductModel item) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to continue')),
      );
      return;
    }

    // Always Rent Flow
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BookingScreen(item: item),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final firestoreService = ref.watch(firestoreServiceProvider);

    return StreamBuilder<ProductModel?>(
      stream: firestoreService.getProductStream(item.id),
      initialData: item,
      builder: (context, snapshot) {
        // Use stream data or fallback to initial item (optimistic)
        final item = snapshot.data ?? this.item;
        
        if (snapshot.hasData && snapshot.data == null) {
           return const Scaffold(body: Center(child: Text("Item no longer exists")));
        }

        final currency = '₹';
        final isSellMode = item.transactionMode == 'sell';
    
    // Dynamic Price Logic
    String displayedPrice;
    if (isSellMode) {
      displayedPrice = item.salePrice != null 
          ? '$currency${item.salePrice}' 
          : 'Not for Sale';
    } else {
      displayedPrice = '$currency${item.rentalPricePerDay} / day';
    }

    final currentUser = FirebaseAuth.instance.currentUser;
    final isOwner = currentUser?.uid == item.ownerId;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            expandedHeight: 300,
            pinned: true,
            actions: [
               if (isOwner)
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _confirmDelete(context, ref),
                  tooltip: 'Delete Item',
                ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              title: Text(item.title),
              background: Container(
                color: Colors.grey.shade900,
                child: item.images.isNotEmpty 
                  ? Image.network(
                      item.images.first, 
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.image, size: 100, color: Colors.white54)),
                    )
                  : const Center(
                      child: Icon(Icons.image, size: 100, color: Colors.white54),
                    ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ARCHIVED BADGE
                  if (!item.isActive)
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade800,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.archive, color: Colors.white),
                          SizedBox(width: 8),
                          Text(
                            'ARCHIVED - Private',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
// Mode Badge removed as per user request (UI Cleanup)

                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          item.categoryName,
                          style: TextStyle(
                            color: Theme.of(context).primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        displayedPrice,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ).animate().fadeIn().slideX(),
                  const SizedBox(height: 24),
                  Text(
                    'Description',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    item.description,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 24),
                  
                  // Conditional Details based on Mode
                  if (!isSellMode) ...[
                      _buildDetailRow(context, 'Security Deposit', '$currency${item.securityDeposit ?? 0}'),
                      const SizedBox(height: 12),
                      _buildDetailRow(context, 'Weekly Rate', item.rentalPricePerWeek != null ? '$currency${item.rentalPricePerWeek}' : '-'),
                      const SizedBox(height: 12),
                      _buildDetailRow(context, 'Monthly Rate', item.rentalPricePerMonth != null ? '$currency${item.rentalPricePerMonth}' : '-'),
                  ] else ...[
                      // Sale specific details if any
                      _buildDetailRow(context, 'Condition', 'Used'), // Placeholder/Inferred
                  ],

                  const SizedBox(height: 12),
                  if (item.originalPrice != null) ...[
                    _buildDetailRow(context, 'Original Price (MRP)', '$currency${item.originalPrice}'),
                    const SizedBox(height: 12),
                  ],
                  if (item.dimensions != null) ...[
                    _buildDetailRow(context, 'Dimensions / Specs', item.dimensions!),
                    const SizedBox(height: 12),
                  ],
                  const SizedBox(height: 24),
                  
                  const SizedBox(height: 24),
                  
                  const Divider(),
                  const SizedBox(height: 16),
                  
                  // Owner Profile
                  Row(
                    children: [
                      const CircleAvatar(child: Icon(Icons.store)),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Listed by ${item.ownerName}',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          Row(
                            children: [
                              Text(
                                'Verified Seller',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
                              ),
                              const SizedBox(width: 8),
                              const Icon(Icons.star, size: 14, color: Colors.amber),
                              Text(
                                ' ${item.averageRating > 0 ? item.averageRating.toStringAsFixed(1) : "New"} (${item.reviewCount})',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Reviews Section
                  _buildReviewsList(context),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton(
            onPressed: () {
              if (isOwner) {
                _showOwnerManageDialog(context, item);
              } else {
                 if (isSellMode) {
                   // Implement Buy Flow or show Info
                   ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Buying feature coming soon!')));
                 } else {
                   _handleAction(context, ref, item);
                 }
              }
            },
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: isOwner 
                  ? Colors.blueGrey.shade800 
                  : (isSellMode ? Colors.orange : const Color(0xFF781C2E)),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(
              isOwner 
                  ? 'MANAGE ITEM (Switch Mode)' 
                  : (isSellMode ? 'BUY NOW' : 'RENT NOW'),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
        ),
      ),
    );
      },
    );
  }

  void _showOwnerManageDialog(BuildContext context, ProductModel item) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        bool isSellMode = item.transactionMode == 'sell';
        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              padding: const EdgeInsets.all(24),
              child: SingleChildScrollView(
                child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Manage Item Transaction Mode',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Switch between Renting and Selling. Changing this will instantly update the item availability for all users.',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 24),
                  
                  SwitchListTile(
                    title: Text(isSellMode ? 'Selling Mode' : 'Renting Mode'),
                    subtitle: Text(isSellMode 
                        ? 'Item is available for purchase only.' 
                        : 'Item is available for rental booking.'),
                    value: isSellMode,
                    activeColor: Colors.orange,
                    secondary: Icon(isSellMode ? Icons.sell : Icons.timer),
                    onChanged: (value) async {
                      final newMode = value ? 'sell' : 'rent';
                      
                      // VALIDATION & INPUT: Check if required price exists
                      if (value && (item.salePrice == null || item.salePrice == 0)) {
                        // Switching to SELL but no Sale Price -> Ask for it
                        Navigator.pop(context); // Close manage sheet
                        _showSetPriceDialog(context, 'Sale Price', (price) async {
                           await _updateItemMode(context, item.id, 'sell', price: price, isSale: true);
                        });
                        return;
                      } 
                      
                      if (!value && (item.rentalPricePerDay == 0)) {
                         // Switching to RENT but no Rent Price -> Ask for it
                         Navigator.pop(context);
                         _showSetPriceDialog(context, 'Daily Rental Price', (price) async {
                           await _updateItemMode(context, item.id, 'rent', price: price, isSale: false);
                         });
                         return;
                      }

                      // If prices exist, just update
                      try {
                         Navigator.pop(context);
                         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Updating item mode...')));
                         await FirestoreService(FirebaseFirestore.instance, FirebaseAuth.instance)
                             .updateProduct(item.id, {'transactionMode': newMode});
                      } catch (e) {
                         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to update: $e')));
                      }
                    },
                  ),
                  const Divider(height: 32),
                  
                  // ARCHIVE TOGGLE
                  SwitchListTile(
                    title: const Text('Archived (Hidden)'),
                    subtitle: const Text('Hide this item from search results and feeds.'),
                    value: !(item.isActive), // Assuming isActive=true usually. 
                    // Actually, let's assume default is active. 
                    // If isActive is NOT present, default true.
                    // UI shows "Archived" -> so value is !isActive
                    activeColor: Colors.grey,
                    secondary: const Icon(Icons.archive),
                    onChanged: (isArchived) async {
                       Navigator.pop(context);
                       final service = FirestoreService(FirebaseFirestore.instance, FirebaseAuth.instance);
                       try {
                         if (isArchived) {
                           await service.archiveProduct(item.id);
                           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Item archived')));
                         } else {
                           await service.unarchiveProduct(item.id);
                           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Item unarchived')));
                         }
                       } catch(e) {
                         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                       }
                    },
                  ),

                  const SizedBox(height: 12),

                  // DELETE BUTTON
                  SizedBox(
                    width: double.infinity,
                    child: TextButton.icon(
                      onPressed: () {
                        // Confirm Delete
                        showDialog(context: context, builder: (ctx) => AlertDialog(
                          title: const Text('Delete Item?'),
                          content: const Text('This action cannot be undone. Any active bookings will remain in history, but the item will be permanently removed.'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCEL')),
                            TextButton(
                              style: TextButton.styleFrom(foregroundColor: Colors.red),
                              onPressed: () async {
                                Navigator.pop(ctx); // Close alert
                                Navigator.pop(context); // Close sheet
                                try {
                                  await FirestoreService(FirebaseFirestore.instance, FirebaseAuth.instance)
                                      .deleteProduct(item.id);
                                  if (context.mounted) {
                                    Navigator.pop(context); // Go back to Home
                                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Item deleted successfully')));
                                  }
                                } catch(e) {
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Delete failed: $e')));
                                }
                              }, 
                              child: const Text('DELETE PERMANENTLY')
                            ),
                          ],
                        ));
                      },
                      icon: const Icon(Icons.delete_forever, color: Colors.red),
                      label: const Text('Delete Item', style: TextStyle(color: Colors.red)),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.all(16),
                        backgroundColor: Colors.red.withOpacity(0.1),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
              ),
            );
          }
        );
      },
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildReviewsList(BuildContext context) {
    return StreamBuilder<List<ReviewModel>>(
      stream: FirebaseFirestore.instance
          .collection('products')
          .doc(item.id)
          .collection('reviews')
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snap) => snap.docs.map((doc) => ReviewModel.fromFirestore(doc)).toList()),
      builder: (context, snapshot) {
        if (snapshot.hasError) return Text('Error loading reviews: ${snapshot.error}');
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        
        final reviews = snapshot.data ?? [];
        if (reviews.isEmpty) return const Text('No reviews yet. Be the first to rent and review!', style: TextStyle(color: Colors.grey));

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: reviews.length > 3 ? 3 : reviews.length, // Show max 3
          separatorBuilder: (_, __) => const SizedBox(height: 16),
          itemBuilder: (context, index) {
            final review = reviews[index];
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.grey.shade200,
                  backgroundImage: review.reviewerImage != null ? NetworkImage(review.reviewerImage!) : null,
                  child: review.reviewerImage == null ? Text(review.reviewerName[0].toUpperCase()) : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(review.reviewerName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          const Spacer(),
                          Text(DateFormat.yMMMd().format(review.createdAt), style: const TextStyle(fontSize: 10, color: Colors.grey)),
                        ],
                      ),
                      Row(
                        children: List.generate(5, (starIndex) {
                          return Icon(
                            starIndex < review.rating ? Icons.star : Icons.star_border,
                            size: 12,
                            color: Colors.amber,
                          );
                        }),
                      ),
                      const SizedBox(height: 4),
                      if (review.comment.isNotEmpty)
                        Text(review.comment, style: const TextStyle(fontSize: 13)),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _updateItemMode(BuildContext context, String itemId, String mode, {double? price, required bool isSale}) async {
    final updates = <String, dynamic>{
      'transactionMode': mode,
    };
    
    if (price != null) {
      if (isSale) {
        updates['salePrice'] = price;
      } else {
        updates['rentalPricePerDay'] = price;
        // Optionally auto-calculate weekly/monthly
        updates['rentalPricePerWeek'] = price * 6;
        updates['rentalPricePerMonth'] = price * 25;
      }
    }

    try {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Updating item...')));
      await FirestoreService(FirebaseFirestore.instance, FirebaseAuth.instance)
          .updateProduct(itemId, updates);
      if (context.mounted) ScaffoldMessenger.of(context).hideCurrentSnackBar();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
      }
    }
  }

  void _showSetPriceDialog(BuildContext context, String label, Function(double) onConfirm) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Set $label'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: label,
            prefixText: '₹ ',
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final val = double.tryParse(controller.text);
              if (val != null && val > 0) {
                Navigator.pop(ctx);
                onConfirm(val);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

