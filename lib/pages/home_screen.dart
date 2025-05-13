import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:intl/intl.dart';
// Tarih formatlama için

import '../models/ilan_model.dart'; // Ilan modelini import et
import '../services/ilan_service.dart'; // Ilan servisini import et
// import 'add_item_screen.dart'; // Kaldırıldı
// import 'add_request_screen.dart'; // Kaldırıldı
import 'settings_screen.dart';
import 'account_screen.dart';
import 'search_screen.dart';
import 'favorites_screen.dart';
import 'ilan_olusturma_ekrani.dart';
import '../utils/app_colors.dart'; // Added AppColors import
// import 'ilan_detay_ekrani.dart'; // Detay ekranı henüz yok, yorum satırı yapıldı

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  // _isLoading sadece kullanıcı verisi için kullanılacaksa kalabilir,
  // ilanlar için StreamBuilder kendi yükleme durumunu yönetecek.
  bool _isUserDataLoading = true;
  Map<String, dynamic>? _userData;
  int _selectedIndex = 0;
  // _featuredItems ve _latestItems kaldırıldı

  void _onItemTapped(int index) {
    // Ana sayfada (index 0) zaten isek ve hala veri yükleniyorsa tekrar yüklemeyi tetikleme
    // if (_selectedIndex == index && index == 0 && _isUserDataLoading) {
    //   return;
    // }
    setState(() {
      _selectedIndex = index;
      // Diğer sekmeler için özel yükleme mantığı varsa buraya eklenebilir
      // Ana sayfa (index 0) seçildiğinde kullanıcı verisini yükle (eğer zaten yüklenmediyse)
      if (index == 0 && _userData == null) {
        _loadUserData();
      }
    });
  }

  @override
  void initState() {
    super.initState();
    // Başlangıçta sadece kullanıcı verisini yükleyelim
    _loadUserData();
    // _loadItems() kaldırıldı
  }

  Future<void> _loadUserData() async {
    if (mounted) setState(() => _isUserDataLoading = true);
    try {
      final user = _auth.currentUser;
      if (user == null) {
        if (mounted) setState(() => _isUserDataLoading = false);
        return;
      }
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (userDoc.exists && mounted) {
        setState(() {
          _userData = userDoc.data();
          _isUserDataLoading = false;
        });
      } else if (mounted) {
        setState(() => _isUserDataLoading = false);
      }
    } catch (e) {
      print('Kullanıcı bilgileri yüklenirken hata: $e');
      if (mounted) setState(() => _isUserDataLoading = false);
    }
  }

  // _loadItems() metodu kaldırıldı

  // Ana Sayfa İçeriği (StreamBuilder ile)
  Widget _buildHomeContent() {
    final ilanService = context.watch<IlanService>();

    return StreamBuilder<List<Ilan>>(
      stream: ilanService.ilanlariGetir(),
      builder: (context, snapshot) {
        // Yükleniyor durumu
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        // Hata durumu
        if (snapshot.hasError) {
          print('İlan stream hatası: ${snapshot.error}');
          return const Center(
              child: Text('İlanlar yüklenirken bir hata oluştu.'));
        }

        // Veri yok veya boş durumu
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
            child: Text(
              'Görünüşe göre henüz hiç ilan yok.\nİlk ilanı sen ekle!',
              textAlign: TextAlign.center,
            ),
          );
        }

        // Veri başarıyla geldi
        final ilanlar = snapshot.data!;

        // İlanları ListView içinde göster
        return ListView.builder(
          padding: const EdgeInsets.all(8.0),
          itemCount: ilanlar.length,
          itemBuilder: (context, index) {
            final ilan = ilanlar[index];
            return _IlanKarti(ilan: ilan); // Her ilan için kart oluştur
          },
        );
      },
    );
  }

  String _getAppBarTitle() {
    // Helper method for AppBar title
    if (_isUserDataLoading) {
      return 'BendeVar'; // Default title while loading
    }
    if (_userData != null) {
      final firstName = _userData!['firstName'] as String? ?? '';
      final lastName = _userData!['lastName'] as String? ?? '';
      final fullName = "$firstName $lastName".trim();
      if (fullName.isNotEmpty) {
        return fullName;
      }
    }
    return 'BendeVar'; // Default title if no user name or data
  }

  @override
  Widget build(BuildContext context) {
    Widget currentScreen;
    switch (_selectedIndex) {
      case 0:
        currentScreen = _buildHomeContent();
        break;
      case 1:
        currentScreen = const SearchScreen();
        break;
      case 2:
        currentScreen = const FavoritesScreen();
        break;
      case 3:
        currentScreen = const AccountScreen();
        break;
      case 4:
        currentScreen = const SettingsScreen();
        break;
      default:
        currentScreen = _buildHomeContent();
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_getAppBarTitle()), // Use helper method for title
        actions: const [], // Empty actions list
      ),
      body: currentScreen,
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Ana Sayfa',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Ara',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite),
            label: 'Favorilerim',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Hesabım',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Ayarlar',
          ),
        ],
        currentIndex: _selectedIndex,
        type: BottomNavigationBarType.fixed,
        onTap: _onItemTapped,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: _selectedIndex == 0
          ? Padding(
              padding: const EdgeInsets.only(bottom: 20.0),
              child: SpeedDial(
                icon: Icons.add,
                activeIcon: Icons.close,
                backgroundColor: AppColors.bordo,
                foregroundColor: Colors.white,
                visible: true,
                curve: Curves.bounceIn,
                children: [
                  SpeedDialChild(
                    child: const Icon(Icons.check_circle_outline,
                        color: Colors.white),
                    backgroundColor: Colors.green,
                    label: 'Bende Var',
                    labelStyle:
                        const TextStyle(fontSize: 16.0, color: Colors.black),
                    onTap: () {
                      Navigator.of(context).push(MaterialPageRoute(
                        builder: (context) => const IlanOlusturmaEkrani(
                            initialIlanTipi: 'BendeVar'),
                      ));
                    },
                  ),
                  SpeedDialChild(
                    child: const Icon(Icons.help_outline, color: Colors.white),
                    backgroundColor: Colors.orange,
                    label: 'Bana Lazım',
                    labelStyle:
                        const TextStyle(fontSize: 16.0, color: Colors.black),
                    onTap: () {
                      Navigator.of(context).push(MaterialPageRoute(
                        builder: (context) => const IlanOlusturmaEkrani(
                            initialIlanTipi: 'BanaLazim'),
                      ));
                    },
                  ),
                ],
              ),
            )
          : null,
    );
  }
}

