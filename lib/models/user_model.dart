// Placeholder for User model
// Will include fields like: uid, name, email, phone, studentInfo, isVerified, etc.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'student_info_model.dart';

class UserModel {
  final String id; // Document ID from Firestore
  final String uid; // Firebase Auth User ID
  final String? name;
  final String? email;
  final String? phoneNumber;
  final String? profileImageUrl;
  final StudentInfoModel? studentInfo;
  final String? studentDocumentUrl;
  final bool isStudentVerified;
  final String? address;
  final Map<String, String>? socialMediaLinks;
  final int score;
  final Timestamp? createdAt;

  UserModel({
    required this.id,
    required this.uid,
    this.name,
    this.email,
    this.phoneNumber,
    this.profileImageUrl,
    this.studentInfo,
    this.studentDocumentUrl,
    this.isStudentVerified = false,
    this.address,
    this.socialMediaLinks,
    this.score = 0,
    this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json, String documentId) {
    return UserModel(
      id: documentId,
      uid: json['uid'] as String? ?? '',
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phoneNumber: json['phoneNumber'] as String? ?? '',
      profileImageUrl: json['profileImageUrl'] as String? ?? '',
      studentInfo: json['studentInfo'] != null
          ? StudentInfoModel.fromJson(
              json['studentInfo'] as Map<String, dynamic>)
          : null,
      studentDocumentUrl: json['studentDocumentUrl'] as String? ?? '',
      isStudentVerified: json['isStudentVerified'] as bool? ?? false,
      address: json['address'] as String? ?? '',
      socialMediaLinks: json['socialMediaLinks'] != null
          ? Map<String, String>.from(json['socialMediaLinks'] as Map)
          : {},
      score: json['score'] as int? ?? 0,
      createdAt: json['createdAt'] as Timestamp? ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      // id alanı Firestore tarafından otomatik yönetildiği için toJson'a eklenmez.
      'uid': uid,
      'name': name,
      'email': email,
      'phoneNumber': phoneNumber,
      'profileImageUrl': profileImageUrl,
      'studentInfo': studentInfo?.toJson(),
      'studentDocumentUrl': studentDocumentUrl,
      'isStudentVerified': isStudentVerified,
      'address': address,
      'socialMediaLinks': socialMediaLinks,
      'score': score,
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
    };
  }
}
