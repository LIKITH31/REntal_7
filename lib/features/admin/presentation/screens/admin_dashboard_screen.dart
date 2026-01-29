import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../core/providers/items_provider.dart'; // Using firestoreServiceProvider from here for now or need separate provider?
// Using firestoreServiceProvider from items_provider is fine.

import 'admin_kyc_screen.dart';
import 'admin_categories_screen.dart';
import 'admin_flagged_items_screen.dart';
import 'admin_products_screen.dart';
import 'admin_orders_screen.dart';
import 'admin_rental_requests_screen.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userModelProvider);

    return userAsync.when(
      data: (user) {
        if (user == null || user.role != 'admin') {
          return const Scaffold(body: Center(child: Text('Access Denied: Admins Only')));
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Admin Dashboard'),
            backgroundColor: Colors.blueGrey.shade900,
            foregroundColor: Colors.white,
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildAdminTile(
                context,
                'KYC Verification',
                Icons.verified_user,
                Colors.orange,
                () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminKycScreen())),
              ),
              _buildAdminTile(
                context,
                'Manage Categories',
                Icons.category,
                Colors.blue,
                () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminCategoriesScreen())),
              ),
              _buildAdminTile(
                context,
                'Flagged Products',
                Icons.flag,
                Colors.red,
                () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminFlaggedItemsScreen())),
              ),
              _buildAdminTile(
                context,
                'Approve Products',
                Icons.check_circle_outline,
                Colors.green,
                () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminProductsScreen())),
              ),
              _buildAdminTile( // NEW: Rental Requests Tile
                context,
                'Rental Requests',
                Icons.hourglass_top,
                Colors.orange,
                () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminRentalRequestsScreen())),
              ),
              _buildAdminTile(
                context,
                'Manage Orders',
                Icons.shopping_bag_outlined,
                Colors.blueAccent,
                () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminOrdersScreen())),
              ),
              _buildAdminTile(
                context,
                'Migrate Legacy Data',
                Icons.system_update_alt,
                Colors.purple,
                () async {
                   try {
                     ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Starting migration...')));
                     await ref.read(firestoreServiceProvider).migrateLegacyItems();
                     ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Migration Complete! Items restored.')));
                   } catch (e) {
                     ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                   }
                },
              ),
            ],
          ),
        );
      },
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (err, stack) => Scaffold(body: Center(child: Text('Error: $err'))),
    );
  }

  Widget _buildAdminTile(BuildContext context, String title, IconData icon, Color color, VoidCallback onTap) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.1),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        onTap: onTap,
      ),
    );
  }
}
