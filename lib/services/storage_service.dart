// Placeholder for StorageService
// This service will handle file uploads to Firebase Cloud Storage,
// such as student verification documents and item images.

import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart'; // XFile için

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();

  // Galeriden veya kameradan fotoğraf seçme
  Future<XFile?> fotografSec(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        imageQuality:
            70, // Kaliteyi biraz düşürerek dosya boyutunu azaltabiliriz
        maxWidth: 800, // Genişliği sınırlayabiliriz
      );
      return pickedFile;
    } catch (e) {
      print('Fotoğraf seçerken hata: $e');
      return null;
    }
  }

  // Seçilen fotoğrafı Firebase Storage'a yükleme
  Future<String?> ilanFotografiYukle(
      {required String userId, required File imageFile}) async {
    try {
      // Benzersiz bir dosya adı oluştur (örn: userId_timestamp.jpg)
      String fileName =
          '${userId}_${DateTime.now().millisecondsSinceEpoch}.jpg';

      // Storage'da yolu belirle (örn: ilan_fotograflari/userId/fileName)
      Reference storageRef = _storage
          .ref()
          .child('ilan_fotograflari')
          .child(userId)
          .child(fileName);

      // Dosyayı yükle
      UploadTask uploadTask = storageRef.putFile(imageFile);

      // Yükleme tamamlanınca URL'yi al
      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      print('Fotoğraf yüklerken hata: $e');
      return null;
    }
  }
}
