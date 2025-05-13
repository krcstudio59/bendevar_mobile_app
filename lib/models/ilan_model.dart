import 'package:cloud_firestore/cloud_firestore.dart';

class Ilan {
  final String id; // Document ID from Firestore
  final String userId; // ID of the user who created the listing
  final String ilanTipi; // 'BendeVar' or 'BanaLazim'
  final String baslik; // Item title
  final String aciklama; // Description
  final String kategori; // Category (e.g., 'Elektronik', 'Mobilya')
  final String lokasyon; // Location (e.g., 'İstanbul/Kadıköy')
  final String? fotografUrl; // Optional photo URL from Firebase Storage
  final Timestamp olusturulmaTarihi; // Creation timestamp
  final bool aktifMi; // Is the listing still active?

  Ilan({
    required this.id,
    required this.userId,
    required this.ilanTipi,
    required this.baslik,
    required this.aciklama,
    required this.kategori,
    required this.lokasyon,
    this.fotografUrl,
    required this.olusturulmaTarihi,
    this.aktifMi = true, // Default to active
  });

  // Convert Ilan object to a Map for Firestore
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'ilanTipi': ilanTipi,
      'baslik': baslik,
      'aciklama': aciklama,
      'kategori': kategori,
      'lokasyon': lokasyon,
      'fotografUrl': fotografUrl,
      'olusturulmaTarihi': olusturulmaTarihi,
      'aktifMi': aktifMi,
    };
  }

  // Create Ilan object from Firestore DocumentSnapshot
  factory Ilan.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Ilan(
      id: doc.id,
      userId: data['userId'] ?? '',
      ilanTipi: data['ilanTipi'] ?? '',
      baslik: data['baslik'] ?? '',
      aciklama: data['aciklama'] ?? '',
      kategori: data['kategori'] ?? '',
      lokasyon: data['lokasyon'] ?? '',
      fotografUrl: data['fotografUrl'], // Can be null
      olusturulmaTarihi:
          data['olusturulmaTarihi'] ?? Timestamp.now(), // Provide default
      aktifMi: data['aktifMi'] ?? true, // Default to active if missing
    );
  }
}
