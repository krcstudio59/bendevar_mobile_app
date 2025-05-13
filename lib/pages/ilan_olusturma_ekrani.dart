import 'dart:io'; // Dosya işlemleri için
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart'; // Fotoğraf seçimi için
import '../models/ilan_model.dart';
import '../services/ilan_service.dart';
import '../services/storage_service.dart'; // Storage servisi import edildi

class IlanOlusturmaEkrani extends StatefulWidget {
  final String? initialIlanTipi; // Initial type parameter

  const IlanOlusturmaEkrani(
      {super.key, this.initialIlanTipi}); // Updated constructor

  @override
  State<IlanOlusturmaEkrani> createState() => _IlanOlusturmaEkraniState();
}

class _IlanOlusturmaEkraniState extends State<IlanOlusturmaEkrani> {
  final _formKey = GlobalKey<FormState>();
  final _baslikController = TextEditingController();
  final _aciklamaController = TextEditingController();
  final _kategoriController = TextEditingController();
  final _lokasyonController = TextEditingController();

  String _seciliIlanTipi = 'BendeVar'; // Varsayılan olarak
  bool _isLoading = false;
  File? _secilenFotograf; // Seçilen fotoğraf dosyasını tutacak state

  @override
  void initState() {
    super.initState();
    // Set the initial selected type if provided
    if (widget.initialIlanTipi != null &&
        (widget.initialIlanTipi == 'BendeVar' ||
            widget.initialIlanTipi == 'BanaLazim')) {
      _seciliIlanTipi = widget.initialIlanTipi!;
    }
  }

  @override
  void dispose() {
    _baslikController.dispose();
    _aciklamaController.dispose();
    _kategoriController.dispose();
    _lokasyonController.dispose();
    super.dispose();
  }

  // Fotoğraf seçme fonksiyonu
  Future<void> _fotoSec() async {
    final storageService = context.read<StorageService>();
    // Şimdilik sadece galeriden seçtiriyoruz
    final XFile? pickedFile =
        await storageService.fotografSec(ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _secilenFotograf = File(pickedFile.path);
      });
    }
  }

  Future<void> _ilaniKaydet() async {
    if (!_formKey.currentState!.validate()) {
      return; // Form geçerli değilse işlemi durdur
    }
    if (_seciliIlanTipi == 'BendeVar' && _secilenFotograf == null) {
      // BendeVar ilanı için fotoğraf zorunluysa bu kontrolü ekle
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen bir ürün fotoğrafı seçin.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      // Kullanıcı giriş yapmamışsa hata göster
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('İlan oluşturmak için giriş yapmalısınız.')),
      );
      setState(() {
        _isLoading = false;
      });
      return;
    }

    String? fotografIndirmeUrl;
    final ilanService = context.read<IlanService>();
    final storageService = context.read<StorageService>();

    try {
      // Eğer "BendeVar" ilanı ve fotoğraf seçilmişse yükle
      if (_seciliIlanTipi == 'BendeVar' && _secilenFotograf != null) {
        fotografIndirmeUrl = await storageService.ilanFotografiYukle(
          userId: user.uid,
          imageFile: _secilenFotograf!,
        );
        if (fotografIndirmeUrl == null) {
          // Fotoğraf yükleme hatası
          throw Exception('Fotoğraf yüklenemedi.');
        }
      }

      // Yeni Ilan nesnesi oluştur
      final yeniIlan = Ilan(
        id: '', // Firestore ID'yi otomatik atayacak
        userId: user.uid,
        ilanTipi: _seciliIlanTipi,
        baslik: _baslikController.text,
        aciklama: _aciklamaController.text,
        kategori: _kategoriController.text,
        lokasyon: _lokasyonController.text,
        olusturulmaTarihi: Timestamp.now(),
        fotografUrl: fotografIndirmeUrl, // Yüklenen fotoğrafın URL'si
        aktifMi: true,
      );

      // İlanı Firestore'a ekle
      await ilanService.ilanEkle(yeniIlan);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('İlan başarıyla oluşturuldu!')),
      );
      if (mounted) Navigator.of(context).pop(); // Ekranı kapat
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Bir hata oluştu: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('$_seciliIlanTipi İlanı Oluştur'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // İlan Tipi Seçimi (ToggleButtons)
              Center(
                child: ToggleButtons(
                  isSelected: [
                    _seciliIlanTipi == 'BendeVar',
                    _seciliIlanTipi == 'BanaLazim'
                  ],
                  onPressed: (index) {
                    setState(() {
                      _seciliIlanTipi = index == 0 ? 'BendeVar' : 'BanaLazim';
                    });
                  },
                  borderRadius: BorderRadius.circular(8.0),
                  selectedBorderColor: Colors.deepPurple,
                  selectedColor: Colors.white,
                  fillColor: Colors.deepPurple.shade300,
                  color: Colors.deepPurple,
                  constraints:
                      const BoxConstraints(minHeight: 40.0, minWidth: 100.0),
                  children: const [
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text('Bende Var'),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text('Bana Lazım'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Başlık
              TextFormField(
                controller: _baslikController,
                decoration: const InputDecoration(
                  labelText: 'Başlık',
                  hintText: 'Örn: Çalışma Masası',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Başlık boş bırakılamaz.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Açıklama
              TextFormField(
                controller: _aciklamaController,
                decoration: const InputDecoration(
                  labelText: 'Açıklama',
                  hintText: 'Eşyanın durumu, özellikleri vb.',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Açıklama boş bırakılamaz.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Kategori
              TextFormField(
                controller: _kategoriController,
                decoration: const InputDecoration(
                  labelText: 'Kategori',
                  hintText: 'Örn: Mobilya, Elektronik, Kitap',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Kategori boş bırakılamaz.';
                  }
                  return null;
                }, // Şimdilik serbest metin, ileride Dropdown olabilir
              ),
              const SizedBox(height: 16),

              // Lokasyon
              TextFormField(
                controller: _lokasyonController,
                decoration: const InputDecoration(
                  labelText: 'Lokasyon',
                  hintText: 'Örn: Kampüs İçi / İstanbul, Kadıköy',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Lokasyon boş bırakılamaz.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Fotoğraf Ekleme Alanı (Sadece BendeVar için)
              if (_seciliIlanTipi == 'BendeVar')
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Ürün Fotoğrafı',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Center(
                      child: _secilenFotograf != null
                          ? Image.file(
                              _secilenFotograf!,
                              height: 150,
                              width: 150,
                              fit: BoxFit.cover,
                            )
                          : Container(
                              height: 150,
                              width: 150,
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.image_not_supported,
                                  color: Colors.grey, size: 50),
                            ),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: ElevatedButton.icon(
                        onPressed: _fotoSec,
                        icon: const Icon(Icons.camera_alt),
                        label: Text(_secilenFotograf == null
                            ? 'Fotoğraf Seç'
                            : 'Fotoğrafı Değiştir'),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),

              // Kaydet Butonu
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _ilaniKaydet,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        backgroundColor: Colors.deepPurple, // Buton rengi
                        foregroundColor: Colors.white, // Yazı rengi
                      ),
                      child: const Text('İlanı Yayınla'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
