import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import '../services/auth_service.dart';
import 'auth_screen.dart';
import 'add_item_screen.dart';
import 'add_request_screen.dart';
import 'settings_screen.dart';
import 'account_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isLoading = true;
  Map<String, dynamic>? _userData;
  int _selectedIndex = 0;
  List<DocumentSnapshot> _featuredItems = [];
  List<DocumentSnapshot> _latestItems = [];

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadItems();
  }

  Future<void> _loadUserData() async {
    try {
      final userDoc = await _firestore
          .collection('users')
          .doc(_auth.currentUser?.uid)
          .get();
      if (userDoc.exists) {
        setState(() {
          _userData = userDoc.data();
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Kullanıcı bilgileri yüklenirken hata: $e');
    }
  }

  Future<void> _loadItems() async {
    setState(() => _isLoading = true);
    try {
      // En çok favorilenen 5 ürünü al
      final featuredQuery = await FirebaseFirestore.instance
          .collection('items')
          .orderBy('favoriteCount', descending: true)
          .limit(5)
          .get();

      // En son eklenen 5 ürünü al
      final latestQuery = await FirebaseFirestore.instance
          .collection('items')
          .orderBy('createdAt', descending: true)
          .limit(5)
          .get();

      setState(() {
        _featuredItems = featuredQuery.docs;
        _latestItems = latestQuery.docs;
        _isLoading = false;
      });
    } catch (e) {
      print('Ürünler yüklenirken hata: $e');
      setState(() => _isLoading = false);
    }
  }

  Widget _buildHomeContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: () async {
        await _loadUserData();
        await _loadItems();
      },
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Öne Çıkan Ürünler
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Öne Çıkan Ürünler',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            SizedBox(
              height: 200,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _featuredItems.length,
                itemBuilder: (context, index) {
                  final item =
                      _featuredItems[index].data() as Map<String, dynamic>;
                  return Card(
                    margin: const EdgeInsets.all(8),
                    child: SizedBox(
                      width: 150,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (item['imageUrl'] != null)
                            Image.network(
                              item['imageUrl'],
                              height: 100,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          Padding(
                            padding: const EdgeInsets.all(8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item['title'] ?? '',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  item['description'] ?? '',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // Son Eklenen Ürünler
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Son Eklenen Ürünler',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.all(8),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.75,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: _latestItems.length,
              itemBuilder: (context, index) {
                final item = _latestItems[index].data() as Map<String, dynamic>;
                return Card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (item['imageUrl'] != null)
                        Expanded(
                          child: Image.network(
                            item['imageUrl'],
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item['title'] ?? '',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              item['description'] ?? '',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget currentScreen;
    switch (_selectedIndex) {
      case 0:
        currentScreen = _buildHomeContent();
        break;
      case 1:
        currentScreen = const AccountScreen();
        break;
      case 2:
        currentScreen = const SettingsScreen();
        break;
      default:
        currentScreen = _buildHomeContent();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('BendeVar'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await context.read<AuthService>().signOut();
              if (!mounted) return;
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => const AuthScreen()),
              );
            },
          ),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadItems),
        ],
      ),
      body: currentScreen,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Ana Sayfa',
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
      ),
      floatingActionButton: _selectedIndex == 0
          ? SpeedDial(
              animatedIcon: AnimatedIcons.menu_close,
              animatedIconTheme: const IconThemeData(size: 22.0),
              backgroundColor: Theme.of(context).primaryColor,
              visible: true,
              closeManually: false,
              curve: Curves.bounceIn,
              overlayColor: Colors.black,
              overlayOpacity: 0.5,
              onOpen: () => print('OPENING DIAL'),
              onClose: () => print('DIAL CLOSED'),
              tooltip: 'Hızlı Erişim',
              heroTag: 'speed-dial-hero-tag',
              elevation: 8.0,
              shape: const CircleBorder(),
              children: [
                SpeedDialChild(
                  child: const Icon(Icons.add_circle_outline),
                  backgroundColor: Colors.green,
                  label: 'Bende Var',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AddItemScreen(),
                      ),
                    );
                  },
                ),
                SpeedDialChild(
                  child: const Icon(Icons.request_page),
                  backgroundColor: Colors.blue,
                  label: 'Bana Lazım',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AddRequestScreen(),
                      ),
                    );
                  },
                ),
              ],
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
