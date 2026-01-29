import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math' as math;
import '../../../../core/models/product_model.dart'; // Updated import
import '../../../../core/providers/items_provider.dart'; // Keeping provider import
import '../../../../core/providers/location_provider.dart';
import '../../../../core/providers/favorites_provider.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../core/services/location_service.dart';
import '../../../booking/presentation/booking_screen.dart';
import '../../../add_listing/presentation/screens/add_listing_screen.dart';
import 'item_details_screen.dart';
import 'subscription_screen.dart';
import 'search_dashboard_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> with TickerProviderStateMixin {
  late PageController _pageController;
  double _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.8);
    _pageController.addListener(() {
      setState(() {
        _currentPage = _pageController.page ?? 0;
      });
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  String? _selectedCategory;

  @override
  Widget build(BuildContext context) {
    // Watch location and products
    final currentLocationAsync = ref.watch(currentLocationProvider);
    
    // Switch to using the stream or future provider for real data
    final nearbyProductsAsync = ref.watch(nearbyProductsProvider);
    final searchRadius = ref.watch(searchRadiusProvider);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            floating: true,
            title: const Text('Discover'),
            actions: [
              // Location indicator
              currentLocationAsync.when(
                data: (position) => Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: Chip(
                    avatar: const Icon(Icons.location_on, size: 16),
                    label: Text('${searchRadius.toInt()} km'),
                    onDeleted: () {
                      _showRadiusDialog(context);
                    },
                    deleteIcon: const Icon(Icons.tune, size: 16),
                  ),
                ).animate().fadeIn(),
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
              IconButton(
                icon: const Icon(Icons.search),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SearchDashboardScreen(),
                    ),
                  );
                },
              ).animate().fadeIn().scale(),
              
              // Premium Button
              Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const SubscriptionScreen()),
                    );
                  },
                  icon: const Icon(Icons.workspace_premium, color: Color(0xFFF9F6EE)), 
                  label: const Text(
                    'Subscribe',
                    style: TextStyle(
                      color: Color(0xFFF9F6EE), 
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF781C2E), 
                    foregroundColor: const Color(0xFFF9F6EE),
                    elevation: 2,
                    shadowColor: const Color(0xFF8B2635).withValues(alpha: 0.5),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ).animate().fadeIn().scale(delay: 200.ms),
            ],
          ),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Location status
                currentLocationAsync.when(
                  data: (position) {
                    if (position == null) {
                      return Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Card(
                          color: Colors.orange.shade50,
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              children: [
                                Icon(Icons.location_off, color: Colors.orange.shade700),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Enable location to see nearby items',
                                    style: TextStyle(color: Colors.orange.shade700),
                                  ),
                                ),
                                TextButton(
                                  onPressed: () async {
                                    await LocationService.requestLocationPermission();
                                    ref.read(currentLocationProvider.notifier).refreshLocation();
                                  },
                                  child: const Text('Enable'),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ).animate().fadeIn().slideY(begin: -0.2);
                    }
                    return Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Icon(Icons.near_me, color: Theme.of(context).colorScheme.primary),
                          const SizedBox(width: 8),
                          Text(
                            'Showing items within ${searchRadius.toInt()} km',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ).animate().fadeIn();
                  },
                  loading: () => const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: 12),
                        Text('Getting your location...'),
                      ],
                    ),
                  ),
                  error: (_, __) => const SizedBox.shrink(),
                ),
                
                // Products List
                nearbyProductsAsync.when(
                  data: (products) {
                    final currentUser = ref.watch(currentUserProvider); // Get current user
                    
                    // Filter
                    final filteredProducts = products.where((item) {
                      // Filter out own items
                      if (currentUser != null && item.ownerId == currentUser.uid) {
                        return false;
                      }

                      final matchesCategory = _selectedCategory == null || item.categoryName == _selectedCategory;
                      return matchesCategory;
                    }).toList();

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text(
                            'Nearby Items (${filteredProducts.length})',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ).animate().fadeIn().slideX(begin: -0.2),
                        ),
                         if (filteredProducts.isEmpty)
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.all(32.0),
                              child: Column(
                                children: [
                                  Icon(Icons.search_off, size: 64, color: Colors.grey.shade400),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No items found nearby',
                                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                          color: Colors.grey,
                                        ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Try increasing the search radius',
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                          color: Colors.grey,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ).animate().fadeIn()
                        else
                          SizedBox(
                            height: 400,
                            child: PageView.builder(
                              controller: _pageController,
                              itemCount: filteredProducts.length,
                              itemBuilder: (context, index) {
                                return _build3DCard(filteredProducts[index], index);
                              },
                            ),
                          ),
                      ],
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (err, stack) => Center(child: Text('Error: $err')),
                ),

                const SizedBox(height: 32),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Categories',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ).animate().fadeIn().slideX(begin: -0.2, delay: 200.ms),
                ),
                _buildCategoriesGrid(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddListingScreen()),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('List Item'),
      )
          .animate()
          .fadeIn(delay: 500.ms)
          .scale(begin: const Offset(0.5, 0.5))
          .shimmer(delay: 1000.ms, duration: 1500.ms),
    );
  }

  void _showRadiusDialog(BuildContext context) {
    final currentRadius = ref.read(searchRadiusProvider);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Search Radius'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Current: ${currentRadius.toInt()} km'),
            Slider(
              value: currentRadius,
              min: 1,
              max: 50,
              divisions: 49,
              label: '${currentRadius.toInt()} km',
              onChanged: (value) {
                ref.read(searchRadiusProvider.notifier).setRadius(value);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  Widget _build3DCard(ProductModel item, int index) {
    double diff = (_currentPage - index).abs();
    double scale = 1 - (diff * 0.2).clamp(0.0, 0.2);
    double rotation = (diff * 0.3).clamp(-0.3, 0.3);

    // Get color based on category
    final color = _getCategoryColor(item.categoryName);
    final icon = _getCategoryIcon(item.categoryName);
    
    // Get distance if location available
    final currentLocationAsync = ref.watch(currentLocationProvider);
    String? distanceText;
    currentLocationAsync.whenData((position) {
      if (position != null) {
        final distance = item.location.distanceFrom(position.latitude, position.longitude);
        distanceText = LocationService.formatDistance(distance);
      }
    });

    return AnimatedBuilder(
      animation: _pageController,
      builder: (context, child) {
        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001) // perspective
            ..rotateY(rotation)
            ..scale(scale),
          child: child,
        );
      },
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ItemDetailsScreen(item: item),
            ),
          );
        },
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 24),
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
                  colors: [
                    color.withOpacity(0.8),
                    color,
                  ],
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
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.location_on, size: 16, color: Colors.white),
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
                        Icon(
                          icon,
                          size: 120,
                          color: Colors.white,
                        )
                            .animate(onPlay: (controller) => controller.repeat())
                            .shimmer(duration: 2000.ms, delay: 1000.ms)
                            .shake(hz: 0.5, curve: Curves.easeInOutCubic),
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

                  // Favorite Icon - Now inside the colored container
                  Positioned(
                    top: 16,
                    right: 16,
                    child: Consumer(
                      builder: (context, ref, child) {
                        final favorites = ref.watch(userFavoritesProvider).value ?? [];
                        final isFavorite = favorites.contains(item.id);
                        final currentUser = ref.watch(currentUserProvider);

                        return Container(
                          decoration: BoxDecoration(
                            color: Colors.black12,
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: Icon(
                              isFavorite ? Icons.favorite : Icons.favorite_border,
                              color: isFavorite ? Colors.red : Colors.white,
                              size: 24, // Smaller size
                            ),
                            onPressed: () async {
                              if (currentUser == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Please login to manage favorites')),
                                );
                                return;
                              }
                              try {
                                await ref.read(firestoreServiceProvider).toggleFavorite(currentUser.uid, item.id);
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Error: $e')),
                                  );
                                }
                              }
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

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

  Widget _buildCategoriesGrid() {
    // final selectedCategory = ref.watch(categoryFilterProvider);
    final categories = [
      CategoryItem('Electronics', Icons.devices, Colors.blue),
      CategoryItem('Vehicles', Icons.directions_car, Colors.orange),
      CategoryItem('Sports', Icons.sports_basketball, Colors.green),
      CategoryItem('Tools', Icons.construction, Colors.red),
      CategoryItem('Furniture', Icons.chair, Colors.purple),
      CategoryItem('Clothing', Icons.checkroom, Colors.pink),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 6, // Reduced block size (fits all 6 in row)
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.85, // Adjust for text height
      ),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final isSelected = _selectedCategory == categories[index].name;
        
        return GestureDetector(
          onTap: () {
            setState(() {
              if (isSelected) {
                _selectedCategory = null;
              } else {
                _selectedCategory = categories[index].name;
              }
            });
            ScaffoldMessenger.of(context).clearSnackBars(); // Clear previous snackbars
            if (!isSelected) {
               ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Showing ${categories[index].name} items'),
                  duration: const Duration(seconds: 1),
                ),
              );
            }
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: isSelected ? Border.all(color: Colors.white, width: 3) : null,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  categories[index].color.withOpacity(isSelected ? 0.9 : 0.7),
                  categories[index].color,
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: categories[index].color.withOpacity(0.3),
                  blurRadius: isSelected ? 12 : 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  categories[index].icon,
                  size: 32, // Adjusted icon size
                  color: Colors.white,
                ),
                const SizedBox(height: 12),
                Text(
                  categories[index].name,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14, // Increased font size
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        )
            .animate()
            .fadeIn(delay: (100 * index).ms)
            .scale(begin: const Offset(0.8, 0.8))
            .shimmer(delay: (500 + 100 * index).ms, duration: 1000.ms);
      },
    );
  }
}

class CategoryItem {
  final String name;
  final IconData icon;
  final Color color;

  CategoryItem(this.name, this.icon, this.color);
}
