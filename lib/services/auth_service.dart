import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart'; // UserModel'i kullanacağız

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Giriş yapmış kullanıcıyı al
  User? get currentUser => _auth.currentUser;

  // Kullanıcı durumu değişikliklerini dinle
  Stream<UserModel?> get authStateChanges {
    return _auth.authStateChanges().asyncMap((firebaseUser) async {
      if (firebaseUser == null) {
        return null;
      }
      // Firebase kullanıcısından UserModel'e dönüştür
      // Firestore'dan kullanıcı verilerini çek
      final userDoc =
          await _firestore.collection('users').doc(firebaseUser.uid).get();
      if (userDoc.exists) {
        return UserModel.fromJson(userDoc.data()!, userDoc.id);
      }
      return null; // Firestore'da kullanıcı yoksa (bu durum nadir olmalı)
    });
  }

  // E-posta/şifre ile kayıt ol
  Future<UserModel?> registerWithEmailAndPassword(String email, String password,
      String firstName, String lastName, String phoneNumber) async {
    try {
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      UserModel newUser = UserModel(
        id: userCredential.user!.uid,
        uid: userCredential.user!.uid,
        email: email,
        firstName: firstName,
        lastName: lastName,
        phoneNumber: phoneNumber,
        createdAt: Timestamp.now(),
        // Diğer alanlar varsayılan veya null olacak
      );

      await _firestore
          .collection('users')
          .doc(userCredential.user!.uid)
          .set(newUser.toJson());

      return newUser;
    } catch (e) {
      print(e.toString()); // Hata ayıklama için
      rethrow;
    }
  }

  // E-posta/şifre ile giriş yap
  Future<UserModel?> signInWithEmailAndPassword(
      String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final userDoc = await _firestore
          .collection('users')
          .doc(userCredential.user!.uid)
          .get();
      if (userDoc.exists) {
        return UserModel.fromJson(userDoc.data()!, userDoc.id);
      }
      return null;
    } catch (e) {
      print(e.toString());
      rethrow;
    }
  }

  // Çıkış yap (Sadece Firebase Auth çıkışı)
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      print(e.toString());
      rethrow;
    }
  }
}
