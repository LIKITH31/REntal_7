import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/models/order_models.dart'; // Use new comprehensive models
import '../../../../core/providers/items_provider.dart'; // For firestoreServiceProvider
import '../../../../core/providers/auth_provider.dart';

final userOrdersProvider = StreamProvider<List<OrderModel>>((ref) {
  final user = ref.watch(currentUserProvider);
  final firestoreService = ref.watch(firestoreServiceProvider);

  if (user == null) return Stream.value([]);

  return firestoreService.getUserOrders(user.uid);
});

final authStateChangesProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});
