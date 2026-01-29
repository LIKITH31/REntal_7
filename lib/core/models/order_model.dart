import 'package:cloud_firestore/cloud_firestore.dart';

class OrderModel {
  final String id;
  final String orderNumber; // New field
  final String orderType;   // 'rental' or 'sale'
  final String userId; // Renter
  final String status; // pending, confirmed, active, completed, cancelled
  final double totalAmount;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int itemCount;
  
  // UI Summary Fields (denormalized)
  final String itemName;
  final String? itemImage;
  final DateTime? startDate;
  final DateTime? endDate;

  OrderModel({
    required this.id,
    this.orderNumber = '', // Default empty, usually generated on creation
    this.orderType = 'rental', 
    required this.userId,
    required this.status,
    required this.totalAmount,
    required this.createdAt,
    required this.updatedAt,
    this.itemCount = 0,
    this.itemName = '',
    this.itemImage,
    this.startDate,
    this.endDate,
  });

  factory OrderModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return OrderModel(
      id: doc.id,
      orderNumber: data['orderNumber'] ?? '',
      orderType: data['orderType'] ?? 'rental',
      userId: data['userId'] ?? data['renterId'] ?? '',
      status: data['status'] ?? 'pending',
      totalAmount: _parseDouble(data['totalAmount']),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      itemCount: _parseInt(data['itemCount']),
      itemName: data['itemName'] ?? '',
      itemImage: data['itemImage'],
      startDate: (data['startDate'] as Timestamp?)?.toDate(),
      endDate: (data['endDate'] as Timestamp?)?.toDate(),
    );
  }
  
  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  Map<String, dynamic> toFirestore() {
    return {
      'orderNumber': orderNumber,
      'orderType': orderType,
      'userId': userId,
      'status': status,
      'totalAmount': totalAmount,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'itemCount': itemCount,
      'itemName': itemName,
      'itemImage': itemImage,
      'startDate': startDate != null ? Timestamp.fromDate(startDate!) : null,
      'endDate': endDate != null ? Timestamp.fromDate(endDate!) : null,
    };
  }
}

class OrderItemModel {
  final String id; // Subcollection doc id (could be same as productId)
  final String productId;
  final String title;
  final double price; // rent or sale price at time of order
  final int quantity;
  final String type; // 'rental' or 'sale'
  final DateTime? rentalStartDate;
  final DateTime? rentalEndDate;

  OrderItemModel({
    required this.id,
    required this.productId,
    required this.title,
    required this.price,
    this.quantity = 1,
    required this.type,
    this.rentalStartDate,
    this.rentalEndDate,
  });

  factory OrderItemModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return OrderItemModel(
      id: doc.id,
      productId: data['productId'] ?? '',
      title: data['title'] ?? '',
      price: OrderModel._parseDouble(data['price']), // Use static helper from OrderModel
      quantity: data['quantity'] ?? 1,
      type: data['type'] ?? 'rental',
      rentalStartDate: (data['rentalStartDate'] as Timestamp?)?.toDate(),
      rentalEndDate: (data['rentalEndDate'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'productId': productId,
      'title': title,
      'price': price,
      'quantity': quantity,
      'type': type,
      'rentalStartDate': rentalStartDate != null ? Timestamp.fromDate(rentalStartDate!) : null,
      'rentalEndDate': rentalEndDate != null ? Timestamp.fromDate(rentalEndDate!) : null,
    };
  }
}
