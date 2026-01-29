import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product_model.dart';
import '../services/firestore_service.dart';
import 'location_provider.dart';
import 'auth_provider.dart';

// Firestore instance
final firestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

// Firestore service provider
final firestoreServiceProvider = Provider<FirestoreService>((ref) {
  final firestore = ref.watch(firestoreProvider);
  final auth = ref.watch(firebaseAuthProvider);
  return FirestoreService(firestore, auth);
});

// All products provider (fetches from Firestore)
final allProductsProvider = StreamProvider<List<ProductModel>>((ref) {
  final service = ref.watch(firestoreServiceProvider);
  final sampleProducts = ref.watch(sampleProductsProvider);

  return service.getAllAvailableProducts().map((firestoreProducts) {
    // Merge Real DB products with Sample Products so user always sees the 5 demo items
    // Filter out duplicates if sample IDs conflict (unlikely here)
    final allItems = [...firestoreProducts];

    for (var sample in sampleProducts) {
      if (!allItems.any((p) => p.id == sample.id)) {
        allItems.add(sample);
      }
    }
    return allItems;
  });
});

// Nearby products provider (filters by location and radius)
final nearbyProductsProvider = Provider<AsyncValue<List<ProductModel>>>((ref) {
  final allProductsAsync = ref.watch(allProductsProvider);
  final currentLocationAsync = ref.watch(currentLocationProvider);
  final searchRadius = ref.watch(searchRadiusProvider);
  final selectedLocation = ref.watch(selectedLocationProvider);

  return allProductsAsync.when(
    data: (products) {
      return currentLocationAsync.when(
        data: (currentPos) {
          final searchPos = selectedLocation ?? currentPos;

          if (searchPos == null) {
            return AsyncValue.data(products);
          }

          // Filter by distance
          final nearby = products.where((product) {
            final distance = product.location.distanceFrom(
              searchPos.latitude,
              searchPos.longitude,
            );
            return distance <= searchRadius;
          }).toList();

          // Sort by distance
          nearby.sort((a, b) {
            final distA = a.location.distanceFrom(
              searchPos.latitude,
              searchPos.longitude,
            );
            final distB = b.location.distanceFrom(
              searchPos.latitude,
              searchPos.longitude,
            );
            return distA.compareTo(distB);
          });

          return AsyncValue.data(nearby);
        },
        loading: () => const AsyncValue.loading(),
        error: (err, stack) => AsyncValue.data(products),
      );
    },
    loading: () => const AsyncValue.loading(),
    error: (err, stack) => AsyncValue.error(err, stack),
  );
});

// Products by category provider
final productsByCategoryProvider =
    Provider.family<AsyncValue<List<ProductModel>>, String>((ref, category) {
      final nearbyAsync = ref.watch(nearbyProductsProvider);

      return nearbyAsync.when(
        data: (products) {
          final filtered = products
              .where(
                (p) => p.categoryName == category || p.categoryId == category,
              )
              .toList();
          return AsyncValue.data(filtered);
        },
        loading: () => const AsyncValue.loading(),
        error: (err, stack) => AsyncValue.error(err, stack),
      );
    });

// Search products provider (Client-side filtering for reliability and flexibility)
final searchProductsProvider = Provider.family<AsyncValue<List<ProductModel>>, String>((ref, query) {
  final allProductsAsync = ref.watch(allProductsProvider);

  return allProductsAsync.when(
    data: (products) {
      if (query.isEmpty) return const AsyncValue.data([]);

      final lowerQuery = query.toLowerCase();
      final filtered = products.where((product) {
        final title = product.title.toLowerCase();
        // Check if title starts with OR contains (for robustness)
        // We prioritize startsWith logic if we wanted, but 'contains' is better for users.
        return title.contains(lowerQuery); 
      }).toList();

      return AsyncValue.data(filtered);
    },
    loading: () => const AsyncValue.loading(),
    error: (err, stack) => AsyncValue.error(err, stack),
  );
});

