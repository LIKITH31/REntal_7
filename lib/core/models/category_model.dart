import 'package:cloud_firestore/cloud_firestore.dart';

class CategoryModel {
  final String id;
  final String name;
  final String iconUrl; // Or icon code
  final String? description;
  final bool isActive;
  final int displayOrder;

  CategoryModel({
    required this.id,
    required this.name,
    required this.iconUrl,
    this.description,
    this.isActive = true,
    this.displayOrder = 0,
  });

  factory CategoryModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CategoryModel(
      id: doc.id,
      name: data['name'] ?? '',
      iconUrl: data['iconUrl'] ?? '',
      description: data['description'],
      isActive: data['isActive'] ?? true,
      displayOrder: data['displayOrder'] ?? 0,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'iconUrl': iconUrl,
      'description': description,
      'isActive': isActive,
      'displayOrder': displayOrder,
    };
  }
}
