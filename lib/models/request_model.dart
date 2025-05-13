// Placeholder for Request model (for "Bana Lazım")
// Will include fields like: requestId, title, category, description, userId, createdAt.

import 'package:cloud_firestore/cloud_firestore.dart';

class RequestModel {
  final String? id;
  final String title;
  final String category;
  final String description;
  final String userId;
  final Timestamp createdAt;

  RequestModel({
    this.id,
    required this.title,
    required this.category,
    required this.description,
    required this.userId,
    required this.createdAt,
  });

  factory RequestModel.fromJson(Map<String, dynamic> json, String documentId) {
    return RequestModel(
      id: documentId,
      title: json['title'] as String? ?? '',
      category: json['category'] as String? ?? '',
      description: json['description'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      createdAt: json['createdAt'] as Timestamp? ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'category': category,
      'description': description,
      'userId': userId,
      'createdAt': createdAt,
    };
  }
}
