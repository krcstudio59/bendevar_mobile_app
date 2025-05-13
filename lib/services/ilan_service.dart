import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/ilan_model.dart';

class IlanService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 'ilanlar' koleksiyonuna referans
  // Koleksiyon adını istediğiniz gibi değiştirebilirsiniz.
  late final CollectionReference _ilanlarCollection;

  IlanService() {
    _ilanlarCollection = _firestore.collection('ilanlar');
  }

  // Yeni ilan ekleme fonksiyonu
  Future<DocumentReference> ilanEkle(Ilan ilan) async {
    try {
      // Ilan nesnesini Firestore'a göndermeden önce Map'e çeviriyoruz.
      // Modeldeki toJson metodu id'yi dışarıda bırakmalı veya
      // burada id olmadan bir map oluşturmalıyız.
      // Mevcut toJson metodu id'yi içermiyor, bu yüzden doğrudan kullanabiliriz.
      return await _ilanlarCollection.add(ilan.toJson());
    } catch (e) {
      print('İlan eklerken hata oluştu: $e');
      rethrow; // Hatanın üst katmanlara bildirilmesi için
    }
  }

  // İlanları getiren stream fonksiyonu
  // Tarihe göre en yeniden eskiye doğru sıralar
  Stream<List<Ilan>> ilanlariGetir() {
    return _ilanlarCollection
        .orderBy('olusturulmaTarihi', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        // Her bir dökümanı Ilan nesnesine çeviriyoruz
        return Ilan.fromFirestore(doc);
      }).toList();
    }).handleError((error) {
      // Stream hatalarını yönetme
      print("İlanları getirirken hata: $error");
      return []; // Hata durumunda boş liste döndür
    });
  }

  // TODO: İleride eklenecek metotlar:
  // - Ilan guncelleme
  // - Ilan silme
  // - Kullanıcının kendi ilanlarını getirme
  // - ID ile tek bir ilan getirme
  // - Filtreleme/Arama
}
