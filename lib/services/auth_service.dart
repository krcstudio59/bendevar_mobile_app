import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user_model.dart'; // UserModel'i kullanacağız

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

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
  Future<UserModel?> registerWithEmailAndPassword(
      String email, String password, String name, String phoneNumber) async {
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
        name: name,
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

  Future<UserModel?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        return null; // Kullanıcı giriş yapmaktan vazgeçti
      }

      // E-posta kontrolü (.edu.tr)
      if (googleUser.email.isEmpty ||
          !googleUser.email.toLowerCase().endsWith('.edu.tr')) {
        await _googleSignIn.signOut(); // Google oturumunu kapat
        // Firebase tarafında bir oturum açılmadı henüz, bu yüzden _auth.signOut() gerekmiyor.
        throw FirebaseAuthException(
            code: 'invalid-email',
            message:
                'Lütfen .edu.tr uzantılı bir öğrenci e-postası ile giriş yapın.');
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential userCredential =
          await _auth.signInWithCredential(credential);
      User? firebaseUser = userCredential.user;

      if (firebaseUser != null) {
        // Firestore'da kullanıcı var mı kontrol et
        final userDoc =
            await _firestore.collection('users').doc(firebaseUser.uid).get();

        if (userDoc.exists) {
          // Mevcut kullanıcı, verileri döndür
          return UserModel.fromJson(userDoc.data()!, userDoc.id);
        } else {
          // Yeni kullanıcı, Firestore'a kaydet
          UserModel newUser = UserModel(
            id: firebaseUser.uid,
            uid: firebaseUser.uid,
            email: firebaseUser.email,
            name: firebaseUser.displayName,
            profileImageUrl: firebaseUser.photoURL,
            createdAt: Timestamp.now(),
            // phoneNumber ve diğer özel alanlar için varsayılan veya null
          );
          await _firestore
              .collection('users')
              .doc(firebaseUser.uid)
              .set(newUser.toJson());
          return newUser;
        }
      }
      return null;
    } catch (e) {
      print(e.toString());
      rethrow;
    }
  }

  // Çıkış yap
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut(); // Google oturumunu da kapat
      await _auth.signOut();
    } catch (e) {
      print(e.toString());
      rethrow;
    }
  }
}
