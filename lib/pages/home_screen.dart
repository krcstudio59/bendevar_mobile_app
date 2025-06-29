import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
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
import '../widgets/ilan_card.dart'; // Yeni IlanCard widget'ını import et
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
            return IlanCard(ilan: ilan); // Her ilan için YENİ kartı oluştur
          },
        );
      },
    );
  }

  String _getAppBarTitle() {
    switch (_selectedIndex) {
      case 0:
        return 'Ana Sayfa';
      case 1:
        return 'Ara';
      case 2:
        return 'Favorilerim';
      case 3:
        return 'Hesabım';
      case 4:
        return 'Ayarlar';
      default:
        return 'BendeVar';
    }
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
        currentScreen = const SettingsScreen(showAppBar: false);
        break;
      default:
        currentScreen = _buildHomeContent();
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_getAppBarTitle()),
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
