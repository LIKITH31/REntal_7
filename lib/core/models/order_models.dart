import 'package:cloud_firestore/cloud_firestore.dart';

// Main Order Document
class OrderModel {
  final String id;
  final String orderNumber;
  final String orderType; // rental | sale
  final String
  orderStatus; // pending | paid | confirmed | active | completed | cancelled
  final String paymentStatus; // pending | completed | failed | refunded

  // Financial fields
  final double depositAmount;
  final double finalAmount;
  final double totalAmount;
  final double taxAmount;

  final String userId;

  final DateTime createdAt;
  final DateTime updatedAt;

  OrderModel({
    required this.id,
    required this.orderNumber,
    required this.orderType,
    required this.orderStatus,
    required this.paymentStatus,
    required this.depositAmount,
    required this.finalAmount,
    required this.totalAmount,
    required this.taxAmount,
    required this.userId,
    required this.createdAt,
    required this.updatedAt,
  });

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  factory OrderModel.fromMap(Map<String, dynamic> map) {
    return OrderModel(
      id: map['id'] ?? '',
      orderNumber: map['orderNumber'] ?? '',
      orderType: map['orderType'] ?? 'rental',
      orderStatus: map['orderStatus'] ?? 'pending',
      paymentStatus: map['paymentStatus'] ?? 'pending',
      depositAmount: _parseDouble(map['depositAmount']),
      finalAmount: _parseDouble(map['finalAmount']),
      totalAmount: _parseDouble(map['totalAmount']),
      taxAmount: _parseDouble(map['taxAmount']),
      userId: map['userId'] ?? '',
      createdAt: map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: map['updatedAt'] is Timestamp
          ? (map['updatedAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  factory OrderModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return OrderModel.fromMap({...data, 'id': doc.id});
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'orderNumber': orderNumber,
      'orderType': orderType,
      'orderStatus': orderStatus,
      'paymentStatus': paymentStatus,
      'depositAmount': depositAmount,
      'finalAmount': finalAmount,
      'totalAmount': totalAmount,
      'taxAmount': taxAmount,
      'userId': userId,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  Map<String, dynamic> toFirestore() => toMap();
}

// Order Item Model (subcollection: orders/{orderId}/items/{itemId})
class OrderItemModel {
  final String id;
  final String productId;
  final String productName;
  final int quantity;
  final double unitPrice;
  final double totalPrice;
  final DateTime rentalStartDate;
  final DateTime rentalEndDate;
  final DateTime createdAt;

  OrderItemModel({
    required this.id,
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
    required this.rentalStartDate,
    required this.rentalEndDate,
    required this.createdAt,
  });

  factory OrderItemModel.fromMap(Map<String, dynamic> map) {
    return OrderItemModel(
      id: map['id'] ?? '',
      productId: map['productId'] ?? '',
      productName: map['productName'] ?? '',
      quantity: map['quantity'] ?? 1,
      unitPrice: OrderModel._parseDouble(map['unitPrice']),
      totalPrice: OrderModel._parseDouble(map['totalPrice']),
      rentalStartDate: map['rentalStartDate'] is Timestamp
          ? (map['rentalStartDate'] as Timestamp).toDate()
          : DateTime.now(),
      rentalEndDate: map['rentalEndDate'] is Timestamp
          ? (map['rentalEndDate'] as Timestamp).toDate()
          : DateTime.now(),
      createdAt: map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  factory OrderItemModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return OrderItemModel.fromMap({...data, 'id': doc.id});
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'productId': productId,
      'productName': productName,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'totalPrice': totalPrice,
      'rentalStartDate': Timestamp.fromDate(rentalStartDate),
      'rentalEndDate': Timestamp.fromDate(rentalEndDate),
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  Map<String, dynamic> toFirestore() => toMap();
}

// Order Transaction Model (subcollection: orders/{orderId}/transactions/{transactionId})
class OrderTransactionModel {
  final String id;
  final String transactionType; // payment | refund | deposit
  final String transactionStatus; // success | failed | pending
  final double amount;
  final String paymentMethod; // upi | credit_card | debit_card
  final String gatewayName;
  final String gatewayTransactionId;
  final String? errorCode;
  final String userId;
  final DateTime createdAt;

  OrderTransactionModel({
    required this.id,
    required this.transactionType,
    required this.transactionStatus,
    required this.amount,
    required this.paymentMethod,
    required this.gatewayName,
    required this.gatewayTransactionId,
    this.errorCode,
    required this.userId,
    required this.createdAt,
  });

  factory OrderTransactionModel.fromMap(Map<String, dynamic> map) {
    return OrderTransactionModel(
      id: map['id'] ?? '',
      transactionType: map['transactionType'] ?? 'payment',
      transactionStatus: map['transactionStatus'] ?? 'pending',
      amount: OrderModel._parseDouble(map['amount']),
      paymentMethod: map['paymentMethod'] ?? '',
      gatewayName: map['gatewayName'] ?? '',
      gatewayTransactionId: map['gatewayTransactionId'] ?? '',
      errorCode: map['errorCode'],
      userId: map['userId'] ?? '',
      createdAt: map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  factory OrderTransactionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return OrderTransactionModel.fromMap({...data, 'id': doc.id});
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'transactionType': transactionType,
      'transactionStatus': transactionStatus,
      'amount': amount,
      'paymentMethod': paymentMethod,
      'gatewayName': gatewayName,
      'gatewayTransactionId': gatewayTransactionId,
      'errorCode': errorCode,
      'userId': userId,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  Map<String, dynamic> toFirestore() => toMap();
}

// Order Rental Model (subcollection: orders/{orderId}/rentals/details)
class OrderRentalModel {
  final String id; // Usually 'details'
  final double depositAmount;
  final DateTime startDate;
  final DateTime endDate;
  final String returnStatus; // pending | returned
  final DateTime? returnedAt;
  final String refundStatus; // pending | refunded
  final DateTime? refundedAt;

  OrderRentalModel({
    required this.id,
    required this.depositAmount,
    required this.startDate,
    required this.endDate,
    required this.returnStatus,
    this.returnedAt,
    required this.refundStatus,
    this.refundedAt,
  });

  factory OrderRentalModel.fromMap(Map<String, dynamic> map) {
    return OrderRentalModel(
      id: map['id'] ?? 'details',
      depositAmount: OrderModel._parseDouble(map['depositAmount']),
      startDate: map['startDate'] is Timestamp
          ? (map['startDate'] as Timestamp).toDate()
          : DateTime.now(),
      endDate: map['endDate'] is Timestamp
          ? (map['endDate'] as Timestamp).toDate()
          : DateTime.now(),
      returnStatus: map['returnStatus'] ?? 'pending',
      returnedAt: map['returnedAt'] is Timestamp
          ? (map['returnedAt'] as Timestamp).toDate()
          : null,
      refundStatus: map['refundStatus'] ?? 'pending',
      refundedAt: map['refundedAt'] is Timestamp
          ? (map['refundedAt'] as Timestamp).toDate()
          : null,
    );
  }

  factory OrderRentalModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return OrderRentalModel.fromMap({...data, 'id': doc.id});
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'depositAmount': depositAmount,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'returnStatus': returnStatus,
      'returnedAt': returnedAt != null ? Timestamp.fromDate(returnedAt!) : null,
      'refundStatus': refundStatus,
      'refundedAt': refundedAt != null ? Timestamp.fromDate(refundedAt!) : null,
    };
  }

  Map<String, dynamic> toFirestore() => toMap();
}