// Sample data provider (Updated to ProductModel)
final sampleProductsProvider = Provider<List<ProductModel>>((ref) {
  final currentLocationAsync = ref.watch(currentLocationProvider);

  // Helper to generate products with a given base location
  List<ProductModel> getProducts(double baseLat, double baseLng) {
      final now = DateTime.now();
      return [
        ProductModel(
          id: '1',
          title: 'Canon DSLR Camera',
          description: 'Professional DSLR camera with 24MP sensor',
          categoryId: 'electronics',
          categoryName: 'Electronics',
          rentalPricePerDay: 500,
          rentalPricePerWeek: 3000,
          rentalPricePerMonth: 10000,
          salePrice: 45000,
          securityDeposit: 5000,
          images: [],
          ownerId: 'mock_uid_canon_owner',
          ownerName: 'John Doe',
          location: ProductLocation(
            latitude: baseLat + 0.01,
            longitude: baseLng + 0.01,
            address: '123 Camera Street, Delhi',
            city: 'Delhi',
            state: 'Delhi',
            country: 'India',
          ),
          createdAt: now.subtract(const Duration(days: 5)),
          updatedAt: now,
          status: 'approved',
        ),
        ProductModel(
          id: '2',
          title: 'PlayStation 5',
          description: 'Latest gaming console with 2 controllers',
          categoryId: 'electronics',
          categoryName: 'Electronics',
          rentalPricePerDay: 800,
          rentalPricePerWeek: 5000,
          securityDeposit: 10000,
          images: [],
          ownerId: 'mock_uid_gamer',
          ownerName: 'Jane Smith',
          location: ProductLocation(
            latitude: baseLat + 0.015,
            longitude: baseLng - 0.01,
            address: '456 Gaming Avenue, Delhi',
            city: 'Delhi',
          ),
          createdAt: now.subtract(const Duration(days: 3)),
          updatedAt: now,
          status: 'approved',
        ),
        ProductModel(
          id: '3',
          title: 'DJI Drone',
          description: '4K camera drone with gimbal stabilization',
          categoryId: 'electronics',
          categoryName: 'Electronics',
          rentalPricePerDay: 1200,
          rentalPricePerWeek: 7000,
          salePrice: 65000,
          securityDeposit: 15000,
          images: [],
          ownerId: 'mock_uid_drone',
          ownerName: 'Mike Johnson',
          location: ProductLocation(
            latitude: baseLat - 0.01,
            longitude: baseLng + 0.015,
            address: '789 Drone Park, Delhi',
          ),
          createdAt: now.subtract(const Duration(days: 7)),
          updatedAt: now,
          status: 'approved',
        ),
        ProductModel(
          id: '4',
          title: 'Mountain Bike',
          description: 'Rugged terrain bike with 21-speed gears',
          categoryId: 'sports',
          categoryName: 'Sports',
          rentalPricePerDay: 400,
          rentalPricePerWeek: 2000,
          salePrice: 15000,
          securityDeposit: 3000,
          images: [],
          ownerId: 'mock_uid_bike',
          ownerName: 'Alex Rider',
          location: ProductLocation(
            latitude: baseLat + 0.02,
            longitude: baseLng - 0.02,
            address: 'Trail Head, Delhi',
          ),
          createdAt: now.subtract(const Duration(days: 2)),
          updatedAt: now,
          status: 'approved',
        ),
        ProductModel(
          id: '5',
          title: 'Projector 4K',
          description: 'High definition projector for home cinema',
          categoryId: 'electronics',
          categoryName: 'Electronics',
          rentalPricePerDay: 1500,
          rentalPricePerWeek: 8000,
          salePrice: 80000,
          securityDeposit: 20000,
          images: [],
          ownerId: 'mock_uid_projector',
          ownerName: 'Cinema Pro',
          location: ProductLocation(
            latitude: baseLat - 0.015,
            longitude: baseLng - 0.005,
            address: 'Tech Hub, Delhi',
          ),
          createdAt: now.subtract(const Duration(days: 4)),
          updatedAt: now,
          status: 'approved',
        ),
      ];
  }

  return currentLocationAsync.when(
    data: (position) {
      final baseLat = position?.latitude ?? 28.6139;
      final baseLng = position?.longitude ?? 77.2090;
      return getProducts(baseLat, baseLng);
    },
    // Return Delhi items if loading/error so app isn't empty
    loading: () => getProducts(28.6139, 77.2090), 
    error: (_, __) => getProducts(28.6139, 77.2090),
  );
});
