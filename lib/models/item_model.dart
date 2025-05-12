// Placeholder for Item model (for "Bende Var")
// Will include fields like: itemId, title, category, description, imageUrl, quantity, condition, deliveryMethod, location, userId, createdAt, favoriteCount.

import 'package:cloud_firestore/cloud_firestore.dart';

class ItemModel {
  final String? id; // Firestore document ID
  final String title;
  final String category;
  final String description;
  final List<String>? imageUrls; // Can have multiple images
  final int? quantity;
  final String condition; // e.g., "new", "used"
  final String deliveryMethod;
  final String location;
  final String userId; // ID of the user who posted the item
  final Timestamp createdAt;
  final int favoriteCount;

  ItemModel({
    this.id,
    required this.title,
    required this.category,
    required this.description,
    this.imageUrls,
    this.quantity,
    required this.condition,
    required this.deliveryMethod,
    required this.location,
    required this.userId,
    required this.createdAt,
    this.favoriteCount = 0,
  });

  factory ItemModel.fromJson(Map<String, dynamic> json, String documentId) {
    return ItemModel(
      id: documentId,
      title: json['title'] as String? ?? '',
      category: json['category'] as String? ?? '',
      description: json['description'] as String? ?? '',
      imageUrls: json['imageUrls'] != null
          ? List<String>.from(json['imageUrls'] as List<dynamic>)
              .map((e) => e.toString())
              .toList()
          : null,
      quantity: json['quantity'] as int?,
      condition: json['condition'] as String? ?? '',
      deliveryMethod: json['deliveryMethod'] as String? ?? '',
      location: json['location'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      createdAt: json['createdAt'] as Timestamp? ?? Timestamp.now(),
      favoriteCount: json['favoriteCount'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'category': category,
      'description': description,
      'imageUrls': imageUrls,
      'quantity': quantity,
      'condition': condition,
      'deliveryMethod': deliveryMethod,
      'location': location,
      'userId': userId,
      'createdAt': createdAt,
      'favoriteCount': favoriteCount,
    };
  }
}
