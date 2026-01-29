import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../../core/providers/items_provider.dart'; // Is now products_provider technically, but file name retained? I updated file content but not name? Let's check imports.
import '../../../../core/providers/location_provider.dart';
import '../../../../core/models/product_model.dart';
import '../../../home/presentation/screens/item_details_screen.dart';

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  GoogleMapController? _mapController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  
  // Default location (Delhi)
  static const CameraPosition _defaultPosition = CameraPosition(
    target: LatLng(28.6139, 77.2090), 
    zoom: 12,
  );

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Note: Provider name changed in items_provider.dart refactor to allProductsProvider
    // I need to ensure I am importing the right thing. 
    // In items_provider.dart (Step 58), I renamed allItemsProvider to allProductsProvider.
    final allProductsAsync = ref.watch(allProductsProvider); 
    final currentLocationAsync = ref.watch(currentLocationProvider);

    // Initial position based on user location
    CameraPosition initialPosition = _defaultPosition;
    currentLocationAsync.whenData((position) {
      if (position != null) {
        initialPosition = CameraPosition(
          target: LatLng(position.latitude, position.longitude),
          zoom: 13,
        );
      }
    });

    return Scaffold(
      body: Stack(
        children: [
          allProductsAsync.when(
            data: (products) {
              // Filter products
              final filteredProducts = products.where((product) {
                return _searchQuery.isEmpty || 
                    product.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                    product.description.toLowerCase().contains(_searchQuery.toLowerCase());
              }).toList();

              final markers = filteredProducts.map((product) {
                return Marker(
                  markerId: MarkerId(product.id),
                  position: LatLng(product.location.latitude, product.location.longitude),
                  infoWindow: InfoWindow(
                    title: product.title,
                    snippet: '₹${product.rentalPricePerDay}/day',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ItemDetailsScreen(item: product),
                        ),
                      );
                    },
                  ),
                );
              }).toSet();

              return GoogleMap(
                initialCameraPosition: initialPosition,
                markers: markers,
                onMapCreated: (controller) {
                  _mapController = controller;
                  // If we have a location, move to it once map is created
                  currentLocationAsync.whenData((position) {
                    if (position != null) {
                      controller.animateCamera(
                         CameraUpdate.newLatLng(LatLng(position.latitude, position.longitude))
                      );
                    }
                  });
                },
                myLocationEnabled: true,
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(child: Text('Error: $err')),
          ),
          
          // Search and Filters
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search location/items...',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () {
                            setState(() {
                              _searchController.clear();
                              _searchQuery = '';
                            });
                          },
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 15,
                        ),
                      ),
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                        });
                      },
                    ),
                  ).animate().fadeIn().slideY(begin: -0.3),
                ),
                const Spacer(),
                // Item Carousel
                Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, -5),
                      ),
                    ],
                  ),
                  child: allProductsAsync.when(
                    data: (products) {
                      final filteredProducts = products.where((product) {
                        return _searchQuery.isEmpty || 
                            product.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                            product.description.toLowerCase().contains(_searchQuery.toLowerCase());
                      }).toList();
                      
                      return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text(
                            'Nearby Items (${filteredProducts.length})',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ),
                        Expanded(
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: filteredProducts.length,
                            itemBuilder: (context, index) {
                              final product = filteredProducts[index];
                              return GestureDetector(
                                onTap: () {
                                  _mapController?.animateCamera(
                                    CameraUpdate.newLatLng(
                                      LatLng(product.location.latitude, product.location.longitude),
                                    ),
                                  );
                                },
                                child: _buildItemCard(context, product),
                              );
                            },
                          ),
                        ),
                      ],
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                ).animate().slideY(begin: 1),
              ],
            ),
          ),
          
          // My location button
          Positioned(
            right: 16,
            bottom: 220,
            child: FloatingActionButton(
              mini: true,
              onPressed: () {
                ref.read(currentLocationProvider.future).then((position) {
                  if (position != null && _mapController != null) {
                    _mapController!.animateCamera(
                      CameraUpdate.newLatLng(LatLng(position.latitude, position.longitude)),
                    );
                  }
                });
              },
              child: const Icon(Icons.my_location),
            ).animate().fadeIn(delay: 500.ms).scale(),
          ),
        ],
      ),
    );
  }

  Widget _buildItemCard(BuildContext context, ProductModel product) {
    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 12, bottom: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Theme.of(context).canvasColor, // Background
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                color: Colors.grey.shade200,
                image: product.images.isNotEmpty
                    ? DecorationImage(
                        image: NetworkImage(product.images.first),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: product.images.isEmpty
                  ? const Center(child: Icon(Icons.image, color: Colors.grey))
                  : null,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  '₹${product.rentalPricePerDay}/day',
                  style: TextStyle(
                    color: Theme.of(context).primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