// Basit Ilan Kartı Widget'ı
class _IlanKarti extends StatelessWidget {
  final Ilan ilan;

  const _IlanKarti({required this.ilan});

  @override
  Widget build(BuildContext context) {
    // Tarihi daha okunabilir formatta göster
    final formattedDate = DateFormat('dd MMMM yyyy, HH:mm', 'tr_TR')
        .format(ilan.olusturulmaTarihi.toDate());

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
      elevation: 3,
      child: InkWell(
        onTap: () {
          // İlan detay sayfasına gitme işlemi şimdilik yorum satırı
          // Navigator.of(context).push(
          //   MaterialPageRoute(
          //     builder: (context) => IlanDetayEkrani(ilanId: ilan.id), // ID ile detay sayfasına git
          //   ),
          // );
          print(
              "İlan kartına tıklandı: ${ilan.id}"); // Geçici olarak ID'yi yazdır
        },
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Fotoğraf Alanı (varsa)
              if (ilan.fotografUrl != null && ilan.fotografUrl!.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8.0),
                  child: Image.network(
                    ilan.fotografUrl!,
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                    // Yüklenirken veya hata durumunda gösterilecek widget'lar
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        width: 80,
                        height: 80,
                        color: Colors.grey[200],
                        child: const Center(
                            child: CircularProgressIndicator(strokeWidth: 2)),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                          width: 80,
                          height: 80,
                          color: Colors.grey[200],
                          child: const Icon(Icons.broken_image,
                              color: Colors.grey));
                    },
                  ),
                )
              else // Fotoğraf yoksa ilan tipine göre ikon
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Icon(
                    ilan.ilanTipi == 'BendeVar'
                        ? Icons.check_circle_outline
                        : Icons.help_outline,
                    color: ilan.ilanTipi == 'BendeVar'
                        ? Colors.green
                        : Colors.orange,
                    size: 40,
                  ),
                ),
              const SizedBox(width: 12),
              // Metin Alanı
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ilan.baslik,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      ilan.kategori, // Kategori gösterilebilir
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      ilan.lokasyon,
                      style: Theme.of(context).textTheme.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      formattedDate,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[500],
                            fontSize: 10,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
