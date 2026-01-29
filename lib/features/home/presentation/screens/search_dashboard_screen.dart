import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/models/product_model.dart';
import '../../../../core/providers/items_provider.dart';
import '../../../../core/providers/location_provider.dart';
import '../../../../core/services/location_service.dart';
import '../../../booking/presentation/booking_screen.dart';
import 'item_details_screen.dart';

class SearchDashboardScreen extends ConsumerStatefulWidget {
  const SearchDashboardScreen({super.key});

  @override
  ConsumerState<SearchDashboardScreen> createState() =>
      _SearchDashboardScreenState();
}

class _SearchDashboardScreenState extends ConsumerState<SearchDashboardScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  ProductModel? _selectedProduct;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Search items...',
            border: InputBorder.none,
            hintStyle: TextStyle(color: Colors.white70),
          ),
          style: const TextStyle(color: Colors.white),
          onChanged: (value) {
            setState(() {
              _searchQuery = value;
              // Reset selection when typing new query
              if (_selectedProduct != null) {
                _selectedProduct = null;
              }
            });
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () {
              if (_searchQuery.isNotEmpty) {
                _searchController.clear();
                setState(() {
                  _searchQuery = '';
                  _selectedProduct = null;
                });
              } else {
                Navigator.pop(context);
              }
            },
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_selectedProduct != null) {
      return _buildSelectedProductView(_selectedProduct!);
    }

    // WATCH allProductsProvider here to get "Trending" or "Popular" items
    // We reuse this for both empty state (Trending) and search filtering (via searchProductsProvider internal logic)
    final allProductsAsync = ref.watch(allProductsProvider);

    if (_searchQuery.isEmpty) {
      return allProductsAsync.when(
        data: (products) {
          // Show top 5 items as "Trending" or just random ones
          final trending = products.take(5).toList();
          
          if (trending.isEmpty) {
             return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search, size: 80, color: Colors.grey.withOpacity(0.3)),
                  const SizedBox(height: 16),
                  Text(
                    'Type to search items',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.grey,
                        ),
                  ),
                ],
              ),
            ).animate().fadeIn();
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    const Icon(Icons.trending_up, color: Colors.indigo),
                    const SizedBox(width: 8),
                    Text(
                      'Trending Items',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.indigo,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: trending.length,
                  itemBuilder: (context, index) {
                    final product = trending[index];
                    return _buildProductListItem(product, index);
                  },
                ),
              ),
            ],
          ).animate().fadeIn();
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const SizedBox(), // Show nothing on error/initial load
      );
    }

    final searchAsync = ref.watch(searchProductsProvider(_searchQuery));

    return searchAsync.when(
      data: (products) {
        if (products.isEmpty) {
          return Center(
            child: Text(
              'No items found starting with "$_searchQuery"',
              style: const TextStyle(color: Colors.grey),
            ),
          );
        }

        return ListView.builder(
          itemCount: products.length,
          itemBuilder: (context, index) {
            final product = products[index];
            return _buildProductListItem(product, index);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error: $err')),
    );
  }

  Widget _buildProductListItem(ProductModel product, int index) {
      return ListTile(
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: _getCategoryColor(product.categoryName).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            _getCategoryIcon(product.categoryName),
            color: _getCategoryColor(product.categoryName),
          ),
        ),
        title: Text(
          product.title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          '₹${product.rentalPricePerDay.toInt()}/day • ${product.location.city ?? "Nearby"}',
          style: const TextStyle(fontSize: 12),
        ),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
        onTap: () {
          setState(() {
            _selectedProduct = product;
          });
        },
      ).animate().fadeIn(delay: (index * 50).ms).slideX(begin: 0.1);
  }

  Widget _buildSelectedProductView(ProductModel item) {
    // Reusing the card style from HomeScreen but adapted for single view
    final color = _getCategoryColor(item.categoryName);
    final icon = _getCategoryIcon(item.categoryName);

    // Calculate distance
    final currentLocationAsync = ref.watch(currentLocationProvider);
    String? distanceText;
    currentLocationAsync.whenData((position) {
      if (position != null) {
        final distance = item.location.distanceFrom(
          position.latitude,
          position.longitude,
        );
        distanceText = LocationService.formatDistance(distance);
      }
    });

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Back to results button
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () {
                setState(() {
                  _selectedProduct = null;
                });
              },
              icon: const Icon(Icons.arrow_back),
              label: const Text('Back to results'),
            ),
          ),
          const SizedBox(height: 16),
          // Large Item Card
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ItemDetailsScreen(item: item),
                ),
              );
            },
            child: Container(
              height: 500, // Fixed height for consistency
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [color.withOpacity(0.8), color],
                    ),
                  ),
                  child: Stack(
                    children: [
                      // Content
                      Positioned.fill(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (distanceText != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 16.0),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.location_on,
                                        size: 16,
                                        color: Colors.white,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        distanceText!,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ).animate().fadeIn(delay: 200.ms),
                            Icon(icon, size: 120, color: Colors.white)
                                .animate()
                                .scale(duration: 500.ms, curve: Curves.easeOut),
                            const SizedBox(height: 24),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16.0),
                              child: Text(
                                item.title,
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '₹${item.rentalPricePerDay.toInt()}/day',
                              style: const TextStyle(
                                fontSize: 20,
                                color: Colors.white70,
                              ),
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => BookingScreen(item: item),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: color,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 32,
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                              ),
                              child: const Text(
                                'Rent Now',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ).animate().fadeIn(delay: 300.ms).scale(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ).animate().fadeIn().scale(),
        ],
      ),
    );
  }

  // Duplicate helpers from HomeScreen (since we don't want to change global utils right now)
  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'electronics':
        return Colors.blue;
      case 'vehicles':
        return Colors.orange;
      case 'sports':
        return Colors.green;
      case 'tools':
        return Colors.red;
      case 'furniture':
        return Colors.purple;
      case 'clothing':
        return Colors.pink;
      default:
        return Colors.indigo;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'electronics':
        return Icons.devices;
      case 'vehicles':
        return Icons.directions_car;
      case 'sports':
        return Icons.sports_basketball;
      case 'tools':
        return Icons.construction;
      case 'furniture':
        return Icons.chair;
      case 'clothing':
        return Icons.checkroom;
      default:
        return Icons.inventory;
    }
  }
}
