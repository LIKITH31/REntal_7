import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/order_model.dart';

class FirestoreOrderRepository {
  final FirebaseFirestore _firestore;

  FirestoreOrderRepository(this._firestore);

  Stream<List<OrderModel>> watchUserOrders(String userId) {
    return _firestore
        .collection('rentals') 
        .where('renterId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isNotEmpty) {
      }
      return snapshot.docs.map((doc) => OrderModel.fromFirestore(doc)).toList();
    }).handleError((e) {
      throw e; 
    });
  }

  Future<OrderModel?> getOrder(String orderId) async {
    final doc = await _firestore.collection('rentals').doc(orderId).get();
    if (doc.exists) {
      return OrderModel.fromFirestore(doc);
    }
    return null;
  }
}
