import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Giriş yapmış kullanıcıyı al
  User? get currentUser => _auth.currentUser;

  // Kullanıcı durumu değişikliklerini dinle
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // E-posta/şifre ile kayıt ol
  Future<UserCredential> registerWithEmailAndPassword(
      String email, String password, Map<String, dynamic> userData) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Kullanıcı bilgilerini Firestore'a kaydet
      await _firestore
          .collection('users')
          .doc(userCredential.user!.uid)
          .set(userData);

      return userCredential;
    } catch (e) {
      rethrow;
    }
  }

  // E-posta/şifre ile giriş yap
  Future<UserCredential> signInWithEmailAndPassword(
      String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      rethrow;
    }
  }

  // Çıkış yap
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      rethrow;
    }
  }
}
