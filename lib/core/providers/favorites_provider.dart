import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_provider.dart';
import 'items_provider.dart';
import '../models/product_model.dart';

// Stream of favorite item IDs
final userFavoritesProvider = StreamProvider<List<String>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value([]);
  
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.getFavoritesStream(user.uid);
});

// Future of favorite Products (for the FavoritesScreen)
final favoriteItemsProvider = FutureProvider<List<ProductModel>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];
  
  final firestoreService = ref.watch(firestoreServiceProvider);
  // Trigger refresh when favorites change
  final favoritesIds = ref.watch(userFavoritesProvider).value ?? [];
  
  if (favoritesIds.isEmpty) return [];
  
  return firestoreService.getFavoriteProducts(user.uid);
});
